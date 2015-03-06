module RunLoop

  # A class for interacting with the instruments command-line tool
  #
  # @note All instruments commands are run in the context of `xcrun`.
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
      instruments_pids.each do |pid|
        terminator = RunLoop::ProcessTerminator.new(pid, kill_signal, 'instruments')
        unless terminator.kill_process
          terminator = RunLoop::ProcessTerminator.new(pid, 'KILL', 'instruments')
          terminator.kill_process
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

    # Spawn a new instruments process in the context of `xcrun` and detach.
    #
    # @param [String] automation_template The template instruments will use when
    #  launching the application.
    # @param [Hash] options The launch options.
    # @param [String] log_file The file to log to.
    # @return [Integer] Returns the process id of the instruments process.
    # @todo Do I need to enumerate the launch options in the docs?
    # @todo Should this raise errors?
    # @todo Is this jruby compatible?
    def spawn(automation_template, options, log_file)
      splat_args = spawn_arguments(automation_template, options)
      logger = options[:logger]
      RunLoop::Logging.log_debug(logger, "xcrun #{splat_args.join(' ')} >& #{log_file}")
      pid = Process.spawn('xcrun', *splat_args, {:out => log_file, :err => log_file})
      Process.detach(pid)
      pid.to_i
    end

    private

    # @!visibility private
    # Parses the run-loop options hash into an array of arguments that can be
    # passed to `Process.spawn` to launch instruments.
    def spawn_arguments(automation_template, options)
      array = ['instruments']
      array << '-w'
      array << options[:udid]

      trace = options[:results_dir_trace]
      if trace
        array << '-D'
        array << trace
      end

      array << '-t'
      array << automation_template

      array << options[:bundle_dir_or_bundle_id]

      {
            'UIARESULTSPATH' => options[:results_dir],
            'UIASCRIPT' => options[:script]
      }.each do |key, value|
        array << '-e'
        array << key
        array << value
      end
      array + options.fetch(:args, [])
    end

    # @!visibility private
    #
    # ```
    # $ ps x -o pid,command | grep -v grep | grep instruments
    # 98081 sh -c xcrun instruments -w "43be3f89d9587e9468c24672777ff6241bd91124" < args >
    # 98082 /Xcode/6.0.1/Xcode.app/Contents/Developer/usr/bin/instruments -w < args >
    # ```
    #
    # When run from run-loop (via rspec), expect this:
    #
    # ```
    # $ ps x -o pid,command | grep -v grep | grep instruments
    # 98082 /Xcode/6.0.1/Xcode.app/Contents/Developer/usr/bin/instruments -w < args >
    # ```
    INSTRUMENTS_FIND_PIDS_CMD = 'ps x -o pid,command | grep -v grep | grep instruments'

    # @!visibility private
    #
    # Executes `ps_cmd` to find instruments processes and returns the result.
    #
    # @param [String] ps_cmd The Unix ps command to execute to find instruments
    #  processes.
    # @return [String] A ps-style list of process details.  The details returned
    #  are controlled by the `ps_cmd`.
    def ps_for_instruments(ps_cmd=INSTRUMENTS_FIND_PIDS_CMD)
      `#{ps_cmd}`.strip
    end

    # @!visibility private
    # Is the process described an instruments process?
    #
    # @param [String] ps_details Details about a process as returned by `ps`
    # @return [Boolean] True if the details describe an instruments process.
    def is_instruments_process?(ps_details)
      return false if ps_details.nil?
      ps_details[/\/usr\/bin\/instruments/, 0] != nil
    end

    # @!visibility private
    # Extracts an Array of integer process ids from the output of executing
    # the Unix `ps_cmd`.
    #
    # @param [String] ps_cmd The Unix `ps` command used to find instruments
    #  processes.
    # @return [Array<Integer>] An array of integer pids for instruments
    #  processes.  Returns an empty list if no instruments process are found.
    def pids_from_ps_output(ps_cmd=INSTRUMENTS_FIND_PIDS_CMD)
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
      end.compact.sort
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
  end
end
