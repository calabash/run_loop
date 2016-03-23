
describe RunLoop::XCUITest do

  before do
    allow(RunLoop::Environment).to receive(:debug?).and_return(true)
  end

  it "#launch" do
    device = Resources.shared.default_simulator
    bundle_identifier = "com.apple.Preferences"
    xcuitest = RunLoop::XCUITest.new(bundle_identifier, device)
    xcuitest.launch
  end
end