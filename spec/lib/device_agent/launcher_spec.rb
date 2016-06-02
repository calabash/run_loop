
describe RunLoop::DeviceAgent::Launcher do
  describe ".new" do
    it "sets instance variables" do
      device = Resources.shared.device("9.0")
      launcher = RunLoop::DeviceAgent::Launcher.new(device)
      expect(launcher.device).to be == device
      expect(launcher.instance_variable_get(:@device)).to be == device
    end

    it "raises an error if device version < 9.0" do
      device = Resources.shared.device("8.3")

      expect do
        RunLoop::DeviceAgent::Launcher.new(device)
      end.to raise_error(ArgumentError,
                         /XCUITest is only available for iOS >= 9.0/)

    end
  end

  describe "abstract methods" do
    let(:launcher) do
      device = Resources.shared.device("9.0")
      RunLoop::DeviceAgent::Launcher.new(device)
    end

    it "#launch" do
      expect do
        launcher.launch
      end.to raise_error RunLoop::Abstract::AbstractMethodError, /launch/
    end
  end

  describe "file system" do
    let(:dot_dir) { File.expand_path(File.join("tmp", ".run-loop-xcuitest")) }
    let(:xcuitest_dir) { File.join(dot_dir, "xcuitest") }

    before do
      FileUtils.mkdir_p(dot_dir)
      allow(RunLoop::DotDir).to receive(:directory).and_return(dot_dir)
    end

    describe ".dot_dir" do
      it "creates a directory" do
        FileUtils.rm_rf(dot_dir)

        actual = RunLoop::DeviceAgent::Xcodebuild.send(:dot_dir)
        expect(actual).to be == xcuitest_dir
        expect(File.directory?(actual)).to be_truthy
      end

      it "returns a path" do
        FileUtils.mkdir_p(xcuitest_dir)

        actual = RunLoop::DeviceAgent::Xcodebuild.send(:dot_dir)
        expect(actual).to be == xcuitest_dir
      end
    end
  end
end

