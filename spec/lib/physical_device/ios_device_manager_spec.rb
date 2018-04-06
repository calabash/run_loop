
describe RunLoop::PhysicalDevice::IOSDeviceManager do

  let(:device) { Resources.shared.device }
  let(:idm) { RunLoop::PhysicalDevice::IOSDeviceManager.new(device) }
  let(:bundle_id) { "com.apple.Preferences" }
  let(:ipa) { RunLoop::Ipa.new(Resources.shared.ipa_path) }
  let(:app) { RunLoop::App.new(Resources.shared.app_bundle_path) }
  let(:shell_options) { {log_cmd: true } }
  let(:executable) { "path/to/iOSDeviceManager" }

  context ".new" do
    it "calls super with device arg and expands the DeviceAgent Frameworks.zip" do
      frameworks = RunLoop::DeviceAgent::Frameworks.instance
      expect(frameworks).to receive(:install).and_return(true)

      manager = RunLoop::PhysicalDevice::IOSDeviceManager.new(device)
      expect(manager.device).to be == device
    end
  end

  context "#raise_error_on_failure" do
    let(:hash) { {out: "< cmd output >", exit_status: 0} }
    it "returns true if exit status is 0" do
      actual = idm.raise_error_on_failure(RuntimeError, "message", app, device,
                                          hash)
      expect(actual).to be_truthy
    end

    it "raises a error if exit status is != 0" do
      hash[:exit_status] = 1
      begin
        idm.raise_error_on_failure(ArgumentError, "error message", app, device,
                                   hash)
      rescue ArgumentError => e
        expect(e.class).to be == ArgumentError
        expect(e.message[/error message/]).to be_truthy
        expect(e.message[/#{app.bundle_identifier}/]).to be_truthy
        expect(e.message[/#{device.udid}/]).to be_truthy
        expect(e.message[/< cmd output >/]).to be_truthy
      end
    end
  end

  context "#app_installed?" do

    let(:hash) { {out: "true", exit_status: 0} }
    before do
      expect(RunLoop::PhysicalDevice::IOSDeviceManager).to(
        receive(:executable_path).and_return(executable)
      )
    end

    it "can check if RunLoop::App is installed" do
      args = [
        executable, "is-installed", app.bundle_identifier, "-d", device.udid
      ]
      expect(idm).to(
        receive(:run_shell_command).with(args, shell_options).and_return(hash)
      )

      expect(idm.app_installed?(app)).to be_truthy
    end

    it "can check if RunLoop::Ipa is installed" do
      args = [
        executable, "is-installed", ipa.bundle_identifier, "-d", device.udid
      ]
      expect(idm).to(
        receive(:run_shell_command).with(args, shell_options).and_return(hash)
      )

      expect(idm.app_installed?(ipa)).to be_truthy
    end

    it "can check if bundle identifier is installed" do
      args = [executable, "is-installed", bundle_id, "-d", device.udid]
      expect(idm).to(
        receive(:run_shell_command).with(args, shell_options).and_return(hash)
      )

      expect(idm.app_installed?(bundle_id)).to be_truthy
    end

    it "returns false if the app is not installed" do
      hash[:exit_status] = RunLoop::PhysicalDevice::IOSDeviceManager::NOT_INSTALLED_EXIT_CODE
      args = [executable, "is-installed", bundle_id, "-d", device.udid]
      expect(idm).to(
        receive(:run_shell_command).with(args, shell_options).and_return(hash)
      )

      expect(idm.app_installed?(bundle_id)).to be_falsey
    end

    it "raises a RuntimeError is the command fails" do
      hash[:out] = "< cmd output >"
      hash[:exit_status] = 1

      args = [executable, "is-installed", bundle_id, "-d", device.udid]
      expect(idm).to(
        receive(:run_shell_command).with(args, shell_options).and_return(hash)
      )

      expect do
        idm.app_installed?(bundle_id)
      end.to raise_error(RuntimeError,
                         /error checking if app is installed on device/)

    end
  end
end
