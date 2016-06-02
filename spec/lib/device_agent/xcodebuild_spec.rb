
describe RunLoop::DeviceAgent::Xcodebuild do
  let(:device) { Resources.shared.default_simulator }
  let(:xcodebuild) { RunLoop::DeviceAgent::Xcodebuild.new(device) }

  describe "#workspace" do

    it "raises an error if CBXWS is not defined" do
      expect(RunLoop::Environment).to receive(:cbxws).and_return(nil)

      expect do
        xcodebuild.workspace
      end.to raise_error(RuntimeError,
                         /The CBXWS env var is undefined. Are you a maintainer/)
    end

    it "returns the path to the CBXDriver.xcworkspace" do
      path = "path/to/CBXDriver.xcworkspace"
      expect(RunLoop::Environment).to receive(:cbxws).and_return(path)

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

