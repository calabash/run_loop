
describe RunLoop::Strings do
  let(:path) { "/path/to/some/file" }
  let(:app) { RunLoop::App.new(Resources.shared.app_bundle_path) }
  let(:executable) { File.join(app.path, app.executable_name) }
  let(:xcrun) { RunLoop::Xcrun.new }
  let(:strings) { RunLoop::Strings.new(executable) }

  describe ".new" do
    it "sets the @path instance variable" do
      expect(RunLoop::Strings).to receive(:valid_path?).with(path).and_return(true)

      strings = RunLoop::Strings.new(path)

      expect(strings.path).to be == path
      expect(strings.instance_variable_get(:@path)).to be == path
    end

    it "raises an error if path is invalid" do
      expect(RunLoop::Strings).to receive(:valid_path?).with(path).and_return(false)

      expect do
        RunLoop::Strings.new(path)
      end.to raise_error ArgumentError, /must exist and not be a directory/
    end
  end

  describe "#server_version" do
    let(:out) {
      [
        "some text",
        "other text",
        "CALABASH VERSION: 0.18.0",
        "more text"
      ]
    }

    it "extracts version string" do
      expect(strings).to receive(:dump).and_return(out.join($-0))

      actual = strings.server_version
      expected = RunLoop::Version.new("0.18.0")
      expect(actual).to be == expected
    end

    it "extracts pre-release version" do
      out[2] = "CALABASH VERSION: 0.18.1.pre5"
      expect(strings).to receive(:dump).and_return(out.join($-0))

      actual = strings.server_version
      expected = RunLoop::Version.new("0.18.1.pre5")
      expect(actual).to be == expected
    end

    it "returns nil if no match is found" do
      out[2] = "some symbols"
      expect(strings).to receive(:dump).and_return(out.join($-0))

      expect(strings.server_version).to be == nil
    end
  end

  it "#to_s" do
    ap strings
  end

  it "#inspect" do
    strings.inspect
  end

  describe ".valid_path?" do
    it "returns true for valid paths" do
      expect(File).to receive(:exist?).with(path).and_return(true)
      expect(File).to receive(:directory?).with(path).and_return(false)

      expect(RunLoop::Strings.send(:valid_path?, path)).to be_truthy
    end

    describe "false if" do
      it "file does not exist at path" do
        expect(File).to receive(:exist?).with(path).and_return(false)

        expect(RunLoop::Strings.send(:valid_path?, path)).to be_falsey
      end

      it "file is a directory" do
        expect(File).to receive(:exist?).with(path).and_return(true)
        expect(File).to receive(:directory?).with(path).and_return(true)

        expect(RunLoop::Strings.send(:valid_path?, path)).to be_falsey
      end
    end
  end

  describe "#dump" do
    let(:hash) do
      {
        :exit_status => 0,
        :out => "the output",
        :pid => 111
      }
    end

    before do
      allow(strings).to receive(:xcrun).and_return(xcrun)
    end

    it "returns arch information" do
      expect(xcrun).to receive(:run_command_in_context).and_return(hash)

      expect(strings.send(:dump)).to be == hash[:out]
      expect(strings.instance_variable_get(:@dump)).to be == hash[:out]
    end

    it "raises error if there is a problem" do
      hash[:exit_status] = 1
      expect(xcrun).to receive(:run_command_in_context).and_return(hash)

      expect do
        strings.send(:dump)
      end.to raise_error RuntimeError, /Could not get strings info from file:/
    end
  end
end

