
describe RunLoop::DeviceAgent::IOSDeviceManager do

  let(:device) { Resources.shared.device("9.0") }
  let(:simulator) { Resources.shared.simulator("9.0") }

  it ".device_agent_dir" do
    path = RunLoop::DeviceAgent::IOSDeviceManager.device_agent_dir
    expect(RunLoop::DeviceAgent::IOSDeviceManager.class_variable_get(:@@device_agent_dir)).to be == path

    expect(File).not_to receive(:expand_path)
    expect(RunLoop::DeviceAgent::IOSDeviceManager.device_agent_dir).to be == path
  end

  describe ".ios_device_manager" do

    before do
      RunLoop::DeviceAgent::IOSDeviceManager.class_variable_set(:@@ios_device_manager, nil)
    end

    describe "IOS_DEVICE_MANAGER" do
      let(:path) { "/path/to/alternative/iOSDeviceManager" }

      it "returns value" do
        expect(RunLoop::Environment).to receive(:ios_device_manager).and_return(path)
        expect(File).to receive(:exist?).with(path).and_return(true)

        expect(RunLoop::DeviceAgent::IOSDeviceManager.ios_device_manager).to be == path
      end

      it "raises error if path does not exist" do
        expect(RunLoop::Environment).to receive(:ios_device_manager).and_return(path)
        expect(File).to receive(:exist?).with(path).and_return(false)

        expect do
          RunLoop::DeviceAgent::IOSDeviceManager.ios_device_manager
        end.to raise_error(RuntimeError,
                           /IOS_DEVICE_MANAGER environment variable defined:/)
      end
    end

    it "default location" do
      expect(RunLoop::DeviceAgent::IOSDeviceManager).to receive(:device_agent_dir).and_return("/tmp")
      expect(RunLoop::Environment).to receive(:ios_device_manager).and_return(nil)

      expect(RunLoop::DeviceAgent::IOSDeviceManager.ios_device_manager).to be == "/tmp/bin/iOSDeviceManager"
    end
  end

  describe "file system" do
    let(:dot_dir) { File.expand_path(File.join("tmp", ".run-loop", "DeviceAgent")) }

    before do
      FileUtils.mkdir_p(dot_dir)
      allow(RunLoop::DeviceAgent::LauncherStrategy).to receive(:dot_dir).and_return(dot_dir)
    end

    describe ".log_file" do
      let(:path) { File.join(dot_dir, "current.log") }

      it "returns ~/.run-loop/DeviceAgent/current.log after creating it" do
        FileUtils.rm_rf(path)

        expect(RunLoop::DeviceAgent::IOSDeviceManager.log_file).to be == path
        expect(File.exist?(path)).to be_truthy
      end

      it "returns ~/.run-loop/DeviceAgent/current.log if it exists" do
        FileUtils.touch(path)
        expect(RunLoop::DeviceAgent::IOSDeviceManager.log_file).to be == path
      end

      it "returns ~/.run-loop/DeviceAgent/current.log after deleting legacy ios-device-manager.log" do
        legacy_path = File.join(dot_dir, "ios-device-manager.log")
        FileUtils.rm_rf(path)
        FileUtils.touch(legacy_path)

        expect(RunLoop::DeviceAgent::IOSDeviceManager.log_file).to be == path
        expect(File.exist?(path)).to be_truthy
        expect(File.exist?(legacy_path)).to be_falsey
      end
    end
  end
end

