describe RunLoop::Ipa do

  let(:ipa_path) { Resources.shared.cal_ipa_path  }
  let(:ipa) { RunLoop::Ipa.new(ipa_path) }

  context ".is_zip_archive?" do
    it "returns true when the file at path is zip archive" do
      hash = {out: "Zip archive data"}
      expect(RunLoop::Shell).to receive(:run_shell_command).and_return(hash)

      expect(RunLoop::Ipa.is_zip_archive?("path/to/app")).to be_truthy
    end

    it "returns false when the file at path is not a zip archive" do
      hash = {out: "Regular file"}
      expect(RunLoop::Shell).to receive(:run_shell_command).and_return(hash)

      expect(RunLoop::Ipa.is_zip_archive?("path/to/app")).to be_falsey
    end
  end

  context ".new" do
    it "raises an error when the path does not exist" do
      expect do
        RunLoop::Ipa.new('/path/does/not/exist')
      end.to raise_error(RuntimeError)
    end

    it "raise an error when the file at path is not an ipa" do
      path = "path/foo.app"
      expect(RunLoop::Ipa).to receive(:is_ipa?).with(path).and_return(false)
      expect(File).to receive(:exist?).with(path).and_return(true)

      expect do
        RunLoop::Ipa.new(path)
      end.to raise_error(RuntimeError)
    end

    it "sets the path" do
      expect(ipa.path).to be == ipa_path
    end
  end

  it '#to_s' do
    expect { ipa.to_s}.not_to raise_error
  end

  it "#bundle_identifier" do
    expect(ipa.bundle_identifier).to be == 'sh.calaba.CalSmoke-cal'
  end

  it "#executable_name" do
    expect(ipa.executable_name).to be == 'CalSmoke-cal'
  end

  it "#arches" do
    expect(ipa.arches).to be == ["armv7", "armv7s", "arm64"]
  end

  it "calabash_server_version" do
    version = ipa.calabash_server_version
    expect(version).to be_a_kind_of(RunLoop::Version)
  end

  describe "codesign" do

    let(:app) { ipa.send(:app) }

    it "#codesign_info" do
      expect(app).to receive(:codesign_info).and_return(:info)

      expect(ipa.codesign_info).to be == :info
    end

    it "#developer_signed?" do
      expect(app).to receive(:developer_signed?).and_return(:value)

      expect(ipa.developer_signed?).to be == :value
    end

    it "#distribution_signed?" do
      expect(app).to receive(:distribution_signed?).and_return(:value)

      expect(ipa.distribution_signed?).to be == :value
    end
  end

  describe "version info" do
    let(:app) { ipa.send(:app) }
    let(:version) { RunLoop::Version.new("1.2.3") }

    it "#marketing_version" do
      expect(app).to receive(:marketing_version).and_return(version)

      expect(ipa.marketing_version).to be == version
    end

    it "#build_version" do
      expect(app).to receive(:build_version).and_return(version)

      expect(ipa.build_version).to be == version
    end
  end

  describe 'private' do
    it '#tmpdir' do
      tmp_dir = ipa.send(:tmpdir)

      expect(File.exist?(tmp_dir)).to be_truthy
      expect(File.directory?(tmp_dir)).to be_truthy
      expect(ipa.instance_variable_get(:@tmpdir)).to be == tmp_dir
    end

    it '#payload_dir' do
      payload_dir = ipa.send(:payload_dir)
      expect(File.exist?(payload_dir)).to be_truthy
      expect(File.directory?(payload_dir)).to be_truthy
      expect(ipa.instance_variable_get(:@payload_dir)).to be == payload_dir
    end

    it '#bundle_dir' do
      bundle_dir = ipa.send(:bundle_dir)
      expect(File.exist?(bundle_dir)).to be_truthy
      expect(File.directory?(bundle_dir)).to be_truthy
      expect(ipa.instance_variable_get(:@bundle_dir)).to be == bundle_dir
    end

    it '#plist_buddy' do
      expect(ipa.send(:plist_buddy)).to be_a_kind_of(RunLoop::PlistBuddy)
    end

    describe "#app" do
      it "returns a RunLoop::App" do
        app = ipa.send(:app)
        expect(app).to be_a_kind_of(RunLoop::App)
        expect(ipa.instance_variable_get(:@app)).to be
      end

      it "raises an error if the app is not valid" do
        expect(ipa).to receive(:bundle_dir).and_return("path/to/invalid.app")

        expect do
          ipa.send(:app)
        end.to raise_error ArgumentError
      end
    end
  end
end

