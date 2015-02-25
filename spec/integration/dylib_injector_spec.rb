describe RunLoop::DylibInjector do

  def select_random_shutdown_sim
    simctl = RunLoop::SimControl.new
    simctl.simulators.shuffle.detect do |device|
      [device.state == 'Shutdown',
       device.name != 'rspec-test-device',
       !device.name[/Resizable/,0]].all?
    end
  end

  before(:each) {
    RunLoop::SimControl.new.reset_sim_content_and_settings
  }

  describe 'injecting a dylib targeting the simulator with' do
    it "Xcode #{Resources.shared.current_xcode_version}" do
      ENV['DEBUG'] = '1'
      device = select_random_shutdown_sim
      abp = Resources.shared.app_bundle_path
      bridge = RunLoop::Simctl::Bridge.new(device, abp)
      expect(bridge.launch).to be == true

      app = RunLoop::App.new(abp)
      dylib = Resources.shared.sim_dylib_path
      injector = RunLoop::DylibInjector.new(app.executable_name, dylib)
      expect(injector.inject_dylib).to be == true
    end
  end
end
