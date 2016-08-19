
describe RunLoop::DeviceAgent::Runner do
  let(:device) { Resources.shared.device("9.0") }
  let(:simulator) { Resources.shared.simulator("9.0") }

  it ".new" do
    runner = RunLoop::DeviceAgent::Runner.new(device)
    expect(runner.device).to be == device
    expect(runner.instance_variable_get(:@device)).to be == device
  end

  describe "instance methods" do
    let(:runner) { RunLoop::DeviceAgent::Runner.new(device) }
    let(:app) { "path/to/DeviceAgent-Runner.app" }
    let(:xctest) { File.join(app, "PlugIns", "DeviceAgent.xctest") }
    let(:plist) { File.join(app, "Info.plist") }

    it "#pbuddy" do
      pbuddy = runner.send(:pbuddy)
      expect(pbuddy).to be_a_kind_of(RunLoop::PlistBuddy)
      expect(runner.instance_variable_get(:@pbuddy)).to be == pbuddy
    end

    it "#info_plist" do
      expect(runner).to receive(:runner).and_return(app)
      actual = runner.send(:info_plist)
      expect(actual).to be == plist
      expect(runner.instance_variable_get(:@info_plist)).to be == plist
    end

    describe "#runner" do
      it "physical device" do
        expect(device).to receive(:physical_device?).at_least(:once).and_return(true)
        expect(RunLoop::DeviceAgent::Runner).to receive(:detect_cbxdevice).and_return(app)

        expect(runner.runner).to be == app
      end

      it "simulator" do
        expect(device).to receive(:physical_device?).at_least(:once).and_return(false)
        expect(RunLoop::DeviceAgent::Runner).to receive(:detect_cbxsim).and_return(app)

        expect(runner.runner).to be == app
      end
    end

    it "#tester" do
      expect(runner).to receive(:runner).and_return(app)

      actual = runner.tester
      expect(actual).to be == xctest
      expect(runner.instance_variable_get(:@tester)).to be == xctest
    end

    it "#version" do
      pbuddy = RunLoop::PlistBuddy.new
      expect(runner).to receive(:info_plist).twice.and_return(plist)
      expect(pbuddy).to receive(:plist_read).with("CFBundleShortVersionString", plist).and_return("1.0.0")
      expect(pbuddy).to receive(:plist_read).with("CFBundleVersion", plist).and_return("5")
      expect(runner).to receive(:pbuddy).twice.and_return(pbuddy)

      expected = RunLoop::Version.new("1.0.0.pre5")
      actual = runner.version
      expect(actual).to be == expected
      expect(runner.instance_variable_get(:@version)).to be == expected
    end
  end

  it ".device_agent_dir" do
    path = RunLoop::DeviceAgent::Runner.device_agent_dir
    expect(RunLoop::DeviceAgent::Runner.class_variable_get(:@@device_agent_dir)).to be == path

    expect(File).not_to receive(:expand_path)
    expect(RunLoop::DeviceAgent::Runner.device_agent_dir).to be == path
  end

  describe ".detect_cbxdevice" do
    let(:path) { "path/to/DeviceAgent-Runner.app" }

    before do
      RunLoop::DeviceAgent::Runner.class_variable_set(:@@cbxdevice, nil)
    end

    describe "CBXDEVICE" do
      it "exists" do
        expect(RunLoop::Environment).to receive(:cbxdevice).and_return(path)
        expect(File).to receive(:exist?).and_return(true)

        expect(RunLoop::DeviceAgent::Runner.detect_cbxdevice).to be == path
      end

      it "does not exist" do
        expect(RunLoop::Environment).to receive(:cbxdevice).and_return(path)
        expect(File).to receive(:exist?).and_return(false)

        expect do
          RunLoop::DeviceAgent::Runner.detect_cbxdevice
        end.to raise_error(RuntimeError,
                           /CBXDEVICE environment variable defined:/)
      end
    end

    it "default" do
      expect(RunLoop::Environment).to receive(:cbxdevice).and_return(nil)
      expect(RunLoop::DeviceAgent::Runner).to receive(:default_cbxdevice).and_return(path)

      expect(RunLoop::DeviceAgent::Runner.detect_cbxdevice).to be == path
    end
  end

  describe ".detect_cbxsim" do
    let(:path) { "path/to/DeviceAgent-Runner.app" }

    before do
      RunLoop::DeviceAgent::Runner.class_variable_set(:@@cbxsim, nil)
    end

    describe "CBXSIM" do
      it "exists" do
        expect(RunLoop::Environment).to receive(:cbxsim).and_return(path)
        expect(File).to receive(:exist?).and_return(true)

        expect(RunLoop::DeviceAgent::Runner.detect_cbxsim).to be == path
      end

      it "does not exist" do
        expect(RunLoop::Environment).to receive(:cbxsim).and_return(path)
        expect(File).to receive(:exist?).and_return(false)

        expect do
          RunLoop::DeviceAgent::Runner.detect_cbxsim
        end.to raise_error(RuntimeError,
                           /CBXSIM environment variable defined:/)
      end
    end

    it "default" do
      expect(RunLoop::Environment).to receive(:cbxsim).and_return(nil)
      expect(RunLoop::DeviceAgent::Runner).to receive(:default_cbxsim).and_return(path)

      expect(RunLoop::DeviceAgent::Runner.detect_cbxsim).to be == path
    end
  end

  describe ".default_cbxdevice" do
    let(:dir) { "path/to/device_agent" }
    let(:ipa) { File.join(dir, "ipa", "DeviceAgent-Runner.app") }
    let(:zip) { File.join(dir, "ipa", "DeviceAgent-Runner.app.zip") }

    before do
      expect(RunLoop::DeviceAgent::Runner).to receive(:device_agent_dir).and_return(dir)
    end

    it "returns default if already expanded" do
      expect(File).to receive(:exist?).with(ipa).and_return(true)

      expect(RunLoop::DeviceAgent::Runner.default_cbxdevice).to be == ipa
    end

    it "expands the default" do
      expect(File).to receive(:exist?).with(ipa).and_return(false)
      expect(RunLoop::DeviceAgent::Runner).to receive(:expand_runner_archive).with(zip).and_return(ipa)

      expect(RunLoop::DeviceAgent::Runner.default_cbxdevice).to be == ipa
    end
  end

  describe ".default_cbxsim" do
    let(:dir) { "path/to/device_agent" }
    let(:app) { File.join(dir, "app", "DeviceAgent-Runner.app") }
    let(:zip) { File.join(dir, "app", "DeviceAgent-Runner.app.zip") }

    before do
      expect(RunLoop::DeviceAgent::Runner).to receive(:device_agent_dir).and_return(dir)
    end

    it "returns default if already expanded" do
      expect(File).to receive(:exist?).with(app).and_return(true)

      expect(RunLoop::DeviceAgent::Runner.default_cbxsim).to be == app
    end

    it "expands the default" do
      expect(File).to receive(:exist?).with(app).and_return(false)
      expect(RunLoop::DeviceAgent::Runner).to receive(:expand_runner_archive).with(zip).and_return(app)

      expect(RunLoop::DeviceAgent::Runner.default_cbxsim).to be == app
    end
  end
end
