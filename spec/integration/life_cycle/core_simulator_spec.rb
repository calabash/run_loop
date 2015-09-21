describe RunLoop::LifeCycle::CoreSimulator do

  let(:sim_control) { RunLoop::SimControl.new }
  let(:simulator) { sim_control.simulators.sample }
  let(:app) { RunLoop::App.new(Resources.shared.cal_app_bundle_path) }
  let(:core_sim) do
    RunLoop::LifeCycle::CoreSimulator.new(app, simulator, sim_control)
  end

  before do
    allow(RunLoop::Environment).to receive(:debug?).and_return true
  end

  it '#launch_simulator' do
    expect(core_sim.launch_simulator).to be_truthy
  end

  it '#launch' do
    pending('Waiting on Apple to respond re: correct simctl usage')
    expect(core_sim.send(:launch)).to be_truthy
  end
end
