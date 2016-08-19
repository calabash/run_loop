
describe RunLoop::DeviceAgent::Xcodebuild do
  let(:device) { Resources.shared.device("9.0") }
  let(:xcodebuild) { RunLoop::DeviceAgent::Xcodebuild.new(device) }

  describe "#name" do
    it "returns :xcodebuild" do
      expect(xcodebuild.name).to be == :xcodebuild
    end
  end

  describe "#workspace" do

    it "raises an error DeviceAgent.xcworkspace cannot be found" do
      expect(RunLoop::Environment).to receive(:cbxws).and_return(nil)
      path = "path/to/DeviceAgent.xcworkspace"
      expect(xcodebuild).to receive(:default_workspace).and_return(path)
      expect(File).to receive(:exist?).with(path).and_return(false)

      expect do
        xcodebuild.workspace
      end.to raise_error RuntimeError,
                         /Cannot find the DeviceAgent\.xcworkspace/
    end

    it "returns the path to the workspace indicated by the CBXWS env var" do
      path = "path/to/DeviceAgent.xcworkspace"
      expect(RunLoop::Environment).to receive(:cbxws).and_return(path)
      expect(File).to receive(:exist?).with(path).and_return(true)

      expect(xcodebuild.workspace).to be == path
    end

    it "returns the path to the default workspace if CBXWS is undefined" do
      path = "path/to/DeviceAgent.xcworkspace"
      expect(RunLoop::Environment).to receive(:cbxws).and_return(nil)
      expect(xcodebuild).to receive(:default_workspace).and_return(path)
      expect(File).to receive(:exist?).with(path).and_return(true)

      expect(xcodebuild.workspace).to be == path
    end
  end

  describe "file system" do
    let(:dot_dir) { File.expand_path(File.join("tmp", ".run-loop-xcuitest")) }
    let(:xcuitest_dir) { File.join(dot_dir, "xcuitest") }

    before do
      FileUtils.mkdir_p(dot_dir)
      allow(RunLoop::DotDir).to receive(:directory).and_return(dot_dir)
    end

    describe ".log_file" do
      before do
        FileUtils.mkdir_p(xcuitest_dir)
      end

      let(:path) { File.join(xcuitest_dir, "xcodebuild.log") }

      it "creates a file" do
        FileUtils.rm_rf(path)

        expect(RunLoop::DeviceAgent::Xcodebuild.log_file).to be == path
        expect(File.exist?(path)).to be_truthy
      end

      it "returns existing file path" do
        FileUtils.touch(path)
        expect(RunLoop::DeviceAgent::Xcodebuild.log_file).to be == path
      end
    end
  end
end
