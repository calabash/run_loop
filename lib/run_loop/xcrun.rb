module RunLoop
  class Xcrun

    require 'command_runner' if RUBY_VERSION >= '2.0'

    DEFAULT_OPTIONS =
          {
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
               IO.popen requires all arguments to be Strings.}
        end
      end

      cmd = "xcrun #{args.join(' ')}"

      # Don't see your log?
      # Commands are only logged when debugging.
      RunLoop.log_unix_cmd(cmd) if merged_options[:log_cmd]

      # Ruby < 2.0 support
      return exec_ruby19(args, merged_options) if RUBY_VERSION < '2.0'

      hash = {}

      begin

        start_time = Time.now
        command_output = CommandRunner.run(['xcrun'] + args, timeout: timeout)

        if command_output[:out]
          out = command_output[:out].force_encoding('utf-8').chomp
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
        raise Error, "Xcrun encountered an error after #{elapsed} seconds: #{e}"
      end

      if hash[:exit_status].nil?
        elapsed = "%0.2f" % (Time.now - start_time)
        raise TimeoutError,
              "Xcrun timed out after #{elapsed} seconds executing '#{cmd}' with a timeout of #{timeout}"
      end

      hash
    end

    private

    attr_reader :stdin, :stdout, :stderr, :pid

    def exec_ruby19(args, options)

      timeout = options[:timeout]

      cmd = "xcrun #{args.join(' ')}"

      err, out, pid, exit_status, process_status = nil

      hash = nil
      begin
        Timeout.timeout(timeout, Timeout::Error) do
          @stdin, @stdout, @stderr, process_status = Open3.popen3('xcrun', *args)

          @pid = process_status.pid
          exit_status = process_status.value.exitstatus

          err = @stderr.read.force_encoding('utf-8').chomp
          err = nil if err == ''

          out = @stdout.read.force_encoding('utf-8').chomp
        end

        hash =
              {
                    :err => err,
                    :out => out,
                    :pid => pid,
                    :exit_status => exit_status
              }
      rescue Timeout::Error => _
        raise TimeoutError, "Xcrun.exec timed out after #{timeout} running '#{cmd}'"
      rescue StandardError => e
        raise Error, e
      ensure
        stdin.close if stdin && !stdin.closed?
        stdout.close if stdout && !stdout.closed?
        stderr.close if stderr && !stderr.closed?

        if pid
          terminator = RunLoop::ProcessTerminator.new(pid, 'TERM', cmd)
          unless terminator.kill_process
            terminator = RunLoop::ProcessTerminator.new(pid, 'KILL', cmd)
            terminator.kill_process
          end
        end

        if process_status
          process_status.join
        end
      end
      hash
    end
  end
end
