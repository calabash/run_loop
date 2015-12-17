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

  it '.trace_template' do
    stub_env('TRACE_TEMPLATE', '/my/tracetemplate')
    expect(RunLoop::Environment.trace_template).to be == '/my/tracetemplate'
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

  describe '.developer_dir' do
    it 'return value' do
      stub_env('DEVELOPER_DIR', '/some/xcode/path')
      expect(RunLoop::Environment.developer_dir).to be == '/some/xcode/path'
    end

    it 'returns nil if value is the empty string' do
      stub_env('DEVELOPER_DIR', '')
      expect(RunLoop::Environment.developer_dir).to be == nil
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
end

