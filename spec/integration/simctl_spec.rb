
describe RunLoop::Simctl do

  let(:simctl) { Resources.shared.simctl }
  let(:sim_control) { Resources.shared.sim_control }

  it "SimControl and Simctl return same simulators" do
    from_sim_control = sim_control.simulators
    from_simctl = simctl.simulators

    # Devices are not object-equal with ==, so the best we can do here is
    # check the simulator count.
    expect(from_sim_control.count).to be == from_simctl.count
  end
end