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

    # Returns true if running in Jenkins CI
    #
    # Checks the value of JENKINS_HOME
    def self.jenkins?
      value = ENV["JENKINS_HOME"]
      return value && value != ''
    end

    # Returns true if running in Travis CI
    #
    # Checks the value of TRAVIS
    def self.travis?
      value = ENV["TRAVIS"]
      return value && value != ''
    end

    # Returns true if running in Circle CI
    #
    # Checks the value of CIRCLECI
    def self.circle_ci?
      value = ENV["CIRCLECI"]
      return value && value != ''
    end

    # Returns true if running in Teamcity
    #
    # Checks the value of TEAMCITY_PROJECT_NAME
    def self.teamcity?
      value = ENV["TEAMCITY_PROJECT_NAME"]
      return value && value != ''
    end

    # Returns true if running in a CI environment
    def self.ci?
      [
        self.ci_var_defined?,
        self.travis?,
        self.jenkins?,
        self.circle_ci?,
        self.teamcity?
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
      return value && value != ''
    end
  end
end

