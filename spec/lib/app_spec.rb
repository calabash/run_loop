describe RunLoop::App do

  let(:app) { RunLoop::App.new(Resources.shared.app_bundle_path) }

  describe '.new' do
    it 'creates a new app with a path' do
      expect(app.path).to be == Resources.shared.app_bundle_path
    end
  end

  context '#valid?' do
    subject { RunLoop::App.new(path).valid? }

    context 'path does not exist' do
      let (:path) { '/path/does/not/exist' }
      it { is_expected.to be_falsey }
    end

    context 'path is not a directory' do
      let (:path) { FileUtils.touch(File.join(Dir.mktmpdir, 'foo.app')).first }
      it { is_expected.to be_falsey }
    end

    context 'path does not end in .app' do
      let (:path) { FileUtils.mkdir_p(File.join(Dir.mktmpdir, 'foo.bar')).first }
      it { is_expected.to be_falsey }
    end
  end

  context '#info_plist_path' do
    subject { RunLoop::App.new(path).info_plist_path }

    context 'the plist exists' do
      let(:path) { Resources.shared.app_bundle_path }
      it { is_expected.to be == File.join(path, 'Info.plist') }
    end

    describe 'raises error when' do
      let (:path) { FileUtils.mkdir_p(File.join(Dir.mktmpdir, 'foo.app')).first }
      it 'there is no info plist' do
        app = RunLoop::App.new(path)
        expect { app.info_plist_path }.to raise_error
      end
    end
  end

  context '#bundle_identifier' do
    subject { RunLoop::App.new(Resources.shared.app_bundle_path).bundle_identifier }
    it { is_expected.to be == 'com.xamarin.chou' }

    context 'raises an error when' do
      let (:path) { FileUtils.mkdir_p(File.join(Dir.mktmpdir, 'foo.app')).first }
      it 'there is no CFBundleIdentifier' do
        app = RunLoop::App.new(path)
        file = RunLoop::PlistBuddy.new.create_plist(File.join(path, 'Info.plist'))
        expect(File.exist?(file)).to be_truthy
        expect { app.bundle_identifier }.to raise_error
      end
    end
  end
end
