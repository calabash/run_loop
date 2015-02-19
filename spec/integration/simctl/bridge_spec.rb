describe RunLoop::Simctl::Bridge do

  def select_random_shutdown_sim
    simctl = RunLoop::SimControl.new
    simctl.simulators.shuffle.detect do |device|
      [device.state == 'Shutdown',
       device.name != 'rspec-test-device',
       !device.name[/Resizable/,0]].all?
    end
  end

  it 'can install an app and launch the simulator' do
    device = select_random_shutdown_sim
    abp = Resources.shared.app_bundle_path
    bridge = RunLoop::Simctl::Bridge.new(device, abp)
    expect(bridge.launch).to be == true
  end

end
