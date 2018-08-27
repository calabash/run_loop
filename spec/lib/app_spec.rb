describe RunLoop::App do

  let(:bundle_path) { Resources.shared.app_bundle_path }
  let(:app) { RunLoop::App.new(bundle_path) }
  let(:bundle_id) { 'sh.calaba.CalSmoke' }

  describe '.new' do
    it 'creates a new app with a path' do
      expect(app.path).to be == Resources.shared.app_bundle_path
    end

    it "raises an error if app bundle path is not valid" do
      expect do
        RunLoop::App.new("path/does/not/exist")
      end.to raise_error(ArgumentError,
                         /App does not exist at path or is not an app bundle/)
    end

    it "raises an error if app bundle is 'cached'" do
      expect(RunLoop::App).to receive(:cached_app_on_simulator?).and_return(true)

      expect do
        RunLoop::App.new(File.join(Resources.shared.resources_dir,
                                         "CachedSimApp.app"))
      end.to raise_error(RuntimeError,
                         /there was an incomplete install or uninstall/)
    end
  end

  describe "private validation class methods" do
    let(:path) { "path/to/My.app" }
    let(:info) { File.join(path, "Info.plist") }
    let(:name) { "My" }
    let(:executable) { File.join(path, "My") }
    let(:pbuddy) { RunLoop::PlistBuddy.new }

    before do
      allow(RunLoop::PlistBuddy).to receive(:new).and_return(pbuddy)
    end

    describe ".info_plist_exists?" do
      it "true" do
        expect(File).to receive(:exist?).with(info).and_return(true)

        expect(RunLoop::App.send(:info_plist_exist?, path)).to be_truthy
      end

      it "false" do
        expect(File).to receive(:exist?).with(info).and_return(false)

        expect(RunLoop::App.send(:info_plist_exist?, path)).to be_falsey
      end
    end

    describe ".executable_file_exists?" do
      describe "false" do
        it "plist does not exist" do
          expect(RunLoop::App).to receive(:info_plist_exist?).with(path).and_return(false)

          expect(RunLoop::App.send(:executable_file_exist?, path)).to be_falsey
        end

        it "Info.plist does not contain the CFBundleExecutable key" do
          expect(RunLoop::App).to receive(:info_plist_exist?).with(path).and_return(true)
          expect(pbuddy).to receive(:plist_read).with("CFBundleExecutable", info).and_return(nil)

          expect(RunLoop::App.send(:executable_file_exist?, path)).to be_falsey
        end

        it "executable file does not exist" do
          expect(RunLoop::App).to receive(:info_plist_exist?).with(path).and_return(true)
          expect(pbuddy).to receive(:plist_read).with("CFBundleExecutable", info).and_return(name)
          expect(File).to receive(:exist?).with(executable).and_return(false)

          expect(RunLoop::App.send(:executable_file_exist?, path)).to be_falsey
        end
      end

      it "true" do
        expect(RunLoop::App).to receive(:info_plist_exist?).with(path).and_return(true)
        expect(pbuddy).to receive(:plist_read).with("CFBundleExecutable", info).and_return(name)
        expect(File).to receive(:exist?).with(executable).and_return(true)

        expect(RunLoop::App.send(:executable_file_exist?, path)).to be_truthy
      end
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

    describe "structure" do
      let(:path) { Resources.shared.app_bundle_path }

      it "bundle does not contain an info plist" do
        expect(RunLoop::App).to receive(:info_plist_exist?).and_return(false)

        expect(RunLoop::App.valid?(path)).to be_falsey
      end

      it "bundle does not contain the app executable file" do
        expect(RunLoop::App).to receive(:executable_file_exist?).and_return(false)

        expect(RunLoop::App.valid?(path)).to be_falsey
      end
    end

    it "true" do
      path = Resources.shared.app_bundle_path
      expect(RunLoop::App.valid?(path)).to be_truthy
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

  context ".cached_app_on_simulator?" do
    it "returns true if the .app bundle is sparse and installed on a simulator" do
      tmpdir = File.join(Resources.shared.local_tmp_dir, "rspec", "app-tests",
                         "81B79FDC-CAD7-4B0E-9704-9FBC31D56F51")
      FileUtils.rm_rf(tmpdir)
      FileUtils.mkdir_p(tmpdir)

      app = File.join(tmpdir, "CachedSimApp.app")
      FileUtils.cp_r(File.join(Resources.shared.resources_dir, "CachedSimApp.app"),
                     app)
      expect(RunLoop::App.cached_app_on_simulator?(app)).to be true

      FileUtils.rm_rf(tmpdir)
    end

    it "returns false if the .app bundle is not installed a simulator" do
      app = Resources.shared.app_bundle_path
      expect(RunLoop::App.cached_app_on_simulator?(app)).to be false
    end

    it "returns false if the .app bundle contains any other files" do
      tmpdir = File.join(Resources.shared.local_tmp_dir, "rspec", "app-tests",
                         "81B79FDC-CAD7-4B0E-9704-9FBC31D56F51")
      FileUtils.rm_rf(tmpdir)
      FileUtils.mkdir_p(tmpdir)

      app = File.join(tmpdir, "CalSmoke.app")
      FileUtils.cp_r(Resources.shared.app_bundle_path, app)
      expect(RunLoop::App.cached_app_on_simulator?(app)).to be false

      FileUtils.rm_rf(tmpdir)
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

  it "#arches" do
    arches = app.arches
    expect(arches).to be == ["i386", "x86_64"]
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

  context "#calabash_server_id" do
    it "returns fingerprint of the embedded server" do
      app = RunLoop::App.new(Resources.shared.cal_app_bundle_path)
      actual = app.calabash_server_id
      expect(actual[/[a-f0-9]{40}(-dirty)?/]).to be_truthy
    end

    it "returns nil if there is no embedded server" do
      app = RunLoop::App.new(Resources.shared.app_bundle_path)
      expect(app.calabash_server_id).to be == nil
    end
  end

  describe "#marketing_version" do
    let(:pbuddy) { RunLoop::PlistBuddy.new }
    let(:args) { ["CFBundleShortVersionString", app.info_plist_path] }

    before do
      allow(app).to receive(:plist_buddy).and_return(pbuddy)
    end

    it "valid CFBundleShortVersionString" do
      expect(pbuddy).to receive(:plist_read).with(*args).twice.and_return("8.0")

      expect(app.marketing_version).to be == RunLoop::Version.new("8.0")
      expect(app.short_bundle_version).to be == RunLoop::Version.new("8.0")
    end

    it "invalid CFBundleShortVersionString" do
      expect(pbuddy).to receive(:plist_read).with(*args).and_return("a.b.c")

      expect(app.marketing_version).to be == nil
    end
  end

  describe "#build_version" do
    let(:pbuddy) { RunLoop::PlistBuddy.new }
    let(:args) { ["CFBundleVersion", app.info_plist_path] }

    before do
      allow(app).to receive(:plist_buddy).and_return(pbuddy)
    end

    it "valid CFBundleVersion" do
      expect(pbuddy).to receive(:plist_read).with(*args).twice.and_return("8.0")

      expect(app.build_version).to be == RunLoop::Version.new("8.0")
      expect(app.bundle_version).to be == RunLoop::Version.new("8.0")
    end

    it "invalid CFBundleVersion" do
      expect(pbuddy).to receive(:plist_read).with(*args).and_return("a.b.c")

      expect(app.build_version).to be == nil
    end
  end

  describe "#simulator_app?" do
    it "false" do
      expect(app).to receive(:arches).twice.and_return(["arm64", "armv7"])

      expect(app.simulator?).to be_falsey
    end

    describe "true" do
      it "i386" do
        expect(app).to receive(:arches).at_least(:once).and_return(["i386"])

        expect(app.simulator?).to be_truthy
      end

      it "x86_64" do
        expect(app).to receive(:arches).at_least(:once).and_return(["x86_64"])

        expect(app.simulator?).to be_truthy
      end

      it "both" do
        expect(app).to receive(:arches).at_least(:once).and_return(["x86_64", "i386"])

        expect(app.simulator?).to be_truthy
      end
    end
  end

  describe "#physical_device_app?" do
    it "false" do
      expect(app).to receive(:arches).at_least(:once).and_return(["x86_64", "i386"])

      expect(app.physical_device?).to be_falsey
    end

    describe "true" do
      it "arm64" do
        expect(app).to receive(:arches).at_least(:once).and_return(["arm64"])

        expect(app.physical_device?).to be_truthy
      end

      it "armv7" do
        expect(app).to receive(:arches).at_least(:once).and_return(["armv7"])

        expect(app.physical_device?).to be_truthy
      end

      it "armv7s" do
        expect(app).to receive(:arches).at_least(:once).and_return(["armv7s"])

        expect(app.physical_device?).to be_truthy
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

      actual = app.executables.sort
      expected = [
        File.join(app.path, app.executable_name),
        File.join(app.path, File.basename(dylib))
      ].sort

      expect(actual).to be == expected
    end

    it "returns an empty list if no executables are found" do
      xcode = RunLoop::Xcode.new
      otool = RunLoop::Otool.new(xcode)
      expect(app).to receive(:otool).at_least(:once).and_return(otool)
      expect(otool).to receive(:executable?).at_least(:once).and_return(false)

      expect(app.executables).to be == []
    end
  end

  it "#skip_executable_check?" do
    path = "path/to/file"
    expect(File).to receive(:directory?).at_least(:once).with(bundle_path).and_return(true)
    expect(File).to receive(:directory?).with(path).and_return(false)
    expect(app).to receive(:image?).with(path).and_return(false)
    expect(app).to receive(:text?).with(path).and_return(false)
    expect(app).to receive(:plist?).with(path).and_return(false)
    expect(app).to receive(:lproj_asset?).with(path).and_return(false)
    expect(app).to receive(:code_signing_asset?).with(path).and_return(false)
    expect(app).to receive(:core_data_asset?).with(path).and_return(false)
    expect(app).to receive(:font?).with(path).and_return(false)
    expect(app).to receive(:build_artifact?).with(path).and_return(false)

    expect(app.send(:skip_executable_check?, path)).to be_falsey
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
      expect(app.send(:lproj_asset?, "path/to/Main.storyboard/any_file")).to be_truthy
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
      expect(app.send(:core_data_asset?, "path/to/my.omo")).to be_truthy
    end

    it "returns false" do
      expect(app.send(:core_data_asset?, "path/to/foo")).to be_falsey
    end
  end

  describe "#font?" do
    it "returns true" do
      expect(app.send(:font?, "path/to/my.ttf")).to be_truthy
      expect(app.send(:font?, "path/to/my.otf")).to be_truthy
    end

    it "returns false" do
      expect(app.send(:font?, "path/to/my.file")).to be_falsey
    end
  end

  describe "#build_artifact?" do
    it "returns true for .xcconfig" do
      expect(app.send(:build_artifact?, "path/to/my.xcconfig")).to be_truthy
    end

    it "returns false for other files" do
      expect(app.send(:build_artifact?, "path/to/my.extension")).to be_falsey
    end
  end

  it "#lipo" do
    actual = app.send(:lipo)
    expect(actual).to be_a_kind_of(RunLoop::Lipo)
    expect(app.instance_variable_get(:@lipo)).to be == actual
  end

  context "#otool" do
    it "returns a memoized RunLoop::Otool instance" do
      otool = app.send(:otool)
      expect(app.send(:otool)).to be == otool
      expect(app.instance_variable_get(:@otool)).to be == otool
      expect(otool).to be_a_kind_of(RunLoop::Otool)
    end
  end

  context "#xcode" do
    it "returns a memoized RunLoop::Xcode instance" do
      xcode = app.send(:xcode)
      expect(app.send(:xcode)).to be == xcode
      expect(app.instance_variable_get(:@xcode)).to be == xcode
      expect(xcode).to be_a_kind_of(RunLoop::Xcode)
    end
  end
end

