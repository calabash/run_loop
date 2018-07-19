
describe RunLoop::DylibInjector do

  let(:device) { Resources.shared.default_simulator }
  let(:app_bundle) { Resources.shared.app_bundle_path }
  let(:app) { RunLoop::App.new(app_bundle) }
  let(:core_sim) { RunLoop::CoreSimulator.new(device, app) }
  let(:dylib) { Resources.shared.sim_dylib_path }
  let(:injector) { RunLoop::DylibInjector.new(app.executable_name, dylib) }

  before do
    allow(RunLoop::Environment).to receive(:debug?).and_return(true)
    RunLoop::CoreSimulator.quit_simulator
  end

  describe '#retriable_inject_dylib' do
    it 'targeting the simulator' do
      core_sim.send(:launch)
      expect(injector.retriable_inject_dylib).to be == true
    end
  end
end
