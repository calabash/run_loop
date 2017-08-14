describe RunLoop::Environment do

  let(:environment) { RunLoop::Environment.new }

  describe ".user_home_directory" do
    it "always returns a directory that exists" do
      expect(File.exist?(RunLoop::Environment.user_home_directory)).to be_truthy
    end

    it "returns local ./tmp/home on the XTC" do
      expect(RunLoop::Environment).to receive(:xtc?).and_return true

      expected = File.join("./", "tmp", "home")
      expect(RunLoop::Environment.user_home_directory).to be == expected
      expect(File.exist?(expected)).to be_truthy
    end
  end

  describe ".windows_env?" do
    before do
      RunLoop::Environment.class_variable_set(:@@windows_env, nil)
    end

    it "returns the value of @@windows_env if it is non-nil" do
      RunLoop::Environment.class_variable_set(:@@windows_env, :windows)

      expect(RunLoop::Environment.windows_env?).to be_truthy
      expect(RunLoop::Environment.class_variable_get(:@@windows_env)).to be_truthy
    end

    describe "matches 'host_os' against known windows hosts" do
      it "true" do
        expect(RunLoop::Environment).to receive(:host_os_is_win?).and_return(true)

        expect(RunLoop::Environment.windows_env?).to be_truthy
        expect(RunLoop::Environment.class_variable_get(:@@windows_env)).to be == true
      end

      it "false" do
        expect(RunLoop::Environment).to receive(:host_os_is_win?).and_return(false)

        expect(RunLoop::Environment.windows_env?).to be_falsey
        expect(RunLoop::Environment.class_variable_get(:@@windows_env)).to be == false
      end
    end
  end

  describe '.debug?' do
    it "returns true when DEBUG == '1'" do
      stub_env('DEBUG', '1')
      expect(RunLoop::Environment.debug?).to be == true
    end

    it "returns false when DEBUG != '1'" do
      stub_env('DEBUG', 1)
      expect(RunLoop::Environment.debug?).to be == false
    end
  end

  describe '.debug_read?' do
    it "returns true when DEBUG_READ == '1'" do
      stub_env('DEBUG_READ', '1')
      expect(RunLoop::Environment.debug_read?).to be == true
    end

    it "returns false when DEBUG_READ != '1'" do
      stub_env('DEBUG_READ', 1)
      expect(RunLoop::Environment.debug_read?).to be == false
    end
  end

  describe '.xtc?' do
    it "returns true when XAMARIN_TEST_CLOUD == '1'" do
      stub_env('XAMARIN_TEST_CLOUD', '1')
      expect(RunLoop::Environment.xtc?).to be == true
    end

    it "returns false when XAMARIN_TEST_CLOUD != '1'" do
      stub_env('XAMARIN_TEST_CLOUD', 1)
      expect(RunLoop::Environment.xtc?).to be == false
    end
  end

  describe ".device_target" do
    it "returns DEVICE_TARGET" do
      stub_env({"DEVICE_TARGET" => "target"})
      expect(RunLoop::Environment.device_target).to be == "target"
    end

    describe "returns nil" do
      it "is undefined" do
        stub_env({"DEVICE_TARGET" => nil})
        expect(RunLoop::Environment.device_target).to be == nil
      end

      it "is the empty string" do
        stub_env({"DEVICE_TARGET" => ""})
        expect(RunLoop::Environment.device_target).to be == nil
      end
    end
  end

  describe ".device_endpoint" do
    it "returns DEVICE_ENDPOINT" do
      url = "http://denis.local:27753"
      stub_env({"DEVICE_ENDPOINT" => url})
      expect(RunLoop::Environment.device_endpoint).to be == url
    end

    describe "returns nil" do
      it "is undefined" do
        stub_env({"DEVICE_ENDPOINT" => nil})
        expect(RunLoop::Environment.device_endpoint).to be == nil
      end

      it "is the empty string" do
        stub_env({"DEVICE_ENDPOINT" => ""})
        expect(RunLoop::Environment.device_endpoint).to be == nil
      end
    end
  end

  describe ".device_agent_url" do
    it "returns DEVICE_AGENT_URL" do
      url = "http://denis.local:27753"
      stub_env({"DEVICE_AGENT_URL" => url})
      expect(RunLoop::Environment.device_agent_url).to be == url
    end

    describe "returns nil" do
      it "is undefined" do
        stub_env({"DEVICE_AGENT_URL" => nil})
        expect(RunLoop::Environment.device_agent_url).to be == nil
      end

      it "is the empty string" do
        stub_env({"DEVICE_AGENT_URL" => ""})
        expect(RunLoop::Environment.device_agent_url).to be == nil
      end
    end
  end

  describe ".reset_between_scenarios?" do
    it "true" do
      stub_env({"RESET_BETWEEN_SCENARIOS" => "1"})
      expect(RunLoop::Environment.reset_between_scenarios?).to be_truthy
    end

    it "false" do
      stub_env({"RESET_BETWEEN_SCENARIOS" => ""})
      expect(RunLoop::Environment.reset_between_scenarios?).to be_falsey

      stub_env({"RESET_BETWEEN_SCENARIOS" => 1})
      expect(RunLoop::Environment.reset_between_scenarios?).to be_falsey
    end
  end

  describe '.trace_template' do
    it "returns TRACE_TEMPLATE expanded" do
      stub_env('TRACE_TEMPLATE', './my/tracetemplate')
      expected = File.join(Dir.pwd, "my", "tracetemplate")
      expect(RunLoop::Environment.trace_template).to be == expected
    end

    describe "returns nil" do
      it "is undefined" do
        stub_env({'TRACE_TEMPLATE' => nil})
        expect(RunLoop::Environment.trace_template).to be == nil
      end

      it "is the empty string" do
        stub_env({'TRACE_TEMPLATE' => ""})
        expect(RunLoop::Environment.trace_template).to be == nil
      end
    end
  end

  describe '.uia_timeout' do
    it 'returns the value of UIA_TIMEOUT' do
      stub_env('UIA_TIMEOUT', 10.0)
      expect(RunLoop::Environment.uia_timeout).to be == 10.0
    end

    it 'converts non-floats to floats' do
      stub_env('UIA_TIMEOUT', '10.0')
      expect(RunLoop::Environment.uia_timeout).to be == 10.0

      stub_env('UIA_TIMEOUT', 10)
      expect(RunLoop::Environment.uia_timeout).to be == 10.0
    end
  end

  describe '.bundle_id' do
    it 'correctly returns bundle id env var' do
      stub_env('BUNDLE_ID', 'com.example.Foo')
      expect(RunLoop::Environment.bundle_id).to be == 'com.example.Foo'
    end

    it 'returns nil when bundle id is the empty string' do
      stub_env('BUNDLE_ID', '')
      expect(RunLoop::Environment.bundle_id).to be == nil
    end
  end

  describe '.path_to_app_bundle' do
    let (:abp) { '/my/app/bundle/path.app' }
    describe 'only one is defined' do
      it 'APP_BUNDLE_PATH' do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('APP_BUNDLE_PATH').and_return(abp)
        allow(ENV).to receive(:[]).with('APP').and_return(nil)
        expect(RunLoop::Environment.path_to_app_bundle).to be == abp
      end

      it 'APP' do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('APP_BUNDLE_PATH').and_return(nil)
        allow(ENV).to receive(:[]).with('APP').and_return(abp)
        expect(RunLoop::Environment.path_to_app_bundle).to be == abp
      end
    end

    it 'when both APP_BUNDLE_PATH and APP are defined, the first takes precedence' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('APP_BUNDLE_PATH').and_return(abp)
      allow(ENV).to receive(:[]).with('APP').and_return('/some/other/path.app')
      expect(RunLoop::Environment.path_to_app_bundle).to be == abp
    end

    describe 'empty strings should be interpreted as nil' do
      it 'APP_BUNDLE_PATH' do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('APP_BUNDLE_PATH').and_return('')
        allow(ENV).to receive(:[]).with('APP').and_return(nil)
        expect(RunLoop::Environment.path_to_app_bundle).to be == nil
      end

      it 'APP' do
        expect(RunLoop::Environment.path_to_app_bundle).to be == nil
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('APP_BUNDLE_PATH').and_return(nil)
        allow(ENV).to receive(:[]).with('APP').and_return('')
      end

      it 'both' do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('APP_BUNDLE_PATH').and_return('')
        allow(ENV).to receive(:[]).with('APP').and_return('')
        expect(RunLoop::Environment.path_to_app_bundle).to be == nil
      end
    end

    it "expands relative paths" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('APP_BUNDLE_PATH').and_return("./CalSmoke-cal.app")

      dirname = File.dirname(__FILE__)
      expected = File.expand_path(File.join(dirname, '..', '..', "CalSmoke-cal.app"))
      expect(RunLoop::Environment.path_to_app_bundle).to be == expected
    end
  end

  describe ".xcodeproj" do
    describe "returns nil if XCODEPROJ variable is" do
      it "the empty string" do
         stub_env({"XCODEPROJ" => ""})
         expect(RunLoop::Environment.xcodeproj).to be_falsey
      end

      it "is undefined" do
         stub_env({"XCODEPROJ" => nil})
         expect(RunLoop::Environment.xcodeproj).to be_falsey
      end
    end

    it "return absolute path" do
      stub_env({"XCODEPROJ" => "my.xcodeproj"})
      dir = File.expand_path(File.dirname(__FILE__))

      expected = File.expand_path(File.join(dir, "..", "..", "my.xcodeproj"))
      actual = RunLoop::Environment.xcodeproj
      expect(actual).to be == expected
    end
  end

  describe ".derived_data" do
    describe "returns nil if DERIVED_DATA variable is" do
      it "the empty string" do
         stub_env({"DERIVED_DATA" => ""})
         expect(RunLoop::Environment.derived_data).to be_falsey
      end

      it "is undefined" do
         stub_env({"DERIVED_DATA" => nil})
         expect(RunLoop::Environment.derived_data).to be_falsey
      end
    end

    it "return absolute path" do
      stub_env({"DERIVED_DATA" => "build"})
      dir = File.expand_path(File.dirname(__FILE__))

      expected = File.expand_path(File.join(dir, "..", "..", "build"))
      actual = RunLoop::Environment.derived_data
      expect(actual).to be == expected
    end
  end

  describe ".solution" do
    describe "returns nil if SOLUTION variable is" do
      it "the empty string" do
         stub_env({"SOLUTION" => ""})
         expect(RunLoop::Environment.solution).to be_falsey
      end

      it "is undefined" do
         stub_env({"SOLUTION" => nil})
         expect(RunLoop::Environment.solution).to be_falsey
      end
    end

    it "return absolute path" do
      stub_env({"SOLUTION" => "build"})
      dir = File.expand_path(File.dirname(__FILE__))

      expected = File.expand_path(File.join(dir, "..", "..", "build"))
      actual = RunLoop::Environment.solution
      expect(actual).to be == expected
    end
  end

  describe '.developer_dir' do
    it 'return value' do
      stub_env('DEVELOPER_DIR', '/some/xcode/path')
      expect(RunLoop::Environment.developer_dir).to be == '/some/xcode/path'
    end

    describe "returns nil" do
      it "if value is the empty string" do
        stub_env('DEVELOPER_DIR', '')
        expect(RunLoop::Environment.developer_dir).to be == nil
      end

      it "if value is nil" do
        stub_env({"DEVELOPER_DIR" => nil})
        expect(RunLoop::Environment.developer_dir).to be == nil
      end
    end
  end

  describe ".codesign_identity" do
    it "returns value" do
      identity = "iPhone Developer: Max Musterman (ABCDE12345)"
      stub_env({"CODE_SIGN_IDENTITY" => identity})

      expect(RunLoop::Environment.code_sign_identity).to be == identity
    end

    describe "returns nil" do
      it "if value is the empty string" do
        stub_env("CODE_SIGN_IDENTITY", "")
        expect(RunLoop::Environment.code_sign_identity).to be == nil
      end

      it "if value is nil" do
        stub_env({"CODE_SIGN_IDENTITY" => nil})
        expect(RunLoop::Environment.code_sign_identity).to be == nil
      end
    end
  end

  describe ".provisioning_profile" do
    it "returns the value" do
      path = "path/to/provisioning/profile"
      stub_env({"PROVISIONING_PROFILE" => path})

      expect(RunLoop::Environment.provisioning_profile).to be == path
    end

    it "returns nil if value is the empty string" do
      stub_env("PROVISIONING_PROFILE", "")
      expect(RunLoop::Environment.provisioning_profile).to be == nil
    end

    it "returns nil if value is nil" do
      stub_env({"PROVISIONING_PROFILE" => nil})
      expect(RunLoop::Environment.provisioning_profile).to be == nil
    end
  end

  describe ".keychain" do
    it "returns value" do
      keychain = "/Users/maxmusterman/Library/Keychains/login.keychain"
      stub_env({"KEYCHAIN" => keychain})

      expect(RunLoop::Environment.keychain).to be == keychain
    end

    describe "returns nil" do
      it "if value is the empty string" do
        stub_env("KEYCHAIN", "")
        expect(RunLoop::Environment.keychain).to be == nil
      end

      it "if value is nil" do
        stub_env({"KEYCHAIN" => nil})
        expect(RunLoop::Environment.keychain).to be == nil
      end
    end
  end

  describe ".ios_device_manager" do
    it "returns value" do
      manager = "/usr/local/bin/iOSDeviceManager"
      stub_env({"IOS_DEVICE_MANAGER" => manager})

      expect(RunLoop::Environment.ios_device_manager).to be == manager
    end

    describe "returns nil" do
      it "if value is the empty string" do
        stub_env("IOS_DEVICE_MANAGER", "")
        expect(RunLoop::Environment.ios_device_manager).to be == nil
      end

      it "if value is nil" do
        stub_env("IOS_DEVICE_MANAGER", "")
        expect(RunLoop::Environment.ios_device_manager).to be == nil
      end
    end
  end

  describe ".cbxdevice" do
    it "returns value" do
      path = "/path/to/ipa/CBX-Runner.app"
      stub_env({"CBXDEVICE" => path})

      expect(RunLoop::Environment.cbxdevice).to be == path
    end

    describe "returns nil" do
      it "if value is the empty string" do
        stub_env("CBXDEVICE", "")
        expect(RunLoop::Environment.cbxdevice).to be == nil
      end

      it "if value is nil" do
        stub_env({"CBXDEVICE" => nil})
        expect(RunLoop::Environment.cbxdevice).to be == nil
      end
    end
  end

  describe ".cbxsim" do
    it "returns value" do
      path = "/path/to/app/CBX-Runner.app"
      stub_env({"CBXSIM" => path})

      expect(RunLoop::Environment.cbxsim).to be == path
    end

    describe "returns nil" do
      it "if value is the empty string" do
        stub_env("CBXSIM", "")
        expect(RunLoop::Environment.cbxsim).to be == nil
      end

      it "if value is nil" do
        stub_env({"CBXSIM" => nil})
        expect(RunLoop::Environment.cbxsim).to be == nil
      end
    end
  end

  describe ".jenkins?" do
    it "returns true if JENKINS_HOME defined" do
      stub_env({"JENKINS_HOME" => "/Users/Shared/Jenkins"})

      expect(RunLoop::Environment.jenkins?).to be == true
    end

    describe "returns false if JENKINS_HOME" do
      it "is nil" do
        stub_env({"JENKINS_HOME" => nil})

        expect(RunLoop::Environment.jenkins?).to be == false
      end

      it "is empty string" do
        stub_env({"JENKINS_HOME" => ""})

        expect(RunLoop::Environment.jenkins?).to be == false
      end
    end
  end

  describe ".travis?" do
    it "returns true if TRAVIS defined" do
      stub_env({"TRAVIS" => "some truthy value"})

      expect(RunLoop::Environment.travis?).to be == true
    end

    describe "returns false if TRAVIS" do
      it "is nil" do
        stub_env({"TRAVIS" => nil})

        expect(RunLoop::Environment.travis?).to be == false
      end

      it "is empty string" do
        stub_env({"TRAVIS" => ""})

        expect(RunLoop::Environment.travis?).to be == false
      end
    end
  end

  describe ".circle_ci?" do
    it "returns true if CIRCLECI defined" do
      stub_env({"CIRCLECI" => true})

      expect(RunLoop::Environment.circle_ci?).to be == true
    end

    describe "returns false if CIRCLECI" do
      it "is nil" do
        stub_env({"CIRCLECI" => nil})

        expect(RunLoop::Environment.circle_ci?).to be == false
      end

      it "is empty string" do
        stub_env({"CIRCLECI" => ""})

        expect(RunLoop::Environment.circle_ci?).to be == false
      end
    end
  end

  describe ".teamcity?" do
    it "returns true if TEAMCITY_PROJECT_NAME defined" do
      stub_env({"TEAMCITY_PROJECT_NAME" => "project name"})

      expect(RunLoop::Environment.teamcity?).to be == true
    end

    describe "returns false if TEAMCITY_PROJECT_NAME" do
      it "is nil" do
        stub_env({"TEAMCITY_PROJECT_NAME" => nil})

        expect(RunLoop::Environment.teamcity?).to be == false
      end

      it "is empty string" do
        stub_env({"TEAMCITY_PROJECT_NAME" => ""})

        expect(RunLoop::Environment.teamcity?).to be == false
      end
    end
  end

  describe ".gitlab?" do
    it "returns true if GITLAB_CI is defined" do
      stub_env({"GITLAB_CI" => true})

      expect(RunLoop::Environment.gitlab?).to be == true
    end

    describe "returns false if GITLAB_CI undefined or empty" do
      it "is nil" do
        stub_env({"GITLAB_CI" => nil})

        expect(RunLoop::Environment.gitlab?).to be == false
      end

      it "is empty string" do
        stub_env({"GITLAB_CI" => ""})

        expect(RunLoop::Environment.gitlab?).to be == false
      end
    end
  end

  describe ".ci?" do
    describe "truthy" do
      it "CI" do
        expect(RunLoop::Environment).to receive(:jenkins?).and_return false
        expect(RunLoop::Environment).to receive(:travis?).and_return false
        expect(RunLoop::Environment).to receive(:circle_ci?).and_return false
        expect(RunLoop::Environment).to receive(:teamcity?).and_return false
        expect(RunLoop::Environment).to receive(:gitlab?).and_return false
        expect(RunLoop::Environment).to receive(:ci_var_defined?).and_return true

        expect(RunLoop::Environment.ci?).to be == true
      end

      it "Jenkins" do
        expect(RunLoop::Environment).to receive(:jenkins?).and_return true
        expect(RunLoop::Environment).to receive(:travis?).and_return false
        expect(RunLoop::Environment).to receive(:circle_ci?).and_return false
        expect(RunLoop::Environment).to receive(:teamcity?).and_return false
        expect(RunLoop::Environment).to receive(:gitlab?).and_return false
        expect(RunLoop::Environment).to receive(:ci_var_defined?).and_return false

        expect(RunLoop::Environment.ci?).to be == true
      end

      it "Travis" do
        expect(RunLoop::Environment).to receive(:jenkins?).and_return false
        expect(RunLoop::Environment).to receive(:travis?).and_return true
        expect(RunLoop::Environment).to receive(:circle_ci?).and_return false
        expect(RunLoop::Environment).to receive(:teamcity?).and_return false
        expect(RunLoop::Environment).to receive(:gitlab?).and_return false
        expect(RunLoop::Environment).to receive(:ci_var_defined?).and_return false

        expect(RunLoop::Environment.ci?).to be == true
      end

      it "Circle CI" do
        expect(RunLoop::Environment).to receive(:jenkins?).and_return false
        expect(RunLoop::Environment).to receive(:travis?).and_return false
        expect(RunLoop::Environment).to receive(:circle_ci?).and_return true
        expect(RunLoop::Environment).to receive(:teamcity?).and_return false
        expect(RunLoop::Environment).to receive(:gitlab?).and_return false
        expect(RunLoop::Environment).to receive(:ci_var_defined?).and_return false

        expect(RunLoop::Environment.ci?).to be == true
      end

      it "TeamCity" do
        expect(RunLoop::Environment).to receive(:jenkins?).and_return false
        expect(RunLoop::Environment).to receive(:travis?).and_return false
        expect(RunLoop::Environment).to receive(:circle_ci?).and_return false
        expect(RunLoop::Environment).to receive(:teamcity?).and_return true
        expect(RunLoop::Environment).to receive(:gitlab?).and_return false
        expect(RunLoop::Environment).to receive(:ci_var_defined?).and_return false

        expect(RunLoop::Environment.ci?).to be == true
      end

      it "GitLab" do
        expect(RunLoop::Environment).to receive(:jenkins?).and_return false
        expect(RunLoop::Environment).to receive(:travis?).and_return false
        expect(RunLoop::Environment).to receive(:circle_ci?).and_return false
        expect(RunLoop::Environment).to receive(:teamcity?).and_return false
        expect(RunLoop::Environment).to receive(:gitlab?).and_return true
        expect(RunLoop::Environment).to receive(:ci_var_defined?).and_return false

        expect(RunLoop::Environment.ci?).to be == true
      end
    end

    it "falsey" do
      expect(RunLoop::Environment).to receive(:jenkins?).and_return false
      expect(RunLoop::Environment).to receive(:travis?).and_return false
      expect(RunLoop::Environment).to receive(:circle_ci?).and_return false
      expect(RunLoop::Environment).to receive(:teamcity?).and_return false
      expect(RunLoop::Environment).to receive(:gitlab?).and_return false
      expect(RunLoop::Environment).to receive(:ci_var_defined?).and_return false

      expect(RunLoop::Environment.ci?).to be == false
    end
  end

  # private

  describe ".ci_var_defined?" do
    it "returns true if CI defined" do
      stub_env({"CI" => true})

      expect(RunLoop::Environment.send(:ci_var_defined?)).to be == true
    end

    describe "returns false if CI" do
      it "is nil" do
        stub_env({"CI" => nil})

        expect(RunLoop::Environment.send(:ci_var_defined?)).to be == false
      end

      it "is empty string" do
        stub_env({"CI" => ""})

        expect(RunLoop::Environment.send(:ci_var_defined?)).to be == false
      end
    end
  end

  describe "CBXWS" do
    it "not defined" do
      stub_env({"CBXWS" => nil})

      expect(RunLoop::Environment.send(:cbxws)).to be_falsey
    end

    describe "defined" do
      let(:path) { "path/to/CBXDriver.xcworkspace" }
      let(:expanded) { "/#{path}" }

      before do
        stub_env({"CBXWS" => path})
        expect(File).to receive(:expand_path).with(path).and_return(expanded)
      end

      it "defined by path does not exist" do
        expect(File).to receive(:directory?).with(expanded).and_return(false)

        expect do
          RunLoop::Environment.send(:cbxws)
        end.to raise_error RuntimeError, /CBXWS is set, but there is no workspace at/
      end

      it "defined and exists" do
        expect(File).to receive(:directory?).with(expanded).and_return(true)

        expect(RunLoop::Environment.send(:cbxws)).to be == expanded
      end
    end
  end
end

