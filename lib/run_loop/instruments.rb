module RunLoop

  # A class for interacting with the instruments command-line tool
  #
  # @note All instruments commands are run in the context of `xcrun`.
  class Instruments

    include RunLoop::Regex

    # @!visibility private
    #
    # Rotates xrtmp__ directories in /Library/Caches/com.apple.dt.instruments
    # keeping the last 5.  On CI systems these can be hundreds of gigabytes.
    def self.rotate_cache_directories

      # Never run on the XTC
      return :xtc if RunLoop::Environment.xtc?

      cache = self.library_cache_dir

      # If the directory does not exist, do nothing.
      return :no_cache if !cache || !File.exist?(cache)

      start = Time.now

      glob = "#{cache}/xrtmp__*"

      RunLoop.log_debug("Searching for instruments caches with glob: #{glob}")

      directories = Dir.glob(glob).select do |path|
        File.directory?(path)
      end

      log_progress = false
      if directories.count > 25
        RunLoop.log_info2("Found #{directories.count} instruments caches: ~#{20 * directories.count} Mb")
        RunLoop.log_info2("Deleting them could take a long time.")
        RunLoop.log_info2("This delay will only happen once!")
        RunLoop.log_info2("Please be patient and allow the directories to be deleted")
        log_progress = true
      else
        RunLoop.log_debug("Found #{directories.count} instruments caches")
      end

      if log_progress
        RunLoop.log_info2("Sorting instruments caches by modification time...")
      end

      oldest_first = directories.sort_by { |f| File.mtime(f) }

      oldest_first.pop(5)

      if log_progress
        RunLoop.log_info2("Will delete #{oldest_first.count} instruments caches...")
      else
        RunLoop.log_debug("Will delete #{oldest_first.count} instruments caches")
      end

      oldest_first.each do |path|
        FileUtils.rm_rf(path)
        if log_progress
          printf "."
        end
      end

      elapsed = Time.now - start

      if log_progress
        puts ""
        RunLoop.log_info2("Deleted #{oldest_first.count} instruments caches in #{elapsed} seconds")
      else
        RunLoop.log_debug("Deleted #{oldest_first.count} instruments caches in #{elapsed} seconds")
      end
      true
    end

    attr_reader :xcode

    def pbuddy
      @pbuddy ||= RunLoop::PlistBuddy.new
    end

    def xcode
      @xcode ||= RunLoop::Xcode.new
    end

    def xcrun
      RunLoop::Xcrun.new
    end

    # @!visibility private
    def to_s
      "#<Instruments #{version.to_s}>"
    end

    # @!visibility private
    def inspect
      to_s
    end

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
    def kill_instruments(_=nil)
      instruments_pids.each do |pid|
        terminator = RunLoop::ProcessTerminator.new(pid, "QUIT", "instruments")
        unless terminator.kill_process
          terminator = RunLoop::ProcessTerminator.new(pid, "KILL", "instruments")
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
      env = {
        "CLOBBER" => "1"
      }
      splat_args = spawn_arguments(automation_template, options)
      logger = options[:logger]
      RunLoop::Logging.log_debug(logger, "xcrun #{splat_args.join(' ')} >& #{log_file}")
      pid = Process.spawn(env, 'xcrun', *splat_args, {:out => log_file, :err => log_file})
      Process.detach(pid)
      pid.to_i
    end

    # Returns the instruments version.
    # @return [RunLoop::Version] A version object.
    def version
      @instruments_version ||= lambda do
        version_string = pbuddy.plist_read('CFBundleShortVersionString',
                                           path_to_instruments_app_plist)
        RunLoop::Version.new(version_string)
      end.call
    end

    # Returns an array of Instruments.app templates.
    #
    # Depending on the Xcode version Instruments.app templates will either be:
    #
    # * A full path to the template. # Xcode 5 and Xcode > 5 betas
    # * The name of a template.      # Xcode >= 6 (non beta)
    #
    # **Maintainers!** The rules above are important and explain why we can't
    # simply filter by `~= /tracetemplate/`.
    #
    # Templates that users have saved will always be full paths - regardless
    # of the Xcode version.
    #
    # @return [Array<String>] Instruments.app templates.
    def templates
      @instruments_templates ||= lambda do
        args = ['instruments', '-s', 'templates']
        hash = xcrun.run_command_in_context(args, log_cmd: true)
        hash[:out].chomp.split("\n").map do |elm|
          stripped = elm.strip.tr('"', '')
          if stripped == '' || stripped == 'Known Templates:'
            nil
          else
            stripped
          end
        end.compact
      end.call
    end

    # Returns an array of the available physical devices.
    #
    # @return [Array<RunLoop::Device>] All the devices will be physical
    #  devices.
    def physical_devices
      @instruments_physical_devices ||= lambda do
        fetch_devices[:out].chomp.split("\n").map do |line|
          udid = line[DEVICE_UDID_REGEX, 0]
          if udid
            version = line[VERSION_REGEX, 0]
            if version
              name = line.split('(').first.strip
              if name
                RunLoop::Device.new(name, version, udid)
              end
            end
          else
            nil
          end
        end.compact
      end.call
    end

    # Returns an array of the available simulators.
    #
    # **Xcode 5.1**
    # * iPad Retina - Simulator - iOS 7.1
    #
    # **Xcode 6**
    # * iPad Retina (8.3 Simulator) [EA79555F-ADB4-4D75-930C-A745EAC8FA8B]
    #
    # **Xcode 7**
    # * iPhone 6 (9.0) [3EDC9C6E-3096-48BF-BCEC-7A5CAF8AA706]
    # * iPhone 6 (9.0) + Apple Watch - 38mm (2.0) [EE3C200C-69BA-4816-A087-0457C5FCEDA0]
    #
    # @return [Array<RunLoop::Device>] All the devices will be simulators.
    def simulators
      @instruments_simulators ||= lambda do
        fetch_devices[:out].chomp.split("\n").map do |line|
          stripped = line.strip
          if line_is_simulator?(stripped) &&
                !line_is_simulator_paired_with_watch?(stripped) &&
                !line_is_apple_tv?(stripped)

            version = stripped[VERSION_REGEX, 0]

            if line_is_xcode5_simulator?(stripped)
              name = line
              udid = line
            else
              name = stripped.split('(').first.strip
              udid = line[CORE_SIMULATOR_UDID_REGEX, 0]
            end

            RunLoop::Device.new(name, version, udid)
          else
            nil
          end
        end.compact
      end.call
    end

    private

    # @!visibility private
    def fetch_devices
      @device_hash ||= lambda do
        args = ['instruments', '-s', 'devices']
        xcrun.run_command_in_context(args, log_cmd: true)
      end.call
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

      array << options[:bundle_id]

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
    #
    # Execute an instruments command.
    # @param [Array] args An array of arguments
    def execute_command(args)
      Open3.popen3('xcrun', 'instruments', *args) do |_, stdout, stderr, process_status|
        yield stdout, stderr, process_status
      end
    end

    # @!visibility private
    def line_is_simulator?(line)
      line_is_core_simulator?(line) || line_is_xcode5_simulator?(line)
    end

    # @!visibility private
    def line_is_xcode5_simulator?(line)
      !line[CORE_SIMULATOR_UDID_REGEX, 0] && line[/Simulator/, 0]
    end

    # @!visibility private
    def line_is_core_simulator?(line)
      return nil if !line_has_a_version?(line)

      line[CORE_SIMULATOR_UDID_REGEX, 0]
    end

    # @!visibility private
    def line_has_a_version?(line)
      line[VERSION_REGEX, 0]
    end

    # @!visibility private
    def line_is_simulator_paired_with_watch?(line)
      line[CORE_SIMULATOR_UDID_REGEX, 0] && line[/Apple Watch/, 0]
    end

    # @!visibility private
    def line_is_apple_tv?(line)
      line[/Apple TV/, 0]
    end

    # @!visibility private
    def path_to_instruments_app_plist
      @path_to_instruments_app_plist ||=
            File.expand_path(File.join(xcode.developer_dir,
                                 '..',
                                 'Applications',
                                 'Instruments.app',
                                 'Contents',
                                 'Info.plist'))
    end

    # @!visibility private
    #
    # Instruments caches files in this directory and it can become quite large
    # over time; particularly on CI system.
    def self.library_cache_dir
      path = "/Library/Caches/com.apple.dt.instruments"

      if File.exist?(path)
        path
      else
        nil
      end
    end
  end
end

