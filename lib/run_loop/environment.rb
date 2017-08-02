module RunLoop
  class Environment

    # Returns the user home directory
    def self.user_home_directory
      if self.xtc?
         home = File.join("./", "tmp", "home")
         FileUtils.mkdir_p(home)
         home
      else
        require 'etc'
        Etc.getpwuid.dir
      end
    end

    # Returns true if Windows environment
    def self.windows_env?
      if @@windows_env.nil?
        @@windows_env = Environment.host_os_is_win?
      end

      @@windows_env
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

    # Returns the value of DEVICE_TARGET
    def self.device_target
      value = ENV["DEVICE_TARGET"]
      if value.nil? || value == ""
        nil
      else
        value
      end
    end

    # Returns the value of DEVICE_ENDPOINT
    def self.device_endpoint
      value = ENV["DEVICE_ENDPOINT"]
      if value.nil? || value == ""
        nil
      else
        value
      end
    end

    # Should the app data be reset between Scenarios?
    def self.reset_between_scenarios?
      ENV["RESET_BETWEEN_SCENARIOS"] == "1"
    end

    # Returns the value of XCODEPROJ which can be used to specify an Xcode
    # project directory (my.xcodeproj).
    #
    # This is useful if your project has multiple xcodeproj directories.
    #
    # Most users should not set this variable.
    def self.xcodeproj
      value = ENV["XCODEPROJ"]
      if value.nil? || value == ""
        nil
      else
        File.expand_path(value)
      end
    end

    # Returns the value of DERIVED_DATA which can be used to specify an
    # alternative DerivedData directory.
    #
    # The default is ~/Library/Xcode/DerivedData, but Xcode allows you to
    # change this value.
    def self.derived_data
      value = ENV["DERIVED_DATA"]
      if value.nil? || value == ""
        nil
      else
        File.expand_path(value)
      end
    end

    # Returns the value of SOLUTION which can be used to specify a
    # Xamarin Studio .sln
    #
    # This is useful if your project has multiple solutions (.sln)
    # and Calabash cannot detect the correct one.
    def self.solution
      value = ENV["SOLUTION"]
      if value.nil? || value == ""
        nil
      else
        File.expand_path(value)
      end
    end

    # Returns the value of TRACE_TEMPLATE; the Instruments template to use
    # during testing.
    def self.trace_template
      value = ENV['TRACE_TEMPLATE']
      if value.nil? || value == ""
        nil
      else
        File.expand_path(value)
      end
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
        File.expand_path(value)
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

    # Returns the value of CODE_SIGN_IDENTITY
    def self.code_sign_identity
      value = ENV["CODE_SIGN_IDENTITY"]
      if !value || value == ""
        nil
      else
        value
      end
    end

    # Returns the value of PROVISIONING_PROFILE
    def self.provisioning_profile
      value = ENV["PROVISIONING_PROFILE"]
      if !value || value == ""
        nil
      else
        value
      end
    end

    # Returns the value of KEYCHAIN
    #
    # Use this to specify a non-default KEYCHAIN for code signing.
    #
    # The default KEYCHAIN is login.keychain.
    def self.keychain
      value = ENV["KEYCHAIN"]
      if !value || value == ""
        nil
      else
        value
      end
    end

    # Returns the value of IOS_DEVICE_MANAGER
    #
    # Use this to specify a non-default ios_device_manager binary.
    #
    # The default ios_device_manager binary is bundled with this gem.
    def self.ios_device_manager
      value = ENV["IOS_DEVICE_MANAGER"]
      if !value || value == ""
        nil
      else
        value
      end
    end

    # Returns the value of CBXDEVICE
    #
    # Use this to specify a non-default CBX-Runner for physical devices.
    #
    # The default CBX-Runner is bundled with this gem.
    def self.cbxdevice
      value = ENV["CBXDEVICE"]
      if !value || value == ""
        nil
      else
        value
      end
    end

    # Returns the value of CBXSIM
    #
    # Use this to specify a non-default CBX-Runner for simulators.
    #
    # The default CBX-Runner is bundled with this gem.
    def self.cbxsim
      value = ENV["CBXSIM"]
      if !value || value == ""
        nil
      else
        value
      end
    end

    # Returns the value of DEVICE_ENDPOINT
    def self.device_agent_url
      value = ENV["DEVICE_AGENT_URL"]
      if value.nil? || value == ""
        nil
      else
        value
      end
    end

    # Returns true if running in Jenkins CI
    #
    # Checks the value of JENKINS_HOME
    def self.jenkins?
      value = ENV["JENKINS_HOME"]
      !!value && value != ''
    end

    # Returns true if running in Travis CI
    #
    # Checks the value of TRAVIS
    def self.travis?
      value = ENV["TRAVIS"]
      !!value && value != ''
    end

    # Returns true if running in Circle CI
    #
    # Checks the value of CIRCLECI
    def self.circle_ci?
      value = ENV["CIRCLECI"]
      !!value && value != ''
    end

    # Returns true if running in Teamcity
    #
    # Checks the value of TEAMCITY_PROJECT_NAME
    def self.teamcity?
      value = ENV["TEAMCITY_PROJECT_NAME"]
      !!value && value != ''
    end

    # Returns true if running in Teamcity
    #
    # Checks the value of GITLAB_CI
    def self.gitlab?
      value = ENV["GITLAB_CI"]
      !!value && value != ''
    end

    # Returns true if running in a CI environment
    def self.ci?
      [
        self.ci_var_defined?,
        self.travis?,
        self.jenkins?,
        self.circle_ci?,
        self.teamcity?,
        self.gitlab?
      ].any?
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

    private

    # !@visibility private
    def self.ci_var_defined?
      value = ENV["CI"]
      !!value && value != ''
    end

    # !@visibility private
    # Returns the value of CBXWS.  This can be used in conjunction with
    # :cbx_launcher => :xcodebuild to launch the DeviceAgent rather than
    # iOSDeviceManager.
    #
    # You should only set this if you are actively developing the DeviceAgent.
    def self.cbxws
      value = ENV["CBXWS"]
      if value.nil? || value == ""
        nil
      else
        path = File.expand_path(value)
        if !File.directory?(path)
          raise RuntimeError, %Q[
CBXWS is set, but there is no workspace at

#{path}

Only set CBXWS if you are developing new features in the DeviceAgent.

]
        end
        path
      end
    end

    private

    # @visibility private
    WIN_PATTERNS = [
      /bccwin/i,
      /cygwin/i,
      /djgpp/i,
      /mingw/i,
      /mswin/i,
      /wince/i,
    ]

    # @!visibility private
    @@windows_env = nil

    # @!visibility private
    def self.host_os_is_win?
      ruby_platform = RbConfig::CONFIG["host_os"]
      !!WIN_PATTERNS.find { |r| ruby_platform =~ r }
    end
  end
end
