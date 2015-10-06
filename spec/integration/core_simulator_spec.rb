describe RunLoop::CoreSimulator do
  let(:simulator) { RunLoop::SimControl.new.simulators.sample }
  let(:app) { RunLoop::App.new(Resources.shared.cal_app_bundle_path) }
  let(:xcrun) { RunLoop::Xcrun.new }

  let(:core_sim) do
    RunLoop::CoreSimulator.new(simulator, app)
  end

  before do
    allow(RunLoop::Environment).to receive(:debug?).and_return true
  end

  it '#launch_simulator' do
    expect(core_sim.launch_simulator).to be_truthy
  end

  it '#launch' do
    expect(core_sim.launch).to be_truthy
  end

  it 'install with simctl' do
    args = ['simctl', 'erase', simulator.udid]
    xcrun.exec(args, {:log_cmd => true })

    simulator.simulator_wait_for_stable_state

    expect(core_sim.install)

    expect(core_sim.launch)
  end
end
