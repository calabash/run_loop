
module RunLoop
  module PhysicalDevice

    require "run_loop/physical_device/life_cycle"
    class IOSDeviceManager < RunLoop::PhysicalDevice::LifeCycle

      require "fileutils"
      require "run_loop/dot_dir"
      require "run_loop/device_agent/frameworks"
      require "run_loop/device_agent/ios_device_manager"

      NOT_INSTALLED_EXIT_CODE = 2

      DEFAULTS = {
        install_timeout: RunLoop::Environment.ci? ? 240 : 120
      }

      # Is the tool installed?
      def self.tool_is_installed?
        File.exist?(IOSDeviceManager.executable_path)
      end

      # Path to tool.
      def self.executable_path
        RunLoop::DeviceAgent::IOSDeviceManager.ios_device_manager
      end

      def initialize(device)
        super(device)

        # Expands the Frameworks.zip if necessary.
        RunLoop::DeviceAgent::Frameworks.instance.install
      end

      def raise_error_on_failure(error_klass, message, app, device, hash)
        if hash[:exit_status] == 0
          true
        else
          raise error_klass, %Q[
          #{message}

        app: #{app}
     device: #{device}
exit status: #{hash[:exit_status]}

          #{hash[:out]}

]
        end
      end

      def app_installed?(app)
        bundle_id = app
        if is_ipa?(app) || is_app?(app)
          bundle_id = app.bundle_identifier
        end

        args = [
          IOSDeviceManager.executable_path,
          "is-installed",
          bundle_id,
          "-d", device.udid
        ]

        options = { :log_cmd => true }
        hash = run_shell_command(args, options)

        exit_status = hash[:exit_status]

        if exit_status != 0 && exit_status != NOT_INSTALLED_EXIT_CODE
          raise_error_on_failure(
            RuntimeError,
            "Encountered an error checking if app is installed on device",
            app, device, hash
          )
        else
          RunLoop::log_debug("Took #{hash[:seconds_elapsed]} seconds to check " +
                               "app was installed")
          hash[:exit_status] == 0
        end
      end

      def install_app(app_or_ipa)
        install_app_internal(app_or_ipa, ["--force"])
      end

      def ensure_newest_installed(app_or_ipa)
        install_app_internal(app_or_ipa)
      end

      def uninstall_app(app_or_ipa)
        bundle_identifier = app_or_ipa.bundle_identifier
        if !app_installed?(bundle_identifier)
          return :was_not_installed
        end

        args = [
          IOSDeviceManager.executable_path,
          "uninstall",
          bundle_identifier,
          "-d", device.udid
        ]

        options = { :log_cmd => true }
        hash = run_shell_command(args, options)

        raise_error_on_failure(
          UninstallError,
          "Could not remove app from device",
          app_or_ipa, device, hash
        )
        hash[:out]
      end

      def can_reset_app_sandbox?
        true
      end

      def reset_app_sandbox(app_or_ipa)
        args = [IOSDeviceManager.executable_path,
                "clear-app-data",
                app_or_ipa.path,
                device.udid]

        options = { :log_cmd => true }
        hash = run_shell_command(args, options)

        raise_error_on_failure(
          ResetAppSandboxError,
          "Could not clear app data",
          app_or_ipa, device, hash
        )

        hash[:out]
      end

=begin
Private Methods
=end

      private

      def install_app_internal(app_or_ipa, additional_args=[])
        args = [
          IOSDeviceManager.executable_path,
          "install",
          app_or_ipa.path,
          "-d", device.udid
        ]

        args = args + additional_args

        code_sign_identity = RunLoop::Environment.code_sign_identity
        if code_sign_identity
          args = args + ["-c", code_sign_identity]
        end

        provisioning_profile = RunLoop::Environment.provisioning_profile
        if provisioning_profile
          args = args + ["-p", provisioning_profile]
        end

        options = {
          :log_cmd => true,
          timeout: DEFAULTS[:install_timeout]
        }
        hash = run_shell_command(args, options)

        raise_error_on_failure(
          InstallError,
          "Could not install app on device",
          app_or_ipa, device, hash
        )

        RunLoop::log_debug("Took #{hash[:seconds_elapsed]} seconds to install app")
        hash[:out]
      end
    end
  end
end
