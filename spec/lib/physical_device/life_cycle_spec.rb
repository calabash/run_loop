
describe RunLoop::PhysicalDevice::LifeCycle do

  let(:udid) { "e60ef9ae876ab4a218ee966d0525c9fb79e56065" }
  let(:device) { RunLoop::Device.new("planetx", "9.3.1", udid) }

  describe ".new" do
    it "raises error if device is not a physical device" do
      expect(device).to receive(:physical_device?).at_least(:once).and_return(false)

      expect do
        RunLoop::PhysicalDevice::LifeCycle.new(device)
      end.to raise_error ArgumentError, /must be a physical device/
    end

    it "sets the :device attribute" do
      lc = RunLoop::PhysicalDevice::LifeCycle.new(device)

      expect(lc.device).to be == device
      expect(lc.instance_variable_get(:@device)).to be == device
    end

    it "responds to #run_shell_command" do
      lc = RunLoop::PhysicalDevice::LifeCycle.new(device)
      expect(lc.respond_to?(:run_shell_command)).to be_truthy
    end
  end

  describe "abstract class methods" do
    let(:mod) { RunLoop::PhysicalDevice::LifeCycle }

    it ".tool_is_installed?" do
      expect do
        mod.tool_is_installed?
      end.to raise_error RunLoop::Abstract::AbstractMethodError, /tool_is_installed\?/
    end

    it ".executable_path" do
      expect do
        mod.executable_path
      end.to raise_error RunLoop::Abstract::AbstractMethodError, /executable_path/
    end
  end

  describe "abstract instance methods" do

    let(:lc) { RunLoop::PhysicalDevice::LifeCycle.new(device) }

    it "#app_installed?" do
      expect do
        lc.app_installed?("com.example.MyApp")
      end.to raise_error RunLoop::Abstract::AbstractMethodError, /app_installed?/
    end

    it "#install_app" do
      expect do
        lc.install_app("app instance")
      end.to raise_error RunLoop::Abstract::AbstractMethodError, /install_app/
    end

    it "#uninstall_app" do
      expect do
        lc.uninstall_app("app instance")
      end.to raise_error RunLoop::Abstract::AbstractMethodError, /uninstall_app/
    end

    it "#ensure_newest_installed" do
      expect do
        lc.ensure_newest_installed("app instance")
      end.to raise_error RunLoop::Abstract::AbstractMethodError, /ensure_newest_installed/
    end

    it "#installed_app_same_as?" do
      expect do
        lc.installed_app_same_as?("app instance")
      end.to raise_error RunLoop::Abstract::AbstractMethodError, /installed_app_same_as?/
    end

    it "#reset_app_sandbox?" do
      expect do
        lc.reset_app_sandbox("com.example.MyApp")
      end.to raise_error RunLoop::Abstract::AbstractMethodError, /reset_app_sandbox/
    end

    it "#architecture" do
      expect do
        lc.architecture
      end.to raise_error RunLoop::Abstract::AbstractMethodError, /architecture/
    end

    it "#app_has_compatible_architecture?" do
      expect do
        lc.app_has_compatible_architecture?("app instance")
      end.to raise_error RunLoop::Abstract::AbstractMethodError, /app_has_compatible_architecture\?/
    end

    it "#iphone?" do
      expect do
        lc.iphone?
      end.to raise_error RunLoop::Abstract::AbstractMethodError, /iphone\?/
    end

    it "#ipad?" do
      expect do
        lc.ipad?
      end.to raise_error RunLoop::Abstract::AbstractMethodError, /ipad\?/
    end

    it "#model" do
      expect do
        lc.model
      end.to raise_error RunLoop::Abstract::AbstractMethodError, /model/
    end

    it "#sideload" do
      expect do
        lc.sideload({})
      end.to raise_error(RunLoop::PhysicalDevice::NotImplementedError,
                         /The behavior of the sideload method has not been determined/)
    end

    it "#remove_from_sandbox" do
      expect do
        lc.remove_from_sandbox("relative/path")
      end.to raise_error(RunLoop::PhysicalDevice::NotImplementedError,
                         /The behavior of the remove_from_sandbox method has not been determined/)
    end
  end

  describe "concrete methods" do
    let(:lc) { RunLoop::PhysicalDevice::LifeCycle.new(device) }
    let(:app) do
      path = Resources.shared.app_bundle_path
      RunLoop::App.new(path)
    end

    let(:ipa) do
      path = Resources.shared.ipa_path
      RunLoop::Ipa.new(path)
    end

    describe "#expect_app_or_ipa" do
      it "app instance" do
        expect(lc.expect_app_or_ipa(app)).to be_truthy
      end

      it "ipa instance" do
        expect(lc.expect_app_or_ipa(ipa)).to be_truthy
      end

      describe "raises error when" do
        it "receives nil" do
          expect do
            lc.expect_app_or_ipa(nil)
          end.to raise_error ArgumentError, /nil/
        end

        it "receives an empty string" do
          expect do
            lc.expect_app_or_ipa("")
          end.to raise_error ArgumentError, /<empty string>/
        end

        it "receives an other object" do
          expect do
            lc.expect_app_or_ipa({})
          end.to raise_error ArgumentError, /{}/
        end
      end
    end

    it "#is_app?" do
      expect(lc.is_app?(app)).to be_truthy
      expect(lc.is_app?(ipa)).to be_falsey
    end

    it "#is_ipa?" do
      expect(lc.is_ipa?(app)).to be_falsey
      expect(lc.is_ipa?(ipa)).to be_truthy
    end
  end
end
