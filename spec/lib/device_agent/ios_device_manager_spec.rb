
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

    context "xctestrun path" do
      let(:runner_bundle) { File.expand_path("path/to/DeviceAgent-Runner.app") }
      let(:xctest_bundle) { File.join(runner_bundle, "PlugIns", "DeviceAgent.xctest") }
      let(:runner) { RunLoop::DeviceAgent::Runner.new(device) }

      before do
        allow(runner).to receive(:runner).and_return(runner_bundle)
        allow(runner).to receive(:tester).and_return(xctest_bundle)
        allow_any_instance_of(RunLoop::DeviceAgent::IOSDeviceManager).to(
          receive(:runner).and_return(runner)
        )
      end
      context "#path_to_xctestrun_template" do
        it "raises an argument error if device is a physical device" do
          expect do
            RunLoop::DeviceAgent::IOSDeviceManager.new(device).path_to_xctestrun_template
          end.to raise_error(ArgumentError, /Physical devices do not require an xctestrun template/)
        end

        it "raises an error if simulator template does not exist" do
          expect do
            RunLoop::DeviceAgent::IOSDeviceManager.new(simulator).path_to_xctestrun_template
          end.to raise_error(RuntimeError, /Could not find an xctestrun template at path/)
        end

        it "returns a path to xctestrun file template for simulators" do
          expected = File.join(xctest_bundle, "DeviceAgent-simulator-template.xctestrun")
          expect(File).to receive(:exist?).with(expected).and_return(true)

          actual = RunLoop::DeviceAgent::IOSDeviceManager.new(simulator).path_to_xctestrun_template
          expect(actual).to be == expected
        end
      end

      context "#path_to_xctestrun" do
        it "returns a path to xctestrun file for a physical device" do
          expected = File.join(xctest_bundle, "DeviceAgent-device.xctestrun")
          expect(File).to receive(:exist?).with(expected).and_return(true)

          actual = RunLoop::DeviceAgent::IOSDeviceManager.new(device).path_to_xctestrun
          expect(actual).to be == expected
        end

        it "raises an error if xctestrun file for physical device does not exist" do
          expect do
            RunLoop::DeviceAgent::IOSDeviceManager.new(device).path_to_xctestrun
          end.to raise_error(RuntimeError, /Could not find an xctestrun file at path/)
        end

        it "returns ~/.run-loop/DeviceAgent/DeviceAgent-simulator.xctestrun with TEST_HOST_PATH substituted" do
          template = File.join("tmp", "DeviceAgent-Runner.app", "DeviceAgent-simulator-template.xctestrun")
          FileUtils.mkdir_p(File.dirname(template))
          File.open(template, "w:UTF-8") do |file|
            file.puts("TEST_HOST_PATH")
          end

          idm = RunLoop::DeviceAgent::IOSDeviceManager.new(simulator)
          expect(idm).to receive(:path_to_xctestrun_template).and_return(template)

          expected = File.join(RunLoop::DeviceAgent::IOSDeviceManager.dot_dir, "DeviceAgent-simulator.xctestrun")
          actual = idm.path_to_xctestrun
          expect(actual).to be == expected

          contents = File.read(actual).force_encoding("UTF-8")
          expect(contents[/TEST_HOST_PATH/]).to be_falsey
          expect(contents[/#{runner_bundle}/]).to be_truthy

          # template is untouched
          contents = File.read(template).force_encoding("UTF-8")
          expect(contents[/TEST_HOST_PATH/]).to be_truthy
        end
      end
    end
  end
end
