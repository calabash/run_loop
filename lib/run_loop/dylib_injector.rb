module RunLoop

  # @!visibility private
  #
  # This is experimental.
  #
  # Injects dylibs into running executables using lldb.
  class DylibInjector

    # Options for controlling how often to retry dylib injection.
    #
    # Try 3 times for 10 seconds each try with a sleep of 2 seconds
    # between tries.
    #
    # You can override these values if they do not work in your environment.
    #
    # For cucumber users, the best place to override would be in your
    # features/support/env.rb.
    #
    # For example:
    #
    # RunLoop::DylibInjector::RETRY_OPTIONS[:timeout] = 60
    RETRY_OPTIONS = {
      :tries => 3,
      :interval => 2,
      :timeout => RunLoop::Environment.ci? ? 40 : 20
    }

    # Options for controlling dylib injection
    #
    # You can override these values if they do not work in your environment.
    #
    # For cucumber users, the best place to override would be in your
    # features/support/env.rb.
    #
    # For example:
    #
    # RunLoop::DylibInjector::OPTIONS[:injection_delay] = 10.0
    OPTIONS = {
      # Starting in Xcode 9, some apps need additional time to launch
      # completely.
      #
      # If lldb interupts the app before it can accept a 'dlopen' command,
      # the app will never finish launching - even on a retry.
      injection_delay: RunLoop::Environment.ci? ? 1.0 : 5.0
    }

    # Extracts the value of :inject_dylib from options Hash.
    # @param options [Hash] arguments passed to {RunLoop.run}
    # @return [String, nil] If the options contains :inject_dylibs and it is a
    #  path to a dylib that exists, return the path.  Otherwise return nil or
    #  raise an error.
    # @raise [RuntimeError] If :inject_dylib points to a path that does not exist.
    # @raise [ArgumentError] If :inject_dylib is not a String.
    def self.dylib_path_from_options(options)
      inject_dylib = options.fetch(:inject_dylib, nil)
      return nil if inject_dylib.nil?
      if !inject_dylib.is_a? String
        raise ArgumentError, %Q[

Expected :inject_dylib to be a path to a dylib, but found '#{inject_dylib}'

]
      end
      dylib_path = File.expand_path(inject_dylib)
      unless File.exist?(dylib_path)
        raise "Cannot load dylib.  The file '#{dylib_path}' does not exist."
      end
      dylib_path
    end

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
      @dylib_path = Shellwords.shellescape(dylib_path)
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
        hash = xcrun.run_command_in_context(["lldb", "--no-lldbinit", "--source", script_path], options)
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
        elapsed = Time.now - start
        RunLoop.log_debug("lldb tried for #{elapsed} seconds to inject calabash dylib before giving up.")
      end

      success
    end

    def retriable_inject_dylib(options={})
      delay = OPTIONS[:injection_delay]
      RunLoop.log_debug("Delaying dylib injection by #{delay} seconds to allow app to finish launching")
      sleep(delay)

      merged_options = RETRY_OPTIONS.merge(options)

      tries = merged_options[:tries]
      timeout = merged_options[:timeout]
      interval = merged_options[:interval]

      success = false

      tries.times do

        success = inject_dylib(timeout)
        break if success

        sleep(interval)
      end

      if !success
        raise RuntimeError, "Could not inject dylib"
      end
      success
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
