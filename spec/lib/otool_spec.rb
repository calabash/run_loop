
describe RunLoop::Otool do
  let(:path) { "/path/to/some/file" }
  let(:app) { RunLoop::App.new(Resources.shared.app_bundle_path) }
  let(:executable) { File.join(app.path, app.executable_name) }
  let(:xcrun) { RunLoop::Xcrun.new }
  let(:xcode) { RunLoop::Xcode.new }
  let(:otool) { RunLoop::Otool.new(xcode) }

  describe ".new" do
    it "sets the @xcode instance variable" do
      xcode = RunLoop::Xcode.new
      otool = RunLoop::Otool.new(xcode)
      expect(otool.instance_variable_get(:@xcode)).to be == xcode
      expect(otool.send(:xcode)).to be == xcode
    end
  end

  it "#to_s" do
    ap otool
  end

  it "#inspect" do
    otool.inspect
  end

  context "#executable?" do
    before do
      expect(otool).to receive(:expect_valid_path!).with(path).and_return(true)
    end

    it "returns true if otool says it is an object file" do
      expect(otool).to(
        receive(:arch_info).with(path).and_return("Anything but not-an-object-file")
      )

      expect(otool.executable?(path)).to be_truthy
    end

    it "returns false if otool says it is not an object file" do
      expect(otool).to receive(:arch_info).with(path).and_return("is not an object file")

      expect(otool.executable?(path)).to be_falsey
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

    let(:command_name) { "depends on xcode version" }

    let(:args) { [command_name, "-hv", "-arch", "all", path] }
    let(:options) { {:log_cmd => false } }

    before do
      allow(otool).to receive(:xcrun).and_return(xcrun)
      allow(otool).to receive(:command_name).and_return(command_name)
    end

    it "returns arch information" do
      expect(xcrun).to(
        receive(:run_command_in_context).with(args, options).and_return(hash)
      )

      expect(otool.send(:arch_info, path)).to be == hash[:out]
    end

    it "raises error if there is a problem" do
      hash[:exit_status] = 1
      expect(xcrun).to receive(:run_command_in_context).and_return(hash)

      expect do
        otool.send(:arch_info, path)
      end.to raise_error RuntimeError, /Could not get arch info from file:/
    end
  end

  describe "#expect_valid_path!" do
    it "returns true for valid paths" do
      expect(File).to receive(:exist?).with(path).and_return(true)
      expect(File).to receive(:directory?).with(path).and_return(false)

      expect(otool.send(:expect_valid_path!, path)).to be_truthy
    end

    it "raises an error if no file exists at path" do
      expect(File).to receive(:exist?).with(path).and_return(false)

      expect do
        otool.send(:expect_valid_path!, path)
      end.to raise_error ArgumentError, /must exist and not be a directory/
    end

    it "raises an error if file is a directory" do
      expect(File).to receive(:exist?).with(path).and_return(true)
      expect(File).to receive(:directory?).with(path).and_return(true)
      expect do
        otool.send(:expect_valid_path!, path)
      end.to raise_error ArgumentError, /must exist and not be a directory/
    end
  end

  context "#command_name" do

    before do
      expect(otool).to receive(:xcode).and_return(xcode)
    end

    it "returns 'otool-classic' for Xcode >= 8.0" do
      expect(xcode).to receive(:version_gte_8?).and_return(true)

      expect(otool.send(:command_name)).to be == "otool-classic"
    end

    it "returns 'otool' for Xcode < 8.0" do
      expect(xcode).to receive(:version_gte_8?).and_return(false)

      expect(otool.send(:command_name)).to be == "otool"
    end

    it "sets the @command_name instance variable" do
      command_name = otool.send(:command_name)
      expect(otool.send(:command_name)).to be == command_name
      expect(otool.instance_variable_get(:@command_name)).to be == command_name
    end
  end

  context "#xcrun" do
    it "returns an instance of Xcrun" do
      xcrun = otool.send(:xcrun)
      expect(otool.send(:xcrun)).to be == xcrun
      expect(otool.instance_variable_get(:@xcrun)).to be == xcrun
      expect(xcrun).to be_a_kind_of(RunLoop::Xcrun)
    end
  end
end

