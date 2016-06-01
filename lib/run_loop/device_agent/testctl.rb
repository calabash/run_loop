
module RunLoop
  # @!visibility private
  #
  # A wrapper around the test-control binary.
  class Testctl

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
    attr_reader :device

    # @!visibility private
    # @param [RunLoop::Device] device where to launch the CBX-Runner
    def initialize(device)
      @device = device

      if device.version < RunLoop::Version.new("9.0")
        raise ArgumentError, %Q[
Invalid device:

#{device}

XCUITest is only available for iOS >= 9.0
]
      end

    end

    # @!visibility private
    def runner
      @runner ||= RunLoop::CBXRunner.new(device)
    end

    # @!visibility private
    def launch
      RunLoop::Frameworks.instance.install

      cmd = RunLoop::Testctl.testctl

      args = ["-r", runner.runner,
              "-t", runner.tester,
              "-d", device.udid]

      if device.physical_device?
        args << "-c"
        args << RunLoop::Environment.codesign_identity
      end

      log_file = File.join(XCUITest.dot_dir, "testctl.log")
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
