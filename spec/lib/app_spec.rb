describe RunLoop::App do

  let(:app) { RunLoop::App.new(Resources.shared.app_bundle_path) }
  let(:bundle_id) { 'sh.calaba.CalSmoke' }

  describe '.new' do
    it 'creates a new app with a path' do
      expect(app.path).to be == Resources.shared.app_bundle_path
    end
  end

  context ".valid?" do
    subject { RunLoop::App.valid?(path) }

    context "path does not exist" do
      let (:path) { "/path/does/not/exist" }
      it { is_expected.to be_falsey }
    end

    context "path is not a directory" do
      let (:path) { FileUtils.touch(File.join(Dir.mktmpdir, "foo.app")).first }
      it { is_expected.to be_falsey }
    end

    context "path does not end in .app" do
      let (:path) { FileUtils.mkdir_p(File.join(Dir.mktmpdir, "foo.bar")).first }
      it { is_expected.to be_falsey }
    end

    context "path is nil" do
      let(:path) { nil }
      it { is_expected.to be_falsey }
    end

    context "bundle does not contain an Info.plist" do
      let(:path) do
        tmp_dir = Dir.mktmpdir
        bundle = File.join(tmp_dir, "foo.app")
        FileUtils.mkdir_p(bundle)
        bundle
      end
      it { is_expected.to be_falsey }
    end
  end

  describe "#valid?" do
    it "returns false" do
      expect(RunLoop::App).to receive(:valid?).with(app.path).and_return(false)

      expect(app.valid?).to be_falsey
    end

    it "returns true" do
      expect(RunLoop::App).to receive(:valid?).with(app.path).and_return(true)

      expect(app.valid?).to be_truthy
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
        expect { app.info_plist_path }.to raise_error(RuntimeError)
      end
    end
  end

  context '#bundle_identifier' do
    subject { RunLoop::App.new(Resources.shared.app_bundle_path).bundle_identifier }
    it { is_expected.to be == bundle_id }

    context 'raises an error when' do
      let (:path) { FileUtils.mkdir_p(File.join(Dir.mktmpdir, 'foo.app')).first }
      it 'there is no CFBundleIdentifier' do
        app = RunLoop::App.new(path)
        file = RunLoop::PlistBuddy.new.create_plist(File.join(path, 'Info.plist'))
        expect(File.exist?(file)).to be_truthy
        expect { app.bundle_identifier }.to raise_error(RuntimeError)
      end
    end
  end

  context '#exectuable_name' do
    subject { RunLoop::App.new(Resources.shared.app_bundle_path).executable_name }
    it { is_expected.to be == 'CalSmoke' }

    context 'raises an error when' do
      let (:path) { FileUtils.mkdir_p(File.join(Dir.mktmpdir, 'foo.app')).first }
      it 'there is no CFExecutableName' do
        app = RunLoop::App.new(path)
        file = RunLoop::PlistBuddy.new.create_plist(File.join(path, 'Info.plist'))
        expect(File.exist?(file)).to be_truthy
        expect { app.executable_name }.to raise_error(RuntimeError)
      end
    end
  end

  context '#calabash_server_version' do
    subject { RunLoop::App.new(Resources.shared.cal_app_bundle_path).calabash_server_version }
    it { should be_kind_of(RunLoop::Version) }

    context 'should be nil when' do
      let (:path) { Resources.shared.app_bundle_path }
      it 'calabash server not included in app' do
        app = RunLoop::App.new(path)
        expect(app.calabash_server_version).to be_nil
      end
    end

    context 'raises an error when' do
      let (:path) { FileUtils.mkdir_p(File.join(Dir.mktmpdir, 'foo.app')).first }
      it 'path is not valid' do
        app = RunLoop::App.new(path)
        expect { app.calabash_server_version }.to raise_error(RuntimeError)
      end
    end
  end

  it '#sha1' do
    expect(RunLoop::Directory).to receive(:directory_digest).with(app.path).and_return 'sha1'

    expect(app.sha1).to be == 'sha1'
  end
end
