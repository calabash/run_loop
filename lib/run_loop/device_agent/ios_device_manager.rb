
module RunLoop
  # @!visibility private
  module DeviceAgent
    # @!visibility private
    #
    # A wrapper around the test-control binary.
    class IOSDeviceManager < RunLoop::DeviceAgent::LauncherStrategy

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
      def self.log_file
        path = File.join(LauncherStrategy.dot_dir, "ios-device-manager.log")
        FileUtils.touch(path) if !File.exist?(path)
        path
      end

      # @!visibility private
      def launch(options)
        code_sign_identity = options[:code_sign_identity]

        RunLoop::DeviceAgent::Frameworks.instance.install
        cmd = RunLoop::DeviceAgent::IOSDeviceManager.ios_device_manager

        start = Time.now
        if device.simulator?
          cbxapp = RunLoop::App.new(runner.runner)

          # Quits the simulator if CoreSimulator is not already in control of it.
          sim = CoreSimulator.new(device, cbxapp, {:quit_sim_on_init => false})
          sim.install
          sim.launch_simulator
        else

          if !code_sign_identity
            raise ArgumentError, %Q[
Targeting a physical devices requires a code signing identity.

Rerun your test with:

$ CODE_SIGN_IDENTITY="iPhone Developer: Your Name (ABCDEF1234)" cucumber

]
          end

          options = {:log_cmd => true}
          args = [
            cmd, "install",
            "--device-id", device.udid,
            "--app-bundle", runner.runner,
            "--codesign-identity", code_sign_identity
          ]

          start = Time.now
          hash = run_shell_command(args, options)


          if hash[:exit_status] != 0
            raise RuntimeError, %Q[

Could not install #{runner.runner}.  iOSDeviceManager says:

#{hash[:out]}

            ]
          end
        end

        RunLoop::log_debug("Took #{Time.now - start} seconds to install DeviceAgent");

        cmd = RunLoop::DeviceAgent::IOSDeviceManager.ios_device_manager

        args = ["start_test", "--device-id", device.udid]

        log_file = IOSDeviceManager.log_file
        FileUtils.rm_rf(log_file)
        FileUtils.touch(log_file)

        env = {
          "CLOBBER" => "1"
        }

        options = {:out => log_file, :err => log_file}
        RunLoop.log_unix_cmd("#{cmd} #{args.join(" ")} >& #{log_file}")

        # Gotta keep the ios_device_manager process alive or the connection
        # to testmanagerd will fail.
        pid = Process.spawn(env, cmd, *args, options)
        Process.detach(pid)

        if device.simulator?
          # Give it a whirl.
          # device.simulator_wait_for_stable_state
        end

        pid.to_i
      end

      def app_installed?(bundle_identifier)
        options = {:log_cmd => true}

        cmd = RunLoop::DeviceAgent::IOSDeviceManager.ios_device_manager

        args = [
          cmd, "is_installed",
          "--device-id", device.udid,
          "--bundle-identifier", bundle_identifier
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
    end
  end
end
