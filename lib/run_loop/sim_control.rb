module RunLoop

  # One class interact with the iOS Simulators.
  #
  # @note All command line tools are run in the context of `xcrun`.
  #
  # Throughout this class's documentation, there are references to the
  # _current version of Xcode_.  The current Xcode version is the one returned
  # by `xcrun xcodebuild`.  The current Xcode version can be set using
  # `xcode-select` or overridden using the `DEVELOPER_DIR`.
  class SimControl

    # Returns an instance of XCTools.
    # @return [RunLoop::XCTools] The xcode tools instance that is used internally.
    def xctools
      @xctools ||= RunLoop::XCTools.new
    end

    # @!visibility private
    # Are we running Xcode 6 or above?
    #
    # This is a convenience method.
    #
    # @return [Boolean] `true` if the current Xcode version is >= 6.0
    def xcode_version_gte_6?
      xctools.xcode_version_gte_6?
    end

    # Return an instance of PlistBuddy.
    # @return [RunLoop::PlistBuddy] The plist buddy instance that is used internally.
    def pbuddy
      @pbuddy ||= RunLoop::PlistBuddy.new
    end

    # Is the simulator for the current version of Xcode running?
    # @return [Boolean] True if the simulator is running.
    def sim_is_running?
      not sim_pid.nil?
    end

    # If it is running, quit the simulator for the current version of Xcode.
    #
    # @param [Hash] opts Optional controls.
    # @option opts [Float] :post_quit_wait (1.0) How long to sleep after the
    #  simulator has quit.
    #
    # @todo Consider migrating apple script call to xctools.
    def quit_sim(opts={})
      if sim_is_running?
        default_opts = {:post_quit_wait => 1.0 }
        merged_opts = default_opts.merge(opts)
        `echo 'application "#{sim_name}" quit' | xcrun osascript`
        sleep(merged_opts[:post_quit_wait]) if merged_opts[:post_quit_wait]
      end
    end

    # If it is not already running, launch the simulator for the current version
    # of Xcode.
    #
    # @param [Hash] opts Optional controls.
    # @option opts [Float] :post_launch_wait (2.0) How long to sleep after the
    #  simulator has launched.
    # @option opts [Boolean] :hide_after (false) If true, will attempt to Hide
    #  the simulator after it is launched.  This is useful `only when testing
    #  gem features` that require the simulator be launched repeated and you are
    #  tired of your editor losing focus. :)
    #
    # @todo Consider migrating apple script call to xctools.
    def launch_sim(opts={})
      unless sim_is_running?
        default_opts = {:post_launch_wait => 2.0,
                        :hide_after => false}
        merged_opts = default_opts.merge(opts)
        `xcrun open -a "#{sim_app_path}"`
        if merged_opts[:hide_after]
          `xcrun /usr/bin/osascript -e 'tell application "System Events" to keystroke "h" using command down'`
        end
        sleep(merged_opts[:post_launch_wait]) if merged_opts[:post_quit_wait]
      end
    end

    # Relaunch the simulator for the current version of Xcode.  If that
    # simulator is already running, it is quit.
    #
    # @param [Hash] opts Optional controls.
    # @option opts [Float] :post_quit_wait (1.0) How long to sleep after the
    #  simulator has quit.
    # @option opts [Float] :post_launch_wait (2.0) How long to sleep after the
    #  simulator has launched.
    # @option opts [Boolean] :hide_after (false) If true, will attempt to Hide
    #  the simulator after it is launched.  This is useful `only when testing
    #  gem features` that require the simulator be launched repeated and you are
    #  tired of your editor losing focus. :)
    def relaunch_sim(opts={})
      default_opts = {:post_quit_wait => 1.0,
                      :post_launch_wait => 2.0,
                      :hide_after => false}
      merged_opts = default_opts.merge(opts)
      quit_sim(merged_opts)
      launch_sim(merged_opts)
    end

    # Terminates all simulators.
    #
    # @note Sends `kill -9` to all Simulator processes.  Use sparingly or not
    #  at all.
    #
    # SimulatorBridge
    # launchd_sim
    # ScriptAgent
    #
    # There can be only one simulator running at a time.  However, during
    # gem testing, situations can arise where multiple simulators are active.
    def self.terminate_all_sims
      processes = ['iPhone Simulator.app', 'iOS Simulator.app', 'launchd_sim',
                   # children of launchd_sim - try to clean them up.
                   # and send one last kill to launchd_sim (it can re-spawn)
                   'SimulatorBridge', 'ScriptAgent', 'configd_sim', 'launchd_sim']

      processes.each do |process_name|
        descripts = `xcrun ps x -o pid,command | grep "#{process_name}" | grep -v grep`.strip.split("\n")
        descripts.each do |process_desc|
          pid = process_desc.split(' ').first
          `xcrun kill -9 #{pid} && wait #{pid} &> /dev/null`
        end
      end
    end

    # Resets the simulator content and settings.  It is analogous to touching
    # the menu item.
    #
    # It works by deleting the following directories:
    #
    # * ~/Library/Application Support/iPhone Simulator/Library
    # * ~/Library/Application Support/iPhone Simulator/Library/<sdk>[-64]
    #
    # and relaunching the iOS Simulator which will recreate the Library
    # directory and the latest SDK directory.
    #
    # @param [Hash] opts Optional controls for quitting and launching the simulator.
    # @option opts [Float] :post_quit_wait (1.0) How long to sleep after the
    #  simulator has quit.
    # @option opts [Float] :post_launch_wait (3.0) How long to sleep after the
    #  simulator has launched.  Waits longer than normal because we need the
    #  simulator directories to be repopulated.
    # @option opts [Boolean] :hide_after (false) If true, will attempt to Hide
    #  the simulator after it is launched.  This is useful `only when testing
    #  gem features` that require the simulator be launched repeated and you are
    #  tired of your editor losing focus. :)
    def reset_sim_content_and_settings(opts={})
      default_opts = {:post_quit_wait => 1.0,
                      :post_launch_wait => 3.0,
                      :hide_after => false}
      merged_opts = default_opts.merge(opts)

      if xcode_version_gte_6?
        raise 'resetting the simulator content and settings is NYI for Xcode >= 6'
      end

      quit_sim(merged_opts)

      sim_lib_path = File.join(sim_app_support_dir, 'Library')
      FileUtils.rm_rf(sim_lib_path)
      existing_sim_support_sdk_dirs.each do |dir|
        FileUtils.rm_rf(dir)
      end

      launch_sim(merged_opts)

      # This is tricky because we need to wait for the simulator to recreate
      # the directories.  Specifically, we need the Accessibility plist to be
      # exist so subsequent calabash launches will be able to enable
      # accessibility.
      #
      # The directories take ~3.0 - ~5.0 to create.
      counter = 0
      loop do
        break if counter == 80
        dirs = existing_sim_support_sdk_dirs
        if dirs.count == 0
          sleep(0.2)
        else
          break if dirs.all? { |dir|
            plist = File.expand_path("#{dir}/Library/Preferences/com.apple.Accessibility.plist")
            File.exists?(plist)
          }
          sleep(0.2)
        end
        counter = counter + 1
      end
    end

    private

    # @!visibility private
    # Returns the current Simulator pid.
    #
    # @note Will only search for the current Xcode simulator.
    #
    # @return [String, nil] The pid as a String or nil if no process is found.
    def sim_pid
      `xcrun ps x -o pid,command | grep "#{sim_name}" | grep -v grep`.strip.split(' ').first
    end

    # @!visibility private
    # Returns the current simulator name.
    #
    # @note In Xcode >= 6.0 the simulator name changed.
    #
    # @note Returns with the .app extension because on Xcode < 6.0, multiple
    #  processes can be found with 'iPhone Simulator'; the .app ensures that
    #  other methods find the right pid and application path.
    # @return [String] A String suitable for searching for a pid, quitting, or
    #  launching the current simulator.
    def sim_name
      @sim_name ||= lambda {
        if xcode_version_gte_6?
          'iOS Simulator.app'
        else
          'iPhone Simulator.app'
        end
      }.call
    end

    # @!visibility private
    # Returns the path to the current simulator.
    #
    # @note Xcode >= 6.0  the simulator app has a different path.
    #
    # @return [String] The path to the simulator app for the current version of
    #  Xcode.
    def sim_app_path
      @sim_app_path ||= lambda {
        dev_dir = xctools.xcode_developer_dir
        if xcode_version_gte_6?
          "#{dev_dir}/Applications/iOS Simulator.app"
        else
          "#{dev_dir}/Platforms/iPhoneSimulator.platform/Developer/Applications/iPhone Simulator.app"
        end
      }.call
    end

    # @!visibility private
    # The absolute path to the iPhone Simulator Application Support directory.
    # @return [String] absolute path
    def sim_app_support_dir
      if xcode_version_gte_6?
        File.expand_path('~/Library/Developer/CoreSimulator/Devices')
      else
        File.expand_path('~/Library/Application Support/iPhone Simulator')
      end
    end

    # @!visibility private
    # Returns a list of absolute paths the existing simulator directories.
    #
    # @note This can _never_ be memoized to a variable; its value reflects the
    #  state of the file system at the time it is called.
    #
    # A simulator 'exists' if has an Application Support directory. for
    # example, the 6.1, 7.0.3-64, and 7.1 simulators exist if the following
    # directories are present:
    #
    #     ~/Library/Application Support/iPhone Simulator/Library/6.1
    #     ~/Library/Application Support/iPhone Simulator/Library/7.0.3-64
    #     ~/Library/Application Support/iPhone Simulator/Library/7.1
    #
    # @return[Array<String>] a list of absolute paths to simulator directories
    def existing_sim_support_sdk_dirs
      if xcode_version_gte_6?
        raise 'simulator support sdk dirs are NYI in Xcode 6.0'
      else
        sim_app_support_path = sim_app_support_dir
        Dir.glob("#{sim_app_support_path}/*").select { |path|
          path =~ /(\d)\.(\d)\.?(\d)?(-64)?/
        }
      end
    end

  end
end