module RunLoop
  class Environment

    # Returns the user's Unix uid.
    # @return [Integer] The user's Unix uid as an integer.
    def self.uid
      `id -u`.strip.to_i
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
    # @note Never call this directly.  Always create an XCTool instance
    #   and allow it to derive the path to the Xcode toolchain.
    def self.developer_dir
      ENV['DEVELOPER_DIR']
    end
  end
end
