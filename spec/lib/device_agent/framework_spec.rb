
describe RunLoop::DeviceAgent::Frameworks do

  let(:instance) { RunLoop::DeviceAgent::Frameworks.instance }

  it "#rootdir" do
    actual = instance.send(:rootdir)
    expect(actual[/lib\/run_loop\/device_agent\/frameworks/, 0]).to be_truthy
  end

  describe "mocked rootdir" do
    let(:rootdir) { "run_loop/device_agent/frameworks" }

    before do
      allow(instance).to receive(:rootdir).and_return(rootdir)
    end

    it "#zip" do
      actual = instance.send(:zip)
      expect(actual[/run_loop\/device_agent\/frameworks\/Frameworks\.zip/, 0]).to be_truthy
    end

    it "#frameworks" do
      actual = instance.send(:frameworks)
      expect(actual[/run_loop\/device_agent\/frameworks\/Frameworks/, 0]).to be_truthy
    end

    it "#target" do
      dotdir = ".calabash"
      allow(RunLoop::DotDir).to receive(:directory).and_return(dotdir)
      actual = instance.send(:target)

      expect(actual[/\.calabash\/Frameworks/, 0]).to be_truthy
    end
  end

  it "#shell" do
    shell = instance.send(:shell)
    expect(shell.respond_to?(:run_shell_command)).to be_truthy
  end
end
