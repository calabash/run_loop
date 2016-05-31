
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

  end
end
