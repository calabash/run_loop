module RunLoop

  # @!visibility private
  #
  # This is experimental.
  #
  # Injects dylibs into running executables using lldb.
  class DylibInjector

    # @!attribute [r] process_name
    # The name of the process to inject the dylib into.  This should be obtained
    #  by inspecting the Info.plist in the app bundle.
    # @return [String] The process_name
    attr_reader :process_name

    # @!attribute [r] dylib_path
    # The path to the dylib that is to be injected.
    # @return [String] The dylib_path
    attr_reader :dylib_path

    # Create a new dylib injector.
    # @param [String] process_name The name of the process to inject the dylib
    #  into.  This should be obtained by inspecting the Info.plist in the app
    #  bundle.
    # @param [String] dylib_path The path the dylib to inject.
    def initialize(process_name, dylib_path)
      @process_name = process_name
      @dylib_path = dylib_path
    end

    # Injects a dylib into a a currently running process.
    def inject_dylib
      RunLoop.log_debug("Starting lldb.")

      stderr_output = nil
      lldb_status = nil
      lldb_start_time = Time.now
      Open3.popen3('sh') do |stdin, stdout, stderr, process_status|
        stdin.puts 'xcrun lldb --no-lldbinit<<EOF'
        stdin.puts "process attach -n '#{@process_name}'"
        stdin.puts "expr (void*)dlopen(\"#{@dylib_path}\", 0x2)"
        stdin.puts 'detach'
        stdin.puts 'exit'
        stdin.puts 'EOF'
        stdin.close

        puts "#{stdout.read.force_encoding("utf-8")}"

        lldb_status = process_status
        stderr_output = stderr.read.force_encoding("utf-8").strip
      end

      pid = lldb_status.pid
      exit_status = lldb_status.value.exitstatus

      RunLoop.log_debug("lldb '#{pid}' exited with value '#{exit_status}'.")
      if stderr_output == ''
        RunLoop.log_debug("Took #{Time.now-lldb_start_time} for lldb to inject calabash dylib.")
      else
        puts "#{stderr_output}"
        RunLoop.log_debug("lldb tried for  #{Time.now-lldb_start_time} to inject calabash dylib before giving up.")
      end

      stderr_output == ''
    end

    def inject_dylib_with_timeout(timeout)
      success = false
      Timeout.timeout(timeout) do
        success = inject_dylib
      end
      success
    end

    def retriable_inject_dylib(options={})
      default_options = {:tries => 3,
                         :interval => 10,
                         :timeout => 10}
      merged_options = default_options.merge(options)

      debug_logging = RunLoop::Environment.debug?

      on_retry = Proc.new do |_, try, elapsed_time, next_interval|
        if debug_logging
          # Retriable 2.0
          if elapsed_time && next_interval
            puts "LLDB: attempt #{try} failed in '#{elapsed_time}'; will retry in '#{next_interval}'"
          else
            puts "LLDB: attempt #{try} failed; will retry in #{merged_options[:interval]}"
          end
        end
        RunLoop::LLDB.kill_lldb_processes
        RunLoop::ProcessWaiter.new('lldb').wait_for_none
      end

      tries = merged_options[:tries]
      interval = merged_options[:interval]
      retry_opts = RunLoop::RetryOpts.tries_and_interval(tries, interval, {:on_retry => on_retry})

      # For some reason, :timeout does not work here;
      # the lldb process can hang indefinitely.
      Retriable.retriable(retry_opts) do
        unless inject_dylib_with_timeout merged_options[:timeout]
          raise RuntimeError, "Could not inject dylib"
        end
      end
      true
    end
  end
end
