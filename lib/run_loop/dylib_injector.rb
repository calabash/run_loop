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

    # @!visibility private
    attr_reader :xcrun

    # Create a new dylib injector.
    # @param [String] process_name The name of the process to inject the dylib
    #  into.  This should be obtained by inspecting the Info.plist in the app
    #  bundle.
    # @param [String] dylib_path The path the dylib to inject.
    def initialize(process_name, dylib_path)
      @process_name = process_name
      @dylib_path = dylib_path
    end

    def xcrun
      @xcrun ||= RunLoop::Xcrun.new
    end

    # Injects a dylib into a a currently running process.
    def inject_dylib
      RunLoop.log_debug("Starting lldb.")

      script_path = write_script

      start = Time.now
      args = ["lldb", "--no-lldbinit", "--source", script_path]
      hash = xcrun.exec(args, {:log_cmd => true})

      puts hash[:out]

      pid = hash[:pid]
      exit_status = hash[:exit_status]

      RunLoop.log_debug("lldb '#{pid}' exited with value '#{exit_status}'.")

      success = exit_status == 0
      elapsed = Time.now - start
      if success
        RunLoop.log_debug("Took #{elapsed} seconds for lldb to inject calabash dylib.")
      else
        RunLoop.log_debug("lldb tried for #{elapsed} seconds to inject calabash dylib before giving up.")
      end

      success
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

    private

    def write_script
      script = File.join(DotDir.directory, "inject-dylib.lldb")

      if File.exist?(script)
        FileUtils.rm_rf(script)
      end

      File.open(script, "w") do |file|
        file.write("process attach -n \"#{process_name}\"\n")
        file.write("expr (void*)dlopen(\"#{dylib_path}\", 0x2)\n")
        file.write("detach\n")
        file.write("exit\n")
      end

      script
    end
  end
end
