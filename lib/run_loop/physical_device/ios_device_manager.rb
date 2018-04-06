
module RunLoop
  module PhysicalDevice

    require "run_loop/physical_device/life_cycle"
    class IOSDeviceManager < RunLoop::PhysicalDevice::LifeCycle

      require "run_loop/device_agent/frameworks"
      require "run_loop/device_agent/ios_device_manager"

      NOT_INSTALLED_EXIT_CODE = 2

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
        app = app_or_ipa
        if is_ipa?(app)
          app = app_or_ipa.app
        end

        code_sign_identity = RunLoop::Environment.code_sign_identity
        if !code_sign_identity
          code_sign_identity = "iPhone Developer"
        end

        args = [
          IOSDeviceManager.executable_path,
          "install",
          "-d", device.udid,
          "-a", app.path,
          "-c", code_sign_identity
        ]

        options = { :log_cmd => true }
        hash = run_shell_command(args, options)

        # TODO: error reporting
        if hash[:exit_status] == 0
          true
        else
          puts hash[:out]
          false
        end
      end

      def uninstall_app(bundle_id)
        return true if !app_installed?(bundle_id)

        args = [
          IOSDeviceManager.executable_path,
          "uninstall",
          "-d", device.udid,
          "-b", bundle_id
        ]

        options = { :log_cmd => true }
        hash = run_shell_command(args, options)

        # TODO: error reporting
        hash[:exit_status] == 0
      end
    end
  end
end
