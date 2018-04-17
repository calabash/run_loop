module RunLoop
  module Shell

    require "command_runner"
    require "run_loop/encoding"
    include RunLoop::Encoding

    # Controls the behavior of Shell#run_shell_command.
    #
    # You can override these values if they do not work in your environment.
    #
    # For cucumber users, the best place to override would be in your
    # features/support/env.rb.
    #
    # For example:
    #
    # RunLoop::Shell::DEFAULT_OPTIONS[:timeout] = 60
    DEFAULT_OPTIONS = {
      :timeout => 30,
      :log_cmd => false
    }

    # Raised when shell command fails.
    class Error < RuntimeError; end

    # Raised when shell command times out.
    class TimeoutError < RuntimeError; end

    def self.run_shell_command(args, options={})
      shell = Class.new do
        include RunLoop::Shell
        def to_s; "#<Anonymous Shell>"; end
        def inspect; to_s; end
      end.new

      shell.run_shell_command(args, options)
    end

    def run_shell_command(args, options={})

      merged_options = DEFAULT_OPTIONS.merge(options)

      timeout = merged_options[:timeout]

      unless args.is_a?(Array)
        raise ArgumentError,
              "Expected args '#{args}' to be an Array, but found '#{args.class}'"
      end

      args.each do |arg|
        unless arg.is_a?(String)
          raise ArgumentError,
%Q{Expected arg '#{arg}' to be a String, but found '#{arg.class}'
IO.popen requires all arguments to be Strings.
}
        end
      end

      cmd = "#{args.join(' ')}"

      # Don't see your log?
      # Commands are only logged when debugging.
      RunLoop.log_unix_cmd(cmd) if merged_options[:log_cmd]

      hash = {}
      shell_start_time = Time.now

      environment = options.fetch(:environment, {})

      begin
        command_output = CommandRunner.run(args,
                                           timeout: timeout,
                                           environment: environment)

        out = ensure_command_output_utf8(command_output[:out], cmd)
        process_status = command_output[:status]

        hash =
              {
                    :out => out,
                    :pid => process_status.pid,
                    # nil if process was killed before completion
                    :exit_status => process_status.exitstatus
              }

      rescue RunLoop::Encoding::UTF8Error => e
        raise e
      rescue => e
        elapsed = "%0.2f" % (Time.now - shell_start_time)
        raise Error,
%Q{Encountered an error after #{elapsed} seconds:

#{e.message}

executing this command:

#{cmd}
}
      ensure
        hash[:seconds_elapsed] = Time.now - shell_start_time
      end

      if hash[:exit_status].nil?
        elapsed = "%0.2f" % (hash[:seconds_elapsed])

        if timeout_exceeded?(shell_start_time, timeout)
          raise TimeoutError,
%Q[
Timed out after #{elapsed} seconds executing

#{cmd}

with a timeout of #{timeout}
]
        else
          raise Error,
                %Q[
There was an error executing:

#{cmd}

The command generated this output:

#{hash[:out]}
]

        end
      end
      hash
    end

    private

    def timeout_exceeded?(start_time, timeout)
      Time.now > start_time + timeout
    end
  end
end
