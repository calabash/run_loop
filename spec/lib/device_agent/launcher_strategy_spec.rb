
describe RunLoop::DeviceAgent::LauncherStrategy do
  describe ".new" do
    it "sets instance variables" do
      device = Resources.shared.device("9.0")
      launcher = RunLoop::DeviceAgent::LauncherStrategy.new(device)
      expect(launcher.device).to be == device
      expect(launcher.instance_variable_get(:@device)).to be == device
    end

    it "raises an error if device version < 9.0" do
      device = Resources.shared.device("8.3")

      expect do
        RunLoop::DeviceAgent::LauncherStrategy.new(device)
      end.to raise_error(ArgumentError,
                         /DeviceAgent is only available for iOS >= 9.0/)

    end
  end

  describe "abstract methods" do
    let(:launcher) do
      device = Resources.shared.device("9.0")
      RunLoop::DeviceAgent::LauncherStrategy.new(device)
    end

    it "#launch" do
      expect do
        launcher.launch({})
      end.to raise_error RunLoop::Abstract::AbstractMethodError, /launch/
    end

    it "#name" do
      expect do
        launcher.name
      end.to raise_error RunLoop::Abstract::AbstractMethodError, /name/
    end
  end

  context ".dot_dir" do
    let(:dot_dir) { File.expand_path(File.join("tmp", ".run-loop-xcuitest")) }
    let(:xcuitest_dir) { File.join(dot_dir, "xcuitest") }
    let(:device_agent_dir) { File.join(dot_dir, "DeviceAgent") }

    before do
      FileUtils.mkdir_p(dot_dir)
      allow(RunLoop::DotDir).to receive(:directory).and_return(dot_dir)
    end

    describe ".dot_dir" do
      it "returns a path to .run-loop/DeviceAgent directory after creating it" do
        FileUtils.rm_rf(dot_dir)

        actual = RunLoop::DeviceAgent::Xcodebuild.send(:dot_dir)
        expect(actual).to be == device_agent_dir
        expect(File.directory?(actual)).to be_truthy
      end

      it "returns a path to existing .run-loop/DeviceAgent directory" do
        FileUtils.mkdir_p(device_agent_dir)

        actual = RunLoop::DeviceAgent::Xcodebuild.send(:dot_dir)
        expect(actual).to be == device_agent_dir
      end

      it "returns a path to .run-loop/DeviceAgent directory after migrating legacy xcuitest directory" do
        FileUtils.rm_rf(dot_dir)
        FileUtils.mkdir_p(xcuitest_dir)
        FileUtils.mkdir_p(File.join(xcuitest_dir, "a"))
        FileUtils.mkdir_p(File.join(xcuitest_dir, "b"))
        FileUtils.touch(File.join(xcuitest_dir, "file.txt"))

        actual = RunLoop::DeviceAgent::Xcodebuild.send(:dot_dir)
        expect(actual).to be == device_agent_dir
        expect(File.directory?(actual)).to be_truthy
        expect(File.directory?(xcuitest_dir)).to be_falsey

        expect(File.directory?(File.join(device_agent_dir, "a"))).to be_truthy
        expect(File.directory?(File.join(device_agent_dir, "b"))).to be_truthy
        expect(File.exist?(File.join(device_agent_dir, "file.txt"))).to be_truthy
      end
    end
  end
end

