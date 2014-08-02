module RunLoop

  # A class to help you control the iOS Simulators.
  #
  # Throughout this class's documentation, there are references to the
  # _current version of Xcode_.  The current Xcode version is the one returned
  # by `xcrun xcodebuild`.  It can be set using `xcode-select` or overridden
  # using the `DEVELOPER_DIR`.
  class SimControl

    # Returns an instance of XCTools.
    # @return [RunLoop::XCTools] The xcode tools instance that is used internally.
    def xctools
      @xctools ||= RunLoop::XCTools.new
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
    # There can be only one simulator running at a time.  However, during
    # gem testing, situations can arise where multiple simulators are active.
    def self.terminate_all_sims
      old = `xcrun ps x -o pid,command | grep "iPhone Simulator.app" | grep -v grep`.strip.split("\n")
      new = `xcrun ps x -o pid,command | grep "iOS Simulator.app" | grep -v grep`.strip.split("\n")
      (old + new).each { |process_desc|
        pid = process_desc.split(' ').first
        `xcrun kill -9 #{pid} && wait #{pid} &> /dev/null`
      }
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
        if xctools.xcode_version >= xctools.xc60
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
        if xctools.xcode_version >= xctools.xc60
          "#{dev_dir}/Applications/iOS Simulator.app"
        else
          "#{dev_dir}/Platforms/iPhoneSimulator.platform/Developer/Applications/iPhone Simulator.app"
        end
      }.call
    end
  end
end