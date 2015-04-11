describe RunLoop::Simctl::Bridge do

  let (:abp) { Resources.shared.app_bundle_path }
  let (:sim_control) { RunLoop::SimControl.new }
  let (:device) {
    sim_control.simulators.shuffle.detect do |device|
      [device.state == 'Shutdown',
       device.name != 'rspec-0test-device',
       !device.name[/Resizable/,0]].all?
    end
  }

  let(:bridge) { RunLoop::Simctl::Bridge.new(device, abp) }

  it 'can launch a specific simulator' do
    bridge.launch_simulator
  end

  it 'can install an app on a simulator and launch it' do
    expect(bridge.launch).to be == true
  end

  it 'can install an app, launch it, and uninstall it' do
    expect(bridge.launch).to be == true

    new_bridge = RunLoop::Simctl::Bridge.new(device, abp)
    expect(new_bridge.uninstall).to be == true
    expect(new_bridge.app_is_installed?).to be_falsey
  end
end
