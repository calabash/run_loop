module RunLoop
  class Xcrun

    DEFAULT_OPTIONS =
          {
                :timeout => 30,
                :log_cmd => false
          }

    # Raised when Xcrun fails.
    class XcrunError < RuntimeError; end

    attr_reader :stdin, :stdout, :stderr, :pid

    def exec(args, options={})
      merged_options = DEFAULT_OPTIONS.merge(options)

      timeout = merged_options[:timeout]

      unless args.is_a?(Array)
        raise ArgumentError,
              "Expected args '#{args}' to be an Array, but found '#{args.class}'"
      end

      @stdin, @stdout, out, @stderr, err, process_status, @pid, exit_status = nil

      cmd = "xcrun #{args.join(' ')}"

      # Don't see your log?
      # Commands are only logged when debugging.
      RunLoop.log_unix_cmd(cmd) if merged_options[:log_cmd]

      begin
        Timeout.timeout(timeout, Timeout::Error) do
          @stdin, @stdout, @stderr, process_status = Open3.popen3('xcrun', *args)

          @pid = process_status.pid
          exit_status = process_status.value.exitstatus

          err = @stderr.read.force_encoding('utf-8').chomp
          err = nil if err == ''

          out = @stdout.read.force_encoding('utf-8').chomp
        end

        {
              :err => err,
              :out => out,
              :pid => pid,
              :exit_status => exit_status
        }
      rescue Timeout::Error => _
        raise XcrunError, "Xcrun.exec timed out after #{timeout} running '#{cmd}'"
      rescue StandardError => e
        raise XcrunError, e
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
    end
  end
end
