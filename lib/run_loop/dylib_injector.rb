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
      debug_logging = RunLoop::Environment.debug?
      puts "Starting lldb." if debug_logging

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

        puts "#{stdout.read}" if debug_logging

        lldb_status = process_status
        stderr_output = stderr.read.strip
      end

      pid = lldb_status.pid
      exit_status = lldb_status.value.exitstatus

      if stderr_output == ''
        if debug_logging
          puts "lldb '#{pid}' exited with value '#{exit_status}'."
          puts "Took #{Time.now-lldb_start_time} for lldb to inject calabash dylib."
        end
      else
        puts "#{stderr_output}"
        if debug_logging
          puts "lldb '#{pid}' exited with value '#{exit_status}'."
          puts "lldb tried for  #{Time.now-lldb_start_time} to inject calabash dylib before giving up."
        end
      end

      stderr_output == ''
    end
  end
end
