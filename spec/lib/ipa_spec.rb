describe RunLoop::Ipa do

  let(:ipa_path) { Resources.shared.cal_ipa_path  }

  let(:ipa) { RunLoop::Ipa.new(ipa_path) }

  describe '.new' do
    describe 'raises an exception' do
      it 'when the path does not exist' do
        expect {
          RunLoop::Ipa.new('/path/does/not/exist')
        }.to raise_error(RuntimeError)
      end

      it 'when the path does not end in .ipa' do
        expect(File).to receive(:exist?).with('/path/foo.app').and_return(true)
        expect {
          RunLoop::Ipa.new('/path/foo.app')
        }.to raise_error(RuntimeError)
      end
    end

    it 'sets the path' do
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

