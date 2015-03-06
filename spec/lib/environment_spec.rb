describe RunLoop::Environment do

  let(:environment) { RunLoop::Environment.new }

  context '.user_id' do
  subject { RunLoop::Environment.uid }
    it {
      is_expected.not_to be nil
      is_expected.to be_a_kind_of(Integer)
    }
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

  it '.bundle_id' do
    stub_env('BUNDLE_ID', 'com.example.Foo')
    expect(RunLoop::Environment.bundle_id).to be == 'com.example.Foo'
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
  end
end
