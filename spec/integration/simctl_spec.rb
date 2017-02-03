
describe RunLoop::Simctl do

  let(:simctl) { Resources.shared.simctl }
  let(:device) { Resources.shared.default_simulator }
  let(:app) { RunLoop::App.new(Resources.shared.cal_app_bundle_path) }
  let(:core_sim) { RunLoop::CoreSimulator.new(device, app) }

  before do
    allow(RunLoop::Environment).to receive(:debug?).and_return(true)
    RunLoop::CoreSimulator.quit_simulator
  end

  it "#shutdown" do
    expect(simctl.shutdown(device)).to be_truthy
  end

  it "#wait_for_shutdown" do
    RunLoop::CoreSimulator.quit_simulator
    core_sim = RunLoop::CoreSimulator.new(device, app)
    core_sim.launch_simulator
    RunLoop::CoreSimulator.quit_simulator
    expect(simctl.wait_for_shutdown(device, 10.0, 0)).to be_truthy
  end

  it "handles the app life cycle" do
    timeout = RunLoop::CoreSimulator::DEFAULT_OPTIONS[:wait_for_state_timeout]
    delay = RunLoop::CoreSimulator::WAIT_FOR_SIMULATOR_STATE_INTERVAL
    expect(simctl.erase(device, timeout, delay)).to be_truthy

    core_sim.launch_simulator

    timeout = RunLoop::CoreSimulator::DEFAULT_OPTIONS[:install_app_timeout]
    expect(simctl.install(device, app, timeout)).to be_truthy
    options = { :timeout => 10, :raise_on_timeout => true }
    device.simulator_wait_for_stable_state

    timeout = RunLoop::CoreSimulator::DEFAULT_OPTIONS[:launch_app_timeout]
    expect(simctl.launch(device, app, timeout)).to be_truthy
    RunLoop::ProcessWaiter.new(app.executable_name, options).wait_for_any
    device.simulator_wait_for_stable_state

    timeout = RunLoop::CoreSimulator::DEFAULT_OPTIONS[:uninstall_app_timeout]
    expect(simctl.uninstall(device, app, timeout)).to be_truthy
    device.simulator_wait_for_stable_state

    RunLoop::CoreSimulator.quit_simulator
  end
end
