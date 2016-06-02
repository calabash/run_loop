
describe RunLoop::DeviceAgent::Testctl do

  let(:device) { Resources.shared.device("9.0") }
  let(:simulator) { Resources.shared.simulator("9.0") }

  it ".device_agent_dir" do
    path = RunLoop::DeviceAgent::Testctl.device_agent_dir
    expect(RunLoop::DeviceAgent::Testctl.class_variable_get(:@@device_agent_dir)).to be == path

    expect(File).not_to receive(:expand_path)
    expect(RunLoop::DeviceAgent::Testctl.device_agent_dir).to be == path
  end

  describe ".testctl" do

    before do
      RunLoop::DeviceAgent::Testctl.class_variable_set(:@@testctl, nil)
    end

    describe "TESTCTL" do
      let(:path) { "/path/to/alternative/testctl" }

      it "returns value" do
        expect(RunLoop::Environment).to receive(:testctl).and_return(path)
        expect(File).to receive(:exist?).with(path).and_return(true)

        expect(RunLoop::DeviceAgent::Testctl.testctl).to be == path
      end

      it "raises error if path does not exist" do
        expect(RunLoop::Environment).to receive(:testctl).and_return(path)
        expect(File).to receive(:exist?).with(path).and_return(false)

        expect do
          RunLoop::DeviceAgent::Testctl.testctl
        end.to raise_error(RuntimeError,
                           /TESTCTL environment variable defined:/)

      end
    end

    it "default location" do
      expect(RunLoop::DeviceAgent::Testctl).to receive(:device_agent_dir).and_return("/tmp")
      expect(RunLoop::Environment).to receive(:testctl).and_return(nil)

      expect(RunLoop::DeviceAgent::Testctl.testctl).to be == "/tmp/bin/testctl"
    end
  end

  describe "file system" do
    let(:dot_dir) { File.expand_path(File.join("tmp", ".run-loop-xcuitest")) }
    let(:xcuitest_dir) { File.join(dot_dir, "xcuitest") }

    before do
      FileUtils.mkdir_p(dot_dir)
      allow(RunLoop::DeviceAgent::Launcher).to receive(:dot_dir).and_return(xcuitest_dir)
    end

    describe ".log_file" do
      before do
        FileUtils.mkdir_p(xcuitest_dir)
      end

      let(:path) { File.join(xcuitest_dir, "testctl.log") }

      it "creates a file" do
        FileUtils.rm_rf(path)

        expect(RunLoop::DeviceAgent::Testctl.log_file).to be == path
        expect(File.exist?(path)).to be_truthy
      end

      it "returns existing file path" do
        FileUtils.touch(path)
        expect(RunLoop::DeviceAgent::Testctl.log_file).to be == path
      end
    end
  end
end

