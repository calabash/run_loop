describe "Detect iOS Simulators" do
  it "Instruments and Simctl agree on the simulator count" do
    simcontrol = Resources.shared.simctl.simulators.count
    instruments = Resources.shared.instruments.simulators.count
    expect(instruments).to be == simcontrol
  end
end

