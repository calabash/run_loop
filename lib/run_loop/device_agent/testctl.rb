
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

  end
end
