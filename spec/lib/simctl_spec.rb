
describe RunLoop::Simctl do
  let(:device) { Resources.shared.default_simulator }
  let(:simctl) { RunLoop::Simctl.new }
  let(:xcrun) { RunLoop::Xcrun.new }
  let(:xcode) { RunLoop::Xcode.new }
  let(:defaults) { RunLoop::Simctl::DEFAULTS }

  it "has a constant that points to plist dir" do
    dir = RunLoop::Simctl::SIMCTL_PLIST_DIR
    expect(Dir.exist?(dir)).to be_truthy
  end

  it "returns uia plist path" do
    expect(File.exist?(RunLoop::Simctl.uia_automation_plist)).to be_truthy
  end

  it "returns uia plugin plist path" do
    expect(File.exist?(RunLoop::Simctl.uia_automation_plugin_plist)).to be_truthy
  end

  it ".new" do
  end

  describe "#app_container" do

    let(:bundle_id) { "sh.calaba.LPTestTarget" }
    let(:cmd) { ["simctl", "get_app_container", device.udid, bundle_id]  }
    let(:hash) do
      {
        :pid => 1,
        :out => "path/to/My.app#{$-0}",
        :exit_status => 0
      }
    end

    before do
      expect(simctl).to receive(:xcode).and_return(xcode)
    end

    describe "Xcode >= 7" do
      before do
        expect(xcode).to receive(:version_gte_7?).and_return(true)
      end

      it "app is installed" do
        expect(simctl).to receive(:execute).with(cmd, defaults).and_return(hash)

        expect(simctl.app_container(device, bundle_id)).to be == hash[:out].strip
      end

      it "app is not installed" do
        hash[:exit_status] = 1
        expect(simctl).to receive(:execute).with(cmd, defaults).and_return(hash)
        expect(simctl.app_container(device, bundle_id)).to be == nil
      end
    end

    it "Xcode < 7" do
      expect(xcode).to receive(:version_gte_7?).and_return(false)

      expect(simctl.app_container(device, bundle_id)).to be == nil
    end
  end

  it "#execute" do
    options = {:a => :b}
    merged = RunLoop::Simctl::DEFAULTS.merge(options)
    cmd = ["simctl", "subcommand"]
    expect(simctl).to receive(:xcrun).and_return(xcrun)
    expect(xcrun).to receive(:exec).with(cmd, merged).and_return({})

    expect(simctl.send(:execute, cmd, options)).to be == {}
  end

  it "#xcrun" do
    actual = simctl.send(:xcrun)
    expect(actual).to be_a_kind_of(RunLoop::Xcrun)
    expect(simctl.instance_variable_get(:@xcrun)).to be == actual
  end

  it "#xcode" do
    actual = simctl.send(:xcode)
    expect(actual).to be_a_kind_of(RunLoop::Xcode)
    expect(simctl.instance_variable_get(:@xcode)).to be == actual
  end

  it "#sim_control" do
    actual = simctl.send(:sim_control)
    expect(actual).to be_a_kind_of(RunLoop::SimControl)
    expect(simctl.instance_variable_get(:@sim_control)).to be == actual
  end
end