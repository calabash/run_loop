require 'cfpropertylist'

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

    # @!visibility private
    # Enables accessibility on all iOS Simulators by adjusting the
    # simulator's Library/Preferences/com.apple.Accessibility.plist contents.
    #
    # A simulator 'exists' if has an Application Support directory. for
    # example, the 6.1, 7.0.3-64, and 7.1 simulators exist if the following
    # directories are present:
    #
    #     ~/Library/Application Support/iPhone Simulator/Library/6.1
    #     ~/Library/Application Support/iPhone Simulator/Library/7.0.3-64
    #     ~/Library/Application Support/iPhone Simulator/Library/7.1
    #
    # A simulator is 'possible' if the SDK is available in the Xcode version.
    #
    # This method merges (uniquely) the possible and existing SDKs.
    #
    # This method also hides the AXInspector.
    #
    # **Q:** _Why do we need to enable for both existing and possible SDKs?_
    # **A:**  Consider what would happen if we were launching against the 7.0.3
    # SDK for the first time.  The 7.0.3 SDK directory does not exist _until the
    # simulator has been launched_.  The upshot is that we need to create the
    # the plist _before_ we try to launch the simulator.
    #
    # @note This method will quit the current simulator.
    #
    # @param [Hash] opts controls the behavior of the method
    # @option opts [Boolean] :verbose controls logging output
    # @return [Boolean] true if enabling accessibility worked on all sdk
    #  directories
    #
    # @todo Should benchmark to see if memo-izing can help speed this up. Or if
    #   we can intuit the SDK and before launching and enable access on only
    #   that SDK.
    #
    # @todo Testing this is _hard_.  ATM, I am using a reset sim content
    #  and settings + RunLoop.run to test.
    def enable_accessibility_on_sims(opts={})

      if xcode_version_gte_6?
        raise 'enabling accessibility on sims is NYI on Xcode >= 6'
      end

      default_opts = {:verbose => false}
      merged_opts = default_opts.merge(opts)

      possible = XCODE_5_SDKS.map do |sdk|
        File.expand_path("~/Library/Application Support/iPhone Simulator/#{sdk}")
      end

      # Accounting for the possibility of iOS 5 and iOS 6.0 SDK directories.
      # but is this really necessary if we are supporting Xcode 5+ ?
      existing = existing_sim_support_sdk_dirs

      dirs = (possible + existing).uniq
      results = dirs.map do |dir|
        enable_accessibility_in_sdk_dir(dir, merged_opts)
      end
      results.all? { |elm| elm }
    end

    private


    # @!visibility private
    # The list of possible SDKs for 5.0 <= Xcode < 6.0
    #
    # @note Used to enable automatically enable accessibility on the simulators.
    #
    # @see #enable_accessibility_on_sims
    XCODE_5_SDKS = ['6.1', '7.0', '7.0.3', '7.0.3-64', '7.1', '7.1-64'].freeze


    # @!visibility private
    # A hash table of the accessibility properties that control whether or not
    # accessibility is enabled and whether the AXInspector is visible.
    #
    # @see #enable_accessibility_on_sims
    ACCESSIBILITY_PROPERTIES_HASH =
          {
                # this is required
                :access_enabled => {:key => 'AccessibilityEnabled',
                                    :value => 'true',
                                    :type => 'bool'},
                # i _think_ this is legacy
                :app_access_enabled => {:key => 'ApplicationAccessibilityEnabled',
                                        :value => 'true',
                                        :type => 'bool'},

                # i don't know what this does
                :automation_enabled => {:key => 'AutomationEnabled',
                                        :value => 'true',
                                        :type => 'bool'},

                # determines if the Accessibility Inspector is showing
                :inspector_showing => {:key => 'AXInspectorEnabled',
                                       :value => 'false',
                                       :type => 'bool'},

                # controls if the Accessibility Inspector is expanded or not expanded
                :inspector_full_size => {:key => 'AXInspector.enabled',
                                         :value => 'false',
                                         :type => 'bool'},

                # controls the frame of the Accessibility Inspector
                # this is a 'string' => {{0, 0}, {276, 166}}
                :inspector_frame => {:key => 'AXInspector.frame',
                                     :value => '{{270, -13}, {276, 166}}',
                                     :type => 'string'}
          }.freeze

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

    # @!visibility private
    # Enables accessibility on the simulator indicated by `app_support_sdk_dir`.
    #
    # @note  This will quit the simulator.
    #
    # @example
    #   path = '~/Library/Application Support/iPhone Simulator/6.1'
    #   enable_accessibility_in_sdk_dir(path)
    #
    # This method also hides the AXInspector.
    #
    # If the Library/Preferences/com.apple.Accessibility.plist does not exist
    # this method will create a Library/Preferences/com.apple.Accessibility.plist
    # that (oddly) the Simulator will _not_ overwrite.
    #
    # @see enable_accessibility_on_simulators for the public API.
    #
    # @param [String] app_support_sdk_dir the directory where the
    #   Library/Preferences/com.apple.Accessibility.plist can be found.
    #
    # @param [Hash] opts controls the behavior of the method
    # @option opts [Boolean] :verbose controls logging output
    # @return [Boolean] if the plist exists and the plist was successfully
    #   updated.
    def enable_accessibility_in_sdk_dir(app_support_sdk_dir, opts={})
      default_opts = {:verbose => false}
      merged_opts = default_opts.merge(opts)

      if xcode_version_gte_6?
        raise 'enabling accessibility NYI for Xcode >= 6.0'
      end

      quit_sim

      verbose = merged_opts[:verbose]
      sdk = File.basename(app_support_sdk_dir)
      msgs = ["cannot enable accessibility for #{sdk} SDK"]

      plist_path = File.expand_path("#{app_support_sdk_dir}/Library/Preferences/com.apple.Accessibility.plist")

      if File.exist?(plist_path)
        res = ACCESSIBILITY_PROPERTIES_HASH.map do |hash_key, settings|
          success = pbuddy.plist_set(settings[:key], settings[:type], settings[:value], plist_path)
          unless success
            if verbose
              if settings[:type] == 'bool'
                value = settings[:value] ? 'YES' : 'NO'
              else
                value = settings[:value]
              end
              msgs << "could not set #{hash_key} => '#{settings[:key]}' to #{value}"
              puts "WARN: #{msgs.join("\n")}"
            end
          end
          success
        end
        res.all? { |elm| elm }
      else
        FileUtils.mkdir_p("#{app_support_sdk_dir}/Library/Preferences")
        plist = CFPropertyList::List.new
        data = {}
        plist.value = CFPropertyList.guess(data)
        plist.save(plist_path, CFPropertyList::List::FORMAT_BINARY)
        enable_accessibility_in_sdk_dir(app_support_sdk_dir, merged_opts)
      end
    end
  end
end