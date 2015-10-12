module RunLoop
  class Environment

    # Returns the user home directory
    def self.user_home_directory
      require 'etc'
      Etc.getpwuid.dir
    end

    # Returns true if debugging is enabled.
    def self.debug?
      ENV['DEBUG'] == '1'
    end

    # Returns true if read debugging is enabled.
    def self.debug_read?
      ENV['DEBUG_READ'] == '1'
    end

    # Returns true if we are running on the XTC
    def self.xtc?
      ENV['XAMARIN_TEST_CLOUD'] == '1'
    end

    # Returns the value of TRACE_TEMPLATE; the Instruments template to use
    # during testing.
    def self.trace_template
      ENV['TRACE_TEMPLATE']
    end

    # Returns the value of UIA_TIMEOUT.  Use this control how long to wait
    # for instruments to launch and attach to your application.
    #
    # Non-empty values are converted to a float.
    def self.uia_timeout
      timeout = ENV['UIA_TIMEOUT']
      timeout ? timeout.to_f : nil
    end

    # Returns the value of BUNDLE_ID
    def self.bundle_id
      value = ENV['BUNDLE_ID']
      if !value || value == ''
        nil
      else
        value
      end
    end

    # Returns to the path to the app bundle (simulator builds).
    #
    # Both APP_BUNDLE_PATH and APP are checked and in that order.
    #
    # Use of APP_BUNDLE_PATH is deprecated and will be removed.
    def self.path_to_app_bundle
      value = ENV['APP_BUNDLE_PATH'] || ENV['APP']
      if !value || value == ''
        nil
      else
        value
      end
    end

    # Returns the value of DEVELOPER_DIR
    #
    # @note Never call this directly.  Always create an Xcode instance
    #   and allow it to derive the path to the Xcode toolchain.
    def self.developer_dir
      value = ENV['DEVELOPER_DIR']
      if !value || value == ''
        nil
      else
        value
      end
    end

    # Returns the value of CAL_SIM_POST_LAUNCH_WAIT
    #
    # Controls how long to wait _after_ the simulator is opened.
    #
    # The default wait time is 1.0.  This was arrived at through testing.
    #
    # In CoreSimulator environments, the iOS Simulator starts many async
    # processes that must be allowed to finish before we start operating on the
    # simulator.  Until we find the right combination of processes to wait for,
    # this variable will give us the opportunity to control how long we wait.
    #
    # Essential for managed envs like Travis + Jenkins and on slower machines.
    def self.sim_post_launch_wait
      value = ENV['CAL_SIM_POST_LAUNCH_WAIT']
      float = nil
      begin
        float = value.to_f
      rescue NoMethodError => _

      end

      if float.nil? || float == 0.0
        nil
      else
        float
      end
    end

    # !@visibility private
    def self.with_debugging(debug, &block)
      if debug
        original_value = ENV['DEBUG']

        begin
          ENV['DEBUG'] = '1'
          block.call
        ensure
          ENV['DEBUG'] = original_value
        end

      else
        block.call
      end
    end
  end
end
