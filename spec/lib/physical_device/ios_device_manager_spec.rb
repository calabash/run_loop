
describe RunLoop::PhysicalDevice::IOSDeviceManager do

  context ".new" do
    it "calls super with device arg and expands the DeviceAgent Frameworks.zip" do
      frameworks = RunLoop::DeviceAgent::Frameworks.instance
      expect(frameworks).to receive(:install).and_return(true)
      device = Resources.shared.device

      manager = RunLoop::PhysicalDevice::IOSDeviceManager.new(device)
      expect(manager.device).to be == device
    end
  end
end
