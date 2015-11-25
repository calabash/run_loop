describe "Detect iOS Simulators" do
  it "Instruments and SimControl agree on the simulator count" do
    simcontrol = RunLoop::SimControl.new.simulators.count
    instruments = RunLoop::Instruments.new.simulators.count
    expect(instruments).to be == simcontrol
  end
end

