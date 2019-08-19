describe "Detect iOS Simulators" do
  it "Instruments and Simctl agree on the simulator count" do
    simcontrol = RunLoop::Simctl.new.simulators.count
    instruments = RunLoop::Instruments.new.simulators.count
    expect(instruments).to be == simcontrol
  end
end

