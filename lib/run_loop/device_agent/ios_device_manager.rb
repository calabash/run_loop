
module RunLoop
  # @!visibility private
  module DeviceAgent
    # @!visibility private
    #
    # A wrapper around the test-control binary.
    class IOSDeviceManager < RunLoop::DeviceAgent::LauncherStrategy

      require "run_loop/regex"

      EXIT_CODES = {
        "0" => :success,
        "2" => :false
      }.freeze

      require "run_loop/shell"
      include RunLoop::Shell

      # @!visibility private
      @@ios_device_manager = nil

      # @!visibility private
      def self.device_agent_dir
        @@device_agent_dir ||= File.expand_path(File.dirname(__FILE__))
      end

      # @!visibility private
      def self.ios_device_manager
        @@ios_device_manager ||= begin
          from_env = RunLoop::Environment.ios_device_manager
          if from_env
            if File.exist?(from_env)
              RunLoop.log_debug("Using IOS_DEVICE_MANAGER=#{from_env}")
              from_env
            else
              raise RuntimeError, %Q[
IOS_DEVICE_MANAGER environment variable defined:

#{from_env}

but binary does not exist at that path.
]
            end
          else
            File.join(self.device_agent_dir, "bin", "iOSDeviceManager")
          end
        end
      end

      # @!visibility private
      def name
        :ios_device_manager
      end

      # @!visibility private
      def to_s
        "#<iOSDeviceManager: #{IOSDeviceManager.ios_device_manager}>"
      end

      # @!visibility private
      def inspect
        to_s
      end

      # @!visibility private
      def runner
        @runner ||= RunLoop::DeviceAgent::Runner.new(device)
      end

      # @!visibility private
      #
      # In earlier implementations, the ios-device-manager.log was located in
      # ~/.run-loop/xcuitest/ios-device-manager.log
      #
      # Now iOSDeviceManager logs almost everything to a fixed location.
      #
      # ~/.calabash/iOSDeviceManager/logs/current.log
      #
      # Starting in run-loop 2.4.0, iOSDeviceManager start_test was replaced
      # by xcodebuild test-without-building.   This change causes a name
      # conflict: there is already an xcodebuild launcher with a log file
      # ~/.run-loop/DeviceAgent/xcodebuild.log.
      #
      # The original xcodebuild launcher requires access to the DeviceAgent
      # Xcode project which is not yet available to the public.
      #
      # Using `current.log` seems to make sense because the file is recreated
      # for every call to `#launch`.
      def self.log_file
        path = File.join(LauncherStrategy.dot_dir, "current.log")
        FileUtils.touch(path) if !File.exist?(path)
        legacy_path = File.join(LauncherStrategy.dot_dir, "ios-device-manager.log")
        if File.exist?(legacy_path)
          FileUtils.rm_rf(legacy_path)
        end
        path
      end

      # @!visibility private
      def launch(options)
        code_sign_identity = options[:code_sign_identity]
        provisioning_profile = options[:provisioning_profile]
        install_timeout = options[:device_agent_install_timeout]

        RunLoop::DeviceAgent::Frameworks.instance.install
        cmd = RunLoop::DeviceAgent::IOSDeviceManager.ios_device_manager

        start = Time.now
        if device.simulator?
          RunLoop::DeviceAgent::Xcodebuild.terminate_simulator_tests

          cbxapp = RunLoop::App.new(runner.runner)
          sim = CoreSimulator.new(device, cbxapp)

          sim.install
          sim.launch_simulator
        else
          RunLoop::DeviceAgent::Xcodebuild.terminate_device_test(device.udid)

          if !install_timeout
            raise ArgumentError, %Q[

Expected :device_agent_install_timeout key in options:

#{options}

]
          end

          shell_options = {:log_cmd => true, :timeout => install_timeout}

          args = [
            cmd, "install", runner.runner, "--device-id", device.udid
          ]

          if code_sign_identity
            args = args + ["--codesign-identity", code_sign_identity]
          end

          if provisioning_profile
            args = args + ["--profile-path", provisioning_profile]
          end

          start = Time.now
          hash = run_shell_command(args, shell_options)

          if hash[:exit_status] != 0
            raise RuntimeError, %Q[

Could not install #{runner.runner}.  iOSDeviceManager says:

#{hash[:out]}

]
          end
        end

        RunLoop::log_debug("Took #{Time.now - start} seconds to install DeviceAgent")

        cmd = "xcrun"
        args = ["xcodebuild",
                "test-without-building",
                "-xctestrun", path_to_xctestrun,
                "-destination", "id=#{device.udid}",
                "-derivedDataPath", Xcodebuild.derived_data_directory]

        log_file = IOSDeviceManager.log_file
        FileUtils.rm_rf(log_file)
        FileUtils.touch(log_file)

        env = {
          # zsh support
          "CLOBBER" => "1"
        }

        options = {:out => log_file, :err => log_file}
        RunLoop.log_unix_cmd("#{cmd} #{args.join(" ")} >& #{log_file}")

        pid = Process.spawn(env, cmd, *args, options)
        Process.detach(pid)

        pid.to_i
      end

      def app_installed?(bundle_identifier)
        options = {:log_cmd => true}

        cmd = RunLoop::DeviceAgent::IOSDeviceManager.ios_device_manager

        args = [
          cmd, "is-installed", bundle_identifier, "--device-id", device.udid
        ]

        start = Time.now
        hash = run_shell_command(args, options)

        exit_status = EXIT_CODES[hash[:exit_status].to_s]
        if exit_status == :success
          true
        elsif exit_status == :false
          false
        else
          raise RuntimeError, %Q[

Could not check if app is installed:

bundle identifier: #{bundle_identifier}
           device: #{device}

iOSDeviceManager says:

#{hash[:out]}

]
        end

        RunLoop::log_debug("Took #{Time.now - start} seconds to check if app was installed");

        hash[:exit_status] == 0
      end

      def path_to_xctestrun
        if device.physical_device?
          path = File.join(runner.tester, "DeviceAgent-device.xctestrun")
          if !File.exist?(path)
            raise RuntimeError, %Q[
Could not find an xctestrun file at path:

#{path}

]
          end
          path
        else
          template = path_to_xctestrun_template
          path = File.join(IOSDeviceManager.dot_dir, "DeviceAgent-simulator.xctestrun")
          contents = File.read(template).force_encoding("UTF-8")
          substituted = contents.gsub("TEST_HOST_PATH", runner.runner)
          File.open(path, "w:UTF-8") do |file|
            file.write(substituted)
          end
          path
        end
      end

      def path_to_xctestrun_template
        if device.physical_device?
          raise(ArgumentError, "Physical devices do not require an xctestrun template")
        end

        template = File.join(runner.tester, "DeviceAgent-simulator-template.xctestrun")
        if !File.exist?(template)
          raise RuntimeError, %Q[
Could not find an xctestrun template at path:

#{template}

]
        end
        template
      end
    end
  end
end
