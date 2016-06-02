
module RunLoop
  # @!visibility private
  module DeviceAgent
    # @!visibility private
    #
    # A wrapper around the test-control binary.
    class Testctl < RunLoop::DeviceAgent::Launcher

      # @!visibility private
      @@testctl = nil

      # @!visibility private
      def self.device_agent_dir
        @@device_agent_dir ||= File.expand_path(File.dirname(__FILE__))
      end

      # @!visibility private
      def self.testctl
        @@testctl ||= lambda do
          from_env = RunLoop::Environment.testctl
          if from_env
            if File.exist?(from_env)
              RunLoop.log_debug("Using TESTCTL=#{from_env}")
              from_env
            else
              raise RuntimeError, %Q[
TESTCTL environment variable defined:

#{from_env}

but binary does not exist at that path.
            ]
            end

          else
            File.join(self.device_agent_dir, "bin", "testctl")
          end
        end.call
      end

      # @!visibility private
      def to_s
        "#<Testctl: #{Testctl.testctl}>"
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
        path = File.join(Launcher.dot_dir, "testctl.log")
        FileUtils.touch(path) if !File.exist?(path)
        path
      end

      # @!visibility private
      def launch
        RunLoop::DeviceAgent::Frameworks.instance.install

        cmd = RunLoop::DeviceAgent::Testctl.testctl

        args = ["-r", runner.runner,
                "-t", runner.tester,
                "-d", device.udid]

        if device.physical_device?
          args << "-c"
          args << RunLoop::Environment.codesign_identity
        end

        log_file = Testctl.log_file
        FileUtils.rm_rf(log_file)
        FileUtils.touch(log_file)

        options = {:out => log_file, :err => log_file}
        RunLoop.log_unix_cmd("#{cmd} #{args.join(" ")} >& #{log_file}")

        # Gotta keep the testctl process alive or the connection
        # to testmanagerd will fail.
        pid = Process.spawn(cmd, *args, options)
        Process.detach(pid)
        pid.to_i
      end
    end
  end
end


