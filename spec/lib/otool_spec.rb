
describe RunLoop::Otool do
  let(:path) { "/path/to/some/file" }
  let(:app) { RunLoop::App.new(Resources.shared.app_bundle_path) }
  let(:executable) { File.join(app.path, app.executable_name) }
  let(:xcrun) { RunLoop::Xcrun.new }
  let(:otool) { RunLoop::Otool.new(executable) }

  describe ".new" do
    it "sets the @path instance variable" do
      expect(RunLoop::Otool).to receive(:valid_path?).with(path).and_return(true)

      otool = RunLoop::Otool.new(path)

      expect(otool.path).to be == path
      expect(otool.instance_variable_get(:@path)).to be == path
    end

    it "raises an error if path is invalid" do
      expect(RunLoop::Otool).to receive(:valid_path?).with(path).and_return(false)

      expect do
        RunLoop::Otool.new(path)
      end.to raise_error ArgumentError, /must exist and not be a directory/
    end
  end

  describe "#executable?" do
    it "true" do
      expect(otool).to receive(:arch_info).and_return("Anything but not-an-object-file")

      expect(otool.executable?).to be_truthy
    end

    it "false" do
      expect(otool).to receive(:arch_info).and_return("is not an object file")

      expect(otool.executable?).to be_falsey
    end
  end

  it "#to_s" do
    ap otool
  end

  it "#inspect" do
    otool.inspect
  end

  describe ".valid_path?" do
    it "returns true for valid paths" do
      expect(File).to receive(:exist?).with(path).and_return(true)
      expect(File).to receive(:directory?).with(path).and_return(false)

      expect(RunLoop::Otool.send(:valid_path?, path)).to be_truthy
    end

    describe "false if" do
      it "file does not exist at path" do
        expect(File).to receive(:exist?).with(path).and_return(false)

        expect(RunLoop::Otool.send(:valid_path?, path)).to be_falsey
      end

      it "file is a directory" do
        expect(File).to receive(:exist?).with(path).and_return(true)
        expect(File).to receive(:directory?).with(path).and_return(true)

        expect(RunLoop::Otool.send(:valid_path?, path)).to be_falsey
      end
    end
  end

  describe "#arch_info" do
    let(:hash) do
      {
        :exit_status => 0,
        :out => "the output",
        :pid => 111
      }
    end

    before do
      allow(otool).to receive(:xcrun).and_return(xcrun)
    end

    it "returns arch information" do
      expect(xcrun).to receive(:exec).and_return(hash)

      expect(otool.send(:arch_info)).to be == hash[:out]
      expect(otool.instance_variable_get(:@arch_info)).to be == hash[:out]
    end

    it "raises error if there is a problem" do
      hash[:exit_status] = 1
      expect(xcrun).to receive(:exec).and_return(hash)

      expect do
        otool.send(:arch_info)
      end.to raise_error RuntimeError, /Could not get arch info from file:/
    end
  end
end

