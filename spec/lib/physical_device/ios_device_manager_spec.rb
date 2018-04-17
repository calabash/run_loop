
describe RunLoop::PhysicalDevice::IOSDeviceManager do

  let(:device) { Resources.shared.device }
  let(:idm) { RunLoop::PhysicalDevice::IOSDeviceManager.new(device) }
  let(:bundle_id) { "com.apple.Preferences" }
  let(:ipa) { RunLoop::Ipa.new(Resources.shared.ipa_path) }
  let(:app) { RunLoop::App.new(Resources.shared.app_bundle_path) }
  let(:shell_options) { {log_cmd: true } }
  let(:install_options) do
    options = shell_options.dup
    options[timeout] =
      RunLoop::PhysicalDevice::IOSDeviceManager::DEFAULT_OPTIONS[:install_timeout]
    options
  end
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

  context "#install_app_internal" do
    let(:install_options) do
      options = shell_options.dup
      options[:timeout] = RunLoop::PhysicalDevice::IOSDeviceManager::DEFAULTS[:install_timeout]
      options
    end

    let(:hash) { {out: "output of install command", exit_status: 0} }

    before do
      expect(RunLoop::PhysicalDevice::IOSDeviceManager).to(
        receive(:executable_path).and_return(executable)
      )
    end

    it "can install a RunLoop::App" do
      args = [executable, "install", app.path, "-d", device.udid]
      expect(idm).to(
        receive(:run_shell_command).with(args, install_options).and_return(hash)
      )

      expect(idm.send(:install_app_internal, app)).to be == hash[:out]
    end

    it "can install a RunLoop::Ipa" do
      args = [executable, "install", ipa.path, "-d", device.udid]
      expect(idm).to(
        receive(:run_shell_command).with(args, install_options).and_return(hash)
      )

      expect(idm.send(:install_app_internal, ipa)).to be == hash[:out]
    end

    it "can add a --codesign-identity if one is defined in the environment" do
      expect(RunLoop::Environment).to receive(:code_sign_identity).and_return("me")
      args = [executable, "install", app.path, "-d", device.udid, "-c", "me"]

      expect(idm).to(
        receive(:run_shell_command).with(args, install_options).and_return(hash)
      )

      expect(idm.send(:install_app_internal, app)).to be == hash[:out]
    end

    it "can add a --provisioning-profile if one is defined in the environment" do
      expect(RunLoop::Environment).to receive(:provisioning_profile).and_return("profile")
      args = [executable, "install", app.path, "-d", device.udid, "-p", "profile"]

      expect(idm).to(
        receive(:run_shell_command).with(args, install_options).and_return(hash)
      )

      expect(idm.send(:install_app_internal, app)).to be == hash[:out]
    end

    it "can add a profile and identity if they are defined in the environment" do
      expect(RunLoop::Environment).to receive(:provisioning_profile).and_return("profile")
      expect(RunLoop::Environment).to receive(:code_sign_identity).and_return("me")
      args = [
        executable, "install", app.path, "-d", device.udid, "-c", "me", "-p", "profile"
      ]

      expect(idm).to(
        receive(:run_shell_command).with(args, install_options).and_return(hash)
      )

      expect(idm.send(:install_app_internal, app)).to be == hash[:out]
    end

    it "can append additional arguments" do
      args = [executable, "install", app.path, "-d", device.udid, "--force"]

      expect(idm).to(
        receive(:run_shell_command).with(args, install_options).and_return(hash)
      )

      expect(idm.send(:install_app_internal, app, ["--force"])).to be == hash[:out]
    end

    it "can raise errors when install fails" do
      hash[:exit_status] = 1
      args = [executable, "install", app.path, "-d", device.udid]

      expect(idm).to(
        receive(:run_shell_command).with(args, install_options).and_return(hash)
      )

      expect do
         idm.send(:install_app_internal, app)
      end.to raise_error(RunLoop::PhysicalDevice::InstallError,
                         /Could not install app on device/)
    end
  end

  context "#install_app" do
    it "calls #install_app_internal with --force flag" do
      app = "path/to/my.app"
      expect(idm).to receive(:install_app_internal).with(app, ["--force"]).and_return(true)

      expect(idm.install_app(app)).to be_truthy
    end
  end

  context "#ensure_newest_installed" do
    it "calls #install_app_internal without the --force flag" do
      app = "path/to/my.app"
      expect(idm).to receive(:install_app_internal).with(app).and_return(true)

      expect(idm.ensure_newest_installed(app)).to be_truthy
    end
  end

  context "#uninstall_app" do
    let(:hash) { {out: "output of uninstall command", exit_status: 0} }

    before do
      allow(RunLoop::PhysicalDevice::IOSDeviceManager).to(
        receive(:executable_path).and_return(executable)
      )
    end

    it "returns :was_not_installed when app is not installed" do
      expect(idm).to(
        receive(:app_installed?).with(app.bundle_identifier).and_return(false)
      )

      expect(idm.uninstall_app(app)).to be == :was_not_installed
    end

    it "returns output of command when app is uninstalled" do
      expect(idm).to(
        receive(:app_installed?).with(app.bundle_identifier).and_return(true)
      )

      args = [executable, "uninstall", app.bundle_identifier, "-d", device.udid]
      expect(idm).to(
        receive(:run_shell_command).with(args, shell_options).and_return(hash)
      )

      expect(idm.uninstall_app(app)).to be == hash[:out]
    end

    it "returns output of command when ipa is uninstalled" do
      expect(idm).to(
        receive(:app_installed?).with(ipa.bundle_identifier).and_return(true)
      )

      args = [executable, "uninstall", ipa.bundle_identifier, "-d", device.udid]
      expect(idm).to(
        receive(:run_shell_command).with(args, shell_options).and_return(hash)
      )

      expect(idm.uninstall_app(ipa)).to be == hash[:out]
    end

    it "raises an error when the uninstall fails" do
      expect(idm).to(
        receive(:app_installed?).with(app.bundle_identifier).and_return(true)
      )

      hash[:exit_status] = 1
      args = [executable, "uninstall", app.bundle_identifier, "-d", device.udid]
      expect(idm).to(
        receive(:run_shell_command).with(args, shell_options).and_return(hash)
      )

      expect do
        idm.uninstall_app(app)
      end.to raise_error(RunLoop::PhysicalDevice::UninstallError,
                         /Could not remove app from device/)
    end
  end

  context "#can_clear_app_data?" do
    it "returns true" do
      expect(idm.can_reset_app_sandbox?).to be_truthy
    end
  end
end
