describe RunLoop::Device do

  let(:device) { Resources.shared.default_simulator }
  let(:prefs_identifier) { "com.apple.Preferences" }
  let(:aut) { RunLoop::App.new(Resources.shared.app_bundle_path) }
  let(:core_sim) { RunLoop::CoreSimulator.new(device, aut) }

  before do
    allow(RunLoop::Environment).to receive(:debug?).and_return(true)
    RunLoop::CoreSimulator.quit_simulator
    RunLoop::Simctl.new.wait_for_shutdown(device, 30, 0.1)
  end

  context "#simulator_running_app_details" do
    it "detects the -Runner, AUT, and other apps" do
      core_sim.install

      aut_args = ["ARG0", "YES", "ARG1", "NO", "ARG_EXISTS"]

      cbx_launcher = RunLoop::DeviceAgent::IOSDeviceManager.new(device)
      client = RunLoop::DeviceAgent::Client.new(aut.bundle_identifier,
                                                device, cbx_launcher,
                                                {aut_args: aut_args})
      client.launch

      options = { :raise_on_timeout => true, :timeout => 5 }
      RunLoop::ProcessWaiter.new(aut.executable_name, options).wait_for_any

      if RunLoop::Environment.ci?
        sleep(5)
      else
        sleep(1)
      end

      running_apps = device.simulator_running_app_details
      expect(running_apps.count).to be >= 2

      if Resources.shared.xcode.version_gte_90?
        runner_name = "DeviceAgent-Runner"
      else
        runner_name = "XTCRunner"
      end

      expect(running_apps[runner_name]).to be_truthy
      expect(running_apps[runner_name][:args]).not_to be == ""
      expect(running_apps[aut.executable_name]).to be_truthy
      actual = running_apps[aut.executable_name][:args]
      expect(actual).to be == aut_args.join(" ")

      client.launch_other_app("com.apple.Preferences")
      running_apps = device.simulator_running_app_details

      expect(running_apps["Preferences"]).to be_truthy
    end
  end
end
