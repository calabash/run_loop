module RunLoop

  # A class for interacting with the instruments command-line tool
  #
  # @note All instruments commands are run in the context of `xcrun`.
  #
  # @todo Detect Instruments.app is running and pop an alert.
  class Instruments

    # Returns an Array of instruments process ids.
    #
    # @note The `block` parameter is included for legacy API and will be
    #  deprecated.  Replace your existing calls with with .each or .map.  The
    #  block argument makes this method hard to mock.
    # @return [Array<Integer>] An array of instruments process ids.
    def instruments_pids(&block)
      pids = pids_from_ps_output
      if block_given?
        pids.each do |pid|
          block.call(pid)
        end
      else
        pids
      end
    end

    # Are there any instruments processes running?
    # @return [Boolean] True if there is are any instruments processes running.
    def instruments_running?
      instruments_pids.count > 0
    end

    # Send a kill signal to any running `instruments` processes.
    #
    # Only one instruments process can be running at any one time.
    #
    # @param [RunLoop::XCTools] xcode_tools The Xcode tools to use to determine
    #  what version of Xcode is active.
    def kill_instruments(xcode_tools = RunLoop::XCTools.new)
      kill_signal = kill_signal xcode_tools
      # It is difficult to test using a block.
      instruments_pids.each do |pid|
        begin
          if ENV['DEBUG'] == '1' or ENV['DEBUG_UNIX_CALLS'] == '1'
            puts "Sending '#{kill_signal}' to instruments process '#{pid}'"
          end
          Process.kill(kill_signal, pid.to_i)
          Process.wait(pid, Process::WNOHANG)
        rescue Exception => e
          if ENV['DEBUG'] == '1' or ENV['DEBUG_UNIX'] == '1'
            puts "Could not kill and wait for process '#{pid.to_i}' - ignoring exception '#{e}'"
          end
        end

        # Process.wait or `wait` here is pointless.  The pid may or may not be
        # a child of this Process.
        begin
          if ENV['DEBUG'] == '1' or ENV['DEBUG_UNIX_CALLS'] == '1'
            puts "Waiting for instruments '#{pid}' to terminate"
          end
          wait_for_process_to_terminate(pid, {:timeout => 2.0})
        rescue Exception => e
          if ENV['DEBUG'] == '1' or ENV['DEBUG_UNIX_CALLS'] == '1'
            puts "Ignoring #{e.message}"
          end
        end
      end
    end

    # Is the Instruments.app running?
    #
    # If the Instruments.app is running, the instruments command line tool
    # cannot take control of applications.
    def instruments_app_running?
      ps_output = `ps x -o pid,comm | grep Instruments.app | grep -v grep`.strip
      if ps_output[/Instruments\.app/, 0]
        true
      else
        false
      end
    end

    private

    # @!visibility private
    # When run from calabash, expect this:
    #
    # ```
    # $ ps x -o pid,command | grep -v grep | grep instruments
    # 98081 sh -c xcrun instruments -w "43be3f89d9587e9468c24672777ff6241bd91124" < args >
    # 98082 /Xcode/6.0.1/Xcode.app/Contents/Developer/usr/bin/instruments -w < args >
    # ```
    # When run from run-loop (via rspec), expect this:
    #
    # ```
    # $ ps x -o pid,command | grep -v grep | grep instruments
    # 98082 /Xcode/6.0.1/Xcode.app/Contents/Developer/usr/bin/instruments -w < args >
    FIND_PIDS_CMD = 'ps x -o pid,comm | grep -v grep | grep instruments'

    # @!visibility private
    #
    # Executes `ps_cmd` to find instruments processes and returns the result.
    #
    # @param [String] ps_cmd The Unix ps command to execute to find instruments
    #  processes.
    # @return [String] A ps-style list of process details.  The details returned
    #  are controlled by the `ps_cmd`.
    def ps_for_instruments(ps_cmd=FIND_PIDS_CMD)
      `#{ps_cmd}`.strip
    end

    # @!visibility private
    # Is the process described an instruments process?
    #
    # @param [String] ps_details Details about a process as returned by `ps`
    # @return [Boolean] True if the details describe an instruments process.
    def is_instruments_process?(ps_details)
      return false if ps_details.nil?
      (ps_details[/\/usr\/bin\/instruments/, 0] or
            ps_details[/sh -c xcrun instruments/, 0]) != nil
    end

    # @!visibility private
    # Extracts an Array of integer process ids from the output of executing
    # the Unix `ps_cmd`.
    #
    # @param [String] ps_cmd The Unix `ps` command used to find instruments
    #  processes.
    # @return [Array<Integer>] An array of integer pids for instruments
    #  processes.  Returns an empty list if no instruments process are found.
    def pids_from_ps_output(ps_cmd=FIND_PIDS_CMD)
      ps_output = ps_for_instruments(ps_cmd)
      lines = ps_output.lines("\n").map { |line| line.strip }
      lines.map do |line|
        tokens = line.strip.split(' ').map { |token| token.strip }
        pid = tokens.fetch(0, nil)
        process_description = tokens[1..-1].join(' ')
        if is_instruments_process? process_description
          pid.to_i
        else
          nil
        end
      end.compact
    end

    # @!visibility private
    # The kill signal should be sent to instruments.
    #
    # When testing against iOS 8, sending -9 or 'TERM' causes the ScriptAgent
    # process on the device to emit the following error until the device is
    # rebooted.
    #
    # ```
    # MobileGestaltHelper[909] <Error>: libMobileGestalt MobileGestalt.c:273: server_access_check denied access to question UniqueDeviceID for pid 796 
    # ScriptAgent[796] <Error>: libMobileGestalt MobileGestaltSupport.m:170: pid 796 (ScriptAgent) does not have sandbox access for re6Zb+zwFKJNlkQTUeT+/w and IS NOT appropriately entitled
    # ScriptAgent[703] <Error>: libMobileGestalt MobileGestalt.c:534: no access to UniqueDeviceID (see <rdar://problem/11744455>)
    # ```
    #
    # @see https://github.com/calabash/run_loop/issues/34
    #
    # @param [RunLoop::XCTools] xcode_tools The Xcode tools to use to determine
    #  what version of Xcode is active.
    # @return [String] Either 'QUIT' or 'TERM', depending on the Xcode
    #  version.
    def kill_signal(xcode_tools = RunLoop::XCTools.new)
      xcode_tools.xcode_version_gte_6? ? 'QUIT' : 'TERM'
    end

    # @!visibility private
    # Wait for Unix process with id `pid` to terminate.
    #
    # @param [Integer] pid The id of the process we are waiting on.
    # @param [Hash] options Values to control the behavior of this method.
    # @option options [Float] :timeout (2.0) How long to wait for the process to
    #  terminate.
    # @option options [Float] :interval (0.1) The polling interval.
    # @option options [Boolean] :raise_on_no_terminate (false) Should an error
    #  be raised if process does not terminate.
    # @raise [RuntimeError] If process does not terminate and
    #  options[:raise_on_no_terminate] is truthy.
    def wait_for_process_to_terminate(pid, options={})
      default_opts = {:timeout => 2.0,
                      :interval => 0.1,
                      :raise_on_no_terminate => false}
      merged_opts = default_opts.merge(options)

      cmd = "ps #{pid} -o pid | grep #{pid}"
      poll_until = Time.now + merged_opts[:timeout]
      delay = merged_opts[:interval]
      has_terminated = false
      while Time.now < poll_until
        has_terminated = `#{cmd}`.strip == ''
        break if has_terminated
        sleep delay
      end

      if merged_opts[:raise_on_no_terminate] and not has_terminated
        details = `ps -p #{pid} -o pid,comm | grep #{pid}`.strip
        raise RuntimeError, "Waited #{merged_opts[:timeout]} s for process '#{details}' to terminate"
      end
    end
  end
end
