if Resources.shared.core_simulator_env?

  describe RunLoop::Simctl::Bridge do

    before do
      RunLoop::SimControl.terminate_all_sims
    end

    let (:abp) { Resources.shared.cal_app_bundle_path }

    let (:sim_control) {
      obj = RunLoop::SimControl.new
      obj.reset_sim_content_and_settings
      obj
    }

    let (:device) {
      sim_control.simulators.find do |device|
        device.version > RunLoop::Version.new('7.1') &&
              !device.name[/Resizable/, 0] &&
              device.name != 'rspec-test-device'
      end
    }

    let(:bridge) { RunLoop::Simctl::Bridge.new(device, abp) }

    it 'can launch a specific simulator' do
      bridge.launch_simulator
    end

    it 'can install an app on a simulator' do
      expect(bridge.install).to be == true
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

    describe '#update_device_state' do
      it 'when no valid device state can be found' do
        options = {:tries => 5, :interval => 0.1}
        expect(bridge).to receive(:fetch_matching_device).at_least(:once).and_return(bridge.device)
        expect(bridge.device).to receive(:state).at_least(5).times.and_return(nil)
        expect {
          bridge.update_device_state(options)
        }.to raise_error(RunLoop::Simctl::SimctlError)
      end
    end

    it '#reset_app_sandbox' do
      bridge.launch
      bridge.reset_app_sandbox
    end
  end
end
