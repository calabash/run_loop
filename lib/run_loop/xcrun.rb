module RunLoop
  class Xcrun

    DEFAULT_TIMEOUT = 10

    # Raised when Xcrun fails.
    class XcrunError < RuntimeError; end

    attr_reader :stdin, :stdout, :stderr, :pid

    def exec(args, timeout = DEFAULT_TIMEOUT)

      unless args.is_a?(Array)
        raise ArgumentError,
              "Expected args '#{args}' to be an Array, but found '#{args.class}'"
      end

      @stdin, @stdout, out, @stderr, err, process_status, @pid, exit_status = nil

      cmd = "xcrun #{args.join(' ')}"
      RunLoop.log_unix_cmd(cmd)

      begin
        Timeout.timeout(timeout, TimeoutError) do
          @stdin, @stdout, @stderr, process_status = Open3.popen3('xcrun', *args)

          @pid = process_status.pid
          exit_status = process_status.value.exitstatus

          err = @stderr.read.chomp
          err = nil if err == ''

          out = @stdout.read.chomp
        end

        {
              :err => err,
              :out => out,
              :pid => pid,
              :exit_status => exit_status
        }
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
