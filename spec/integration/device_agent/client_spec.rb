
describe RunLoop::DeviceAgent::Client do

  before do
    allow(RunLoop::Environment).to receive(:debug?).and_return(true)
  end

  describe "#launch" do
    let(:device) { Resources.shared.default_simulator }
    let(:bundle_identifier) { "com.apple.Preferences" }

    before do
      RunLoop::CoreSimulator.quit_simulator
      RunLoop::Simctl.new.wait_for_shutdown(device, 30, 0.1)
    end

    it "xcodebuild" do
      workspace = File.expand_path(File.join("..", "DeviceAgent.iOS", "DeviceAgent.xcworkspace"))
      if File.exist?(workspace)
        cbx_launcher = RunLoop::DeviceAgent::Xcodebuild.new(device)
        client = RunLoop::DeviceAgent::Client.new(bundle_identifier,
                                                  device,
                                                  cbx_launcher,
                                                  {})
        client.launch

        options = { :raise_on_timeout => true, :timeout => 5 }
        RunLoop::ProcessWaiter.new("Preferences", options).wait_for_any

        if RunLoop::Environment.ci?
          sleep(5)
        else
          sleep(1)
        end

        point = client.query_for_coordinate({marked: "General"})
        client.perform_coordinate_gesture("touch", point[:x], point[:y])
      else
        RunLoop.log_debug("Skipping :xcodebuild cbx launcher test")
        RunLoop.log_debug("Could not find a DeviceAgent.iOS repo")
      end
    end
  end
end
