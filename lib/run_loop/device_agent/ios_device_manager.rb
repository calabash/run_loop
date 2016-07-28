
module RunLoop
  # @!visibility private
  module DeviceAgent
    # @!visibility private
    #
    # A wrapper around the test-control binary.
    class IOSDeviceManager < RunLoop::DeviceAgent::Launcher

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
        :xctestctl
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
        @runner ||= RunLoop::DeviceAgent::CBXRunner.new(device)
      end

      # @!visibility private
      def self.log_file
        path = File.join(Launcher.dot_dir, "ios-device-manager.log")
        FileUtils.touch(path) if !File.exist?(path)
        path
      end

      # @!visibility private
      def launch
        RunLoop::DeviceAgent::Frameworks.instance.install

        # WIP: it is unclear what the behavior should be.
        if device.simulator?
          # Simulator cannot be running for this version.
          CoreSimulator.quit_simulator

          CoreSimulator.wait_for_simulator_state(device, "Shutdown")

          # TODO: run-loop is responsible for detecting an outdated CBX-Runner
          # application and installing a new one.  However, iOSDeviceManager
          # fails if simulator is already running.

          # cbxapp = RunLoop::App.new(runner.runner)
          #
          # # quits the simulator
          # sim = CoreSimulator.new(device, cbxapp)
          # sim.install
          # sim.launch_simulator
        end

        cmd = RunLoop::DeviceAgent::IOSDeviceManager.ios_device_manager

        args = ["start_test",
                "-r", runner.runner,
                "-t", runner.tester,
                "-d", device.udid]

        if device.physical_device?
          args << "-c"
          args << RunLoop::Environment.code_sign_identity
        end

        log_file = IOSDeviceManager.log_file
        FileUtils.rm_rf(log_file)
        FileUtils.touch(log_file)

        options = {:out => log_file, :err => log_file}
        RunLoop.log_unix_cmd("#{cmd} #{args.join(" ")} >& #{log_file}")

        # Gotta keep the ios_device_manager process alive or the connection
        # to testmanagerd will fail.
        pid = Process.spawn(cmd, *args, options)
        Process.detach(pid)

        if device.simulator?
          device.simulator_wait_for_stable_state
        end

        pid.to_i
      end
    end
  end
end
