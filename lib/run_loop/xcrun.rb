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

    # Raised when the output of the command cannot be coerced to UTF8
    class UTF8Error < RuntimeError; end

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

        out = encode_utf8_or_raise(command_output[:out], cmd)
        process_status = command_output[:status]

        hash =
              {
                    :out => out,
                    :pid => process_status.pid,
                    # nil if process was killed before completion
                    :exit_status => process_status.exitstatus
              }

      rescue UTF8Error => e
        raise e
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

    private

    # @!visibility private
    def encode_utf8_or_raise(string, command)
      return '' if !string

      utf8 = string.force_encoding("UTF-8").chomp

      return utf8 if utf8.valid_encoding?

      encoded = utf8.encode('UTF-8', 'UTF-8', invalid: :replace, undef: :replace, replace: '')

      return encoded if encoded.valid_encoding?

        raise UTF8Error, %Q{
Could not force UTF-8 encoding on this string:

#{string}

which is the output of this command:

#{command}

Please file an issue with a stacktrace and the text of this error.

https://github.com/calabash/run_loop/issues
}
    end
  end
end

