
describe RunLoop::Simctl do

  let(:simctl) { Resources.shared.simctl }
  let(:sim_control) { Resources.shared.sim_control }
  let(:device) { Resources.shared.simctl.simulators.sample }

  it "SimControl and Simctl return same simulators" do
    from_sim_control = sim_control.simulators
    from_simctl = simctl.simulators

    # Devices are not object-equal with ==, so the best we can do here is
    # check the simulator count.
    expect(from_sim_control.count).to be == from_simctl.count
  end

  it "#shutdown" do
    expect(simctl.shutdown(device)).to be_truthy
  end

  it "#wait_for_shutdown" do
    expect(simctl.wait_for_shutdown(device, 0.1, 0)).to be_truthy
  end

  it "#erase" do
    timeout = RunLoop::CoreSimulator::DEFAULT_OPTIONS[:wait_for_state_timeout]
    delay = RunLoop::CoreSimulator::WAIT_FOR_SIMULATOR_STATE_INTERVAL
    expect(simctl.erase(device, timeout, delay)).to be_truthy
  end

  it "#launch"
end
