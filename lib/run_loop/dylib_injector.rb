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
    def inject_dylib(timeout)
      RunLoop.log_debug("Starting lldb injection with a timeout of #{timeout} seconds")

      script_path = write_script

      start = Time.now

      options = {
        :timeout => timeout,
        :log_cmd => true
      }

      hash = nil
      success = false
      begin
        hash = xcrun.exec(["lldb", "--no-lldbinit", "--source", script_path], options)
        pid = hash[:pid]
        exit_status = hash[:exit_status]
        success = exit_status == 0

        RunLoop.log_debug("lldb '#{pid}' exited with value '#{exit_status}'.")

        success = exit_status == 0
        elapsed = Time.now - start

        if success
          RunLoop.log_debug("Took #{elapsed} seconds for lldb to inject calabash dylib.")
        else
          RunLoop.log_debug("Could not inject dylib after #{elapsed} seconds.")
          if hash[:out]
            hash[:out].split("\n").each do |line|
              RunLoop.log_debug(line)
            end
          else
            RunLoop.log_debug("lldb returned no output to stdout or stderr")
          end
        end
      rescue RunLoop::Xcrun::TimeoutError
        RunLoop.log_debug("lldb tried for #{elapsed} seconds to inject calabash dylib before giving up.")
      end

      success
    end

    def retriable_inject_dylib(options={})
      default_options = {:tries => 3,
                         # interval is retriable 2.0 for :timeout
                         :interval => 20}
      merged_options = default_options.merge(options)

      on_retry = Proc.new do |_, try, elapsed_time, next_interval|
        # Retriable 2.0
        if elapsed_time && next_interval
          RunLoop.log_debug("LLDB: attempt #{try} failed in '#{elapsed_time}'; will retry in '#{next_interval}'")
        else
          RunLoop.log_debug("LLDB: attempt #{try} failed; will retry in #{merged_options[:interval]}")
        end
      end

      tries = merged_options[:tries]
      interval = merged_options[:interval]
      retry_opts = RunLoop::RetryOpts.tries_and_interval(tries, interval, {:on_retry => on_retry})

      Retriable.retriable(retry_opts) do
        unless inject_dylib(interval)
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
