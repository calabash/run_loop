module RunLoop
  class Xcrun

    require 'command_runner'

    # Controls the behavior of Xcrun#exec.
    #
    # You can override these values if they do not work in your environment.
    #
    # For cucumber users, the best place to override would be in your
    # features/support/env.rb.
    #
    # For example:
    #
    # RunLoop::Xcrun::DEFAULT_OPTIONS[:timeout] = 60
    DEFAULT_OPTIONS = {
      :timeout => 30,
      :log_cmd => false
    }

    # Raised when Xcrun fails.
    class Error < RuntimeError; end


    # Raised when Xcrun times out.
    class TimeoutError < RuntimeError; end

    def exec(args, options={})

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

      cmd = "xcrun #{args.join(' ')}"

      # Don't see your log?
      # Commands are only logged when debugging.
      RunLoop.log_unix_cmd(cmd) if merged_options[:log_cmd]

      hash = {}

      begin

        start_time = Time.now
        command_output = CommandRunner.run(['xcrun'] + args, timeout: timeout)

        if command_output[:out]
          out = command_output[:out].encode('UTF-8', 'UTF-8', :invalid => :replace).chomp
        else
          out = ''
        end

        process_status = command_output[:status]

        hash =
              {
                    :out => out,
                    :pid => process_status.pid,
                    # nil if process was killed before completion
                    :exit_status => process_status.exitstatus
              }

      rescue => e
        elapsed = "%0.2f" % (Time.now - start_time)
        raise Error,
%Q{Xcrun encountered an error after #{elapsed} seconds:

#{e}

executing this command:

#{cmd}
}
      end

      if hash[:exit_status].nil?
        elapsed = "%0.2f" % (Time.now - start_time)
        raise TimeoutError,
%Q{Xcrun timed out after #{elapsed} seconds executing

#{cmd}

with a timeout of #{timeout}
}
      end

      hash
    end
  end
end
