
describe RunLoop::XCUITest do

  before do
    allow(RunLoop::Environment).to receive(:debug?).and_return(true)
  end

  describe "#launch" do
    let(:device) { Resources.shared.default_simulator }
    let(:bundle_identifier) { "com.apple.Preferences" }

    it "xcodebuild" do
      workspace = File.expand_path(File.join("..", "DeviceAgent.iOS", "CBXDriver.xcworkspace"))
      if File.exist?(workspace)
        expect(RunLoop::Environment).to receive(:cbxws).and_return(workspace)
        cbx_launcher = RunLoop::DeviceAgent::Xcodebuild.new(device)
        xcuitest = RunLoop::XCUITest.new(bundle_identifier, device, cbx_launcher)
        xcuitest.launch

        options = { :raise_on_timeout => true, :timeout => 5 }
        RunLoop::ProcessWaiter.new("Preferences", options).wait_for_any

        if RunLoop::Environment.ci?
          sleep(5)
        else
          sleep(1)
        end

        point = xcuitest.query_for_coordinate("General")
        xcuitest.perform_coordinate_gesture("touch", point[:x], point[:y])
      else
        RunLoop.log_debug("Skipping :xcodebuild cbx launcher test")
        RunLoop.log_debug("Could not find a DeviceAgent.iOS repo")
      end
    end

    it "ios_device_manager" do
      cbx_launcher = RunLoop::DeviceAgent::IOSDeviceManager.new(device)
      xcuitest = RunLoop::XCUITest.new(bundle_identifier, device, cbx_launcher)
      xcuitest.launch

      options = { :raise_on_timeout => true, :timeout => 5 }
      RunLoop::ProcessWaiter.new("Preferences", options).wait_for_any

      if RunLoop::Environment.ci?
        sleep(5)
      else
        sleep(1)
      end

      point = xcuitest.query_for_coordinate("General")
      xcuitest.perform_coordinate_gesture("touch", point[:x], point[:y])
    end
  end
end
