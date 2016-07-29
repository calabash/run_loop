
module RunLoop
  module PhysicalDevice

    require "run_loop/physical_device/life_cycle"
    class IOSDeviceManager < RunLoop::PhysicalDevice::LifeCycle

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

      def app_installed?(bundle_id)
        args = [
          IOSDeviceManager.executable_path,
          "is_installed",
          "-d", device.udid,
          "-b", bundle_id
        ]

        options = { :log_cmd => true }
        hash = run_shell_command(args, options)

        # TODO: error reporting
        hash[:exit_status] == 0
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
