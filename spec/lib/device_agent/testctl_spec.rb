
describe RunLoop::Testctl do

  it ".device_agent_dir" do
    path = RunLoop::Testctl.device_agent_dir
    expect(RunLoop::Testctl.class_variable_get(:@@device_agent_dir)).to be == path

    expect(File).not_to receive(:expand_path)
    expect(RunLoop::Testctl.device_agent_dir).to be == path
  end

  describe ".testctl" do

    before do
      RunLoop::Testctl.class_variable_set(:@@testctl, nil)
    end

    describe "TESTCTL" do
      let(:path) { "/path/to/alternative/testctl" }

      it "returns value" do
        expect(RunLoop::Environment).to receive(:testctl).and_return(path)
        expect(File).to receive(:exist?).with(path).and_return(true)

        expect(RunLoop::Testctl.testctl).to be == path
      end

      it "raises error if path does not exist" do
        expect(RunLoop::Environment).to receive(:testctl).and_return(path)
        expect(File).to receive(:exist?).with(path).and_return(false)

        expect do
          RunLoop::Testctl.testctl
        end.to raise_error(RuntimeError,
                           /TESTCTL environment variable defined:/)

      end
    end

    it "default location" do
      expect(RunLoop::Testctl).to receive(:device_agent_dir).and_return("/tmp")
      expect(RunLoop::Environment).to receive(:testctl).and_return(nil)

      expect(RunLoop::Testctl.testctl).to be == "/tmp/bin/testctl"
    end
  end

end
