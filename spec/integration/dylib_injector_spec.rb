if Resources.shared.core_simulator_env? && Resources.shared.whoami == 'moody'

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

    describe '#inject_dylib_with_timeout' do
      it 'targeting the simulator' do
        Resources.shared.with_debugging do
          device = select_random_shutdown_sim
          abp = Resources.shared.app_bundle_path
          bridge = RunLoop::Simctl::Bridge.new(device, abp)
          expect(bridge.launch).to be == true

          app = RunLoop::App.new(abp)
          dylib = Resources.shared.sim_dylib_path
          injector = RunLoop::DylibInjector.new(app.executable_name, dylib)
          expect { injector.inject_dylib_with_timeout(1) }.to raise_error RuntimeError
        end
      end
    end

    describe '#retriable_inject_dylib' do
      it 'targeting the simulator' do
        Resources.shared.with_debugging do
          device = select_random_shutdown_sim
          abp = Resources.shared.app_bundle_path
          bridge = RunLoop::Simctl::Bridge.new(device, abp)
          expect(bridge.launch).to be == true

          app = RunLoop::App.new(abp)
          dylib = Resources.shared.sim_dylib_path
          injector = RunLoop::DylibInjector.new(app.executable_name, dylib)

          vals = [false, false]
          options = { retries: vals.count + 1}
          expect(injector).to receive(:inject_dylib_with_timeout).exactly(vals.count).times.and_return(*vals)
          expect(injector).to receive(:inject_dylib_with_timeout).and_call_original
          expect(injector.retriable_inject_dylib(options)).to be == true
        end
      end
    end
  end
end
