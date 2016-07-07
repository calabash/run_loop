
describe RunLoop::XCUITest do

  before do
    allow(RunLoop::Environment).to receive(:debug?).and_return(true)
  end

  describe "#launch" do
    let(:device) { Resources.shared.default_simulator }
    let(:bundle_identifier) { "com.apple.Preferences" }

    it "xcodebuild" do
      cbx_launcher = RunLoop::DeviceAgent::Xcodebuild.new(device)
      xcuitest = RunLoop::XCUITest.new(bundle_identifier, device, cbx_launcher)

      expect do
        xcuitest.launch
      end.to raise_error(RuntimeError, /The CBXWS env var is undefined. Are you a maintainer/)
    end

    it "ios_device_manager" do
      cbx_launcher = RunLoop::DeviceAgent::IOSDeviceManager.new(device)
      xcuitest = RunLoop::XCUITest.new(bundle_identifier, device, cbx_launcher)
      xcuitest.launch
    end
  end
end
