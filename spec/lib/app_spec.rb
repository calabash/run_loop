describe RunLoop::App do

  let(:app) { RunLoop::App.new(Resources.shared.app_bundle_path) }
  let(:bundle_id) { 'sh.calaba.CalSmoke' }

  describe '.new' do
    it 'creates a new app with a path' do
      expect(app.path).to be == Resources.shared.app_bundle_path
    end

    it "raises an error if app bundle path is not valid" do
      expect(RunLoop::App).to receive(:valid?).and_return(false)

      expect do
        expect(RunLoop::App.new("path/does/not/exist"))
      end.to raise_error ArgumentError, /App does not exist at path or is not an app bundle/
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

  it '#info_plist_path' do
    actual = app.info_plist_path
    expected = File.join(Resources.shared.app_bundle_path, "Info.plist")

    expect(actual).to be == expected
    expect(app.instance_variable_get(:@info_plist_path)).to be == expected
  end

  describe '#bundle_identifier' do
    let(:pbuddy) { RunLoop::PlistBuddy.new }
    let(:args) { ["CFBundleIdentifier", app.info_plist_path] }

    before do
      allow(app).to receive(:plist_buddy).and_return(pbuddy)
    end

    it "returns the bundle identifier" do
      expect(pbuddy).to receive(:plist_read).with(*args).and_return("com.example.App")

      expect(app.bundle_identifier).to be == "com.example.App"
    end

    it "raises an error if key is not found" do
      expect(pbuddy).to receive(:plist_read).with(*args).and_return(nil)

      expect do
        app.bundle_identifier
      end.to raise_error RuntimeError, /Expected key 'CFBundleIdentifier'/
    end
  end

  describe '#executable_name' do
    let(:pbuddy) { RunLoop::PlistBuddy.new }
    let(:args) { ["CFBundleExecutable", app.info_plist_path] }

    before do
      allow(app).to receive(:plist_buddy).and_return(pbuddy)
    end

    it "returns the executable name" do
      expect(pbuddy).to receive(:plist_read).with(*args).and_return("App")

      expect(app.executable_name).to be == "App"
    end

    it "raises an error if key is not found" do
      expect(pbuddy).to receive(:plist_read).with(*args).and_return(nil)

      expect do
        app.executable_name
      end.to raise_error RuntimeError, /Expected key 'CFBundleExecutable'/
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
  end

  describe "codesign" do
    it "#codesign_info" do
      expect(RunLoop::Codesign).to receive(:info).with(app.path).and_return(:info)

      expect(app.codesign_info).to be == :info
    end

    it "#developer_signed?" do
      expect(RunLoop::Codesign).to receive(:developer?).with(app.path).and_return(:value)

      expect(app.developer_signed?).to be == :value
    end

    it "#distribution_signed?" do
      expect(RunLoop::Codesign).to receive(:distribution?).with(app.path).and_return(:value)

      expect(app.distribution_signed?).to be == :value
    end
  end

  it '#sha1' do
    expect(RunLoop::Directory).to receive(:directory_digest).with(app.path).and_return 'sha1'

    expect(app.sha1).to be == 'sha1'
  end

  describe "#executables" do
    let(:path) { Resources.shared.app_bundle_path }
    let(:app) { RunLoop::App.new(path) }

    it "list should include the app executable" do
      actual = app.executables
      expected = [File.join(app.path, app.executable_name)]

      expect(actual).to be == expected
    end

    it "list should include any dylibs" do
      source = Resources.shared.app_bundle_path
      target = File.expand_path(File.join("tmp", "app-tests", "executables"))
      FileUtils.rm_rf(target)
      FileUtils.mkdir_p(target)
      FileUtils.cp_r(source, target)

      dylib = Resources.shared.sim_dylib_path
      FileUtils.cp(dylib, File.join(target, "CalSmoke.app"))
      app = RunLoop::App.new(File.join(target, "CalSmoke.app"))

      actual = app.executables
      expected = [
        File.join(app.path, app.executable_name),
        File.join(app.path, File.basename(dylib))
      ]

      expect(actual).to be == expected
    end

    it "returns an empty list if no executables are found" do
      file = __FILE__
      otool = RunLoop::Otool.new(file)
      expect(app).to receive(:otool).at_least(:once).and_return(otool)
      expect(otool).to receive(:executable?).at_least(:once).and_return(false)

      expect(app.executables).to be == []
    end
  end

  it "#skip_executable_check?" do
    expect(app).to receive(:image?).and_return(false)
    expect(app).to receive(:text?).and_return(false)
    expect(app).to receive(:plist?).and_return(false)
    expect(app).to receive(:lproj_asset?).and_return(false)
    expect(app).to receive(:code_signing_asset?).and_return(false)
    expect(app).to receive(:core_data_asset?).and_return(false)

    expect(app.send(:skip_executable_check?, "path/to/file")).to be_falsey
  end

  describe "#image?" do
    it "returns true" do
      expect(app.send(:image?, "path/to/my.png")).to be_truthy
      expect(app.send(:image?, "path/to/my.jpeg")).to be_truthy
      expect(app.send(:image?, "path/to/my.jpg")).to be_truthy
      expect(app.send(:image?, "path/to/my.gif")).to be_truthy
      expect(app.send(:image?, "path/to/my.svg")).to be_truthy
      expect(app.send(:image?, "path/to/my.tiff")).to be_truthy
      expect(app.send(:image?, "path/to/my.pdf")).to be_truthy
      expect(app.send(:image?, "path/to/Assets.car")).to be_truthy
      expect(app.send(:image?, "path/to/iTunesArtwork")).to be_truthy
    end

    it "returns false" do
      expect(app.send(:image?, "path/to/my.plist")).to be_falsey
    end
  end

  describe "#text?" do
    it "returns true" do
      expect(app.send(:text?, "path/to/my.txt")).to be_truthy
      expect(app.send(:text?, "path/to/my.md")).to be_truthy
      expect(app.send(:text?, "path/to/my.html")).to be_truthy
      expect(app.send(:text?, "path/to/my.xml")).to be_truthy
      expect(app.send(:text?, "path/to/my.json")).to be_truthy
      expect(app.send(:text?, "path/to/my.yml")).to be_truthy
      expect(app.send(:text?, "path/to/my.yaml")).to be_truthy
      expect(app.send(:text?, "path/to/my.rtf")).to be_truthy
      expect(app.send(:text?, "path/to/NOTICE")).to be_truthy
      expect(app.send(:text?, "path/to/LICENSE")).to be_truthy
      expect(app.send(:text?, "path/to/README")).to be_truthy
      expect(app.send(:text?, "path/to/ABOUT")).to be_truthy
    end

    it "returns false" do
      expect(app.send(:text?, "path/to/some_file")).to be_falsey
    end
  end

  describe "#plist?" do
    it "returns true" do
      expect(app.send(:plist?, "path/to/my.plist")).to be_truthy
    end

    it "returns false" do
      expect(app.send(:plist?, "path/to/my.png")).to be_falsey
    end
  end

  describe "#lproj_asset?" do
    it "returns true" do
      expect(app.send(:lproj_asset?, "path/to/Base.lproj/My.nib")).to be_truthy
      expect(app.send(:lproj_asset?, "path/to/My.nib")).to be_truthy
      expect(app.send(:lproj_asset?, "path/to/My.xib")).to be_truthy
      expect(app.send(:lproj_asset?, "path/to/Main.storyboardc/any_file")).to be_truthy
      expect(app.send(:lproj_asset?, "path/to/Localizable.strings")).to be_truthy
    end

    it "returns false" do
      expect(app.send(:lproj_asset?, "path/to/foo")).to be_falsey
    end
  end

  describe "#code_signing_asset?" do
    it "returns true" do
      expect(app.send(:code_signing_asset?, "path/to/embedded.mobileprovision")).to be_truthy
      expect(app.send(:code_signing_asset?, "path/to/some-other.mobileprovision")).to be_truthy
      expect(app.send(:code_signing_asset?, "path/to/xcodesign.xcent")).to be_truthy
      expect(app.send(:code_signing_asset?, "path/to/PkgInfo")).to be_truthy
      expect(app.send(:code_signing_asset?, "path/to/_CodeSignature/any_file")).to be_truthy
    end

    it "returns false" do
      expect(app.send(:code_signing_asset?, "path/to/foo")).to be_falsey
    end
  end

  describe "#core_data_asset?" do
    it "returns true" do
      expect(app.send(:core_data_asset?, "path/to/my.mom")).to be_truthy
      expect(app.send(:core_data_asset?, "path/to/CoreData.momd/SomeFile")).to be_truthy
      expect(app.send(:core_data_asset?, "path/to/my.db")).to be_truthy
    end

    it "returns false" do
      expect(app.send(:core_data_asset?, "path/to/foo")).to be_falsey
    end
  end
end

