describe RunLoop::Device do

  describe "SIM_STABLE_STATE_OPTIONS" do
    it ":timeout" do
      if RunLoop::Environment.ci?
        expected = 240
      else
        expected = 120
      end

      actual = RunLoop::Device::SIM_STABLE_STATE_OPTIONS[:timeout]
      expect(actual).to be == expected
    end
  end

  context 'creating a new instance' do
    subject!(:version) { RunLoop::Version.new('7.1.2') }
    subject(:device) { RunLoop::Device.new('name', version , 'udid', 'Shutdown') }

    describe '.new' do
      it 'has attr name' do
        expect(device.name).to be == 'name'
      end

      it 'has attr udid' do
        expect(device.udid).to be == 'udid'
      end

      it 'has attr state' do
        expect(device.state).to be == 'Shutdown'
      end

      describe 'version attr' do
        it 'has attr version' do
          expect(device.version).to be == version
        end

        it 'can accept a version str' do
          local_device = RunLoop::Device.new('name', '7.1.2', 'udid', 'Shutdown')
          expect(local_device.version).to be_a RunLoop::Version
          expect(local_device.version).to be == RunLoop::Version.new('7.1.2')
        end
      end
    end

    context "#simctl" do
      it "is a memoized attr reader" do
        simctl = device.send(:simctl)
        expect(device.send(:simctl)).to be == simctl
        expect(device.instance_variable_get(:@simctl)).to be == simctl
        expect(simctl).to be_a_kind_of(RunLoop::Simctl)
      end
    end
  end


  describe '#to_s' do
    it 'physical device' do
      device = RunLoop::Device.new('denis',
                                   '8.3',
                                   '893688959205dc7eb48d603c558ede919ad8dd0c')
      expect { device.to_s }.not_to raise_error
    end

    it 'simulator' do
      device = RunLoop::Device.new('iPhone 4s',
                                   '8.3',
                                   'CE5BA25E-9434-475A-8947-ECC3918E64E3')
      expect { device.to_s }.not_to raise_error
    end
  end

  context "#simulator_instruments_identifier_same_as?" do
    let(:device) { RunLoop::Device.new("iPhone 8",
                                       "11.0.1",
                                       'CE5BA25E-9434-475A-8947-ECC3918E64E3') }

    it "returns true if sim identifier is == arg" do
      actual = device.simulator_instruments_identifier_same_as?("iPhone 8 (11.0.1)")
      expect(actual).to be true
    end

    it "returns true if model number and the major.minor part of id is == arg" do
      actual = device.simulator_instruments_identifier_same_as?("iPhone 8 (11.0)")
      expect(actual).to be true
    end

    it "returns false if model number does not match arg" do
      actual = device.simulator_instruments_identifier_same_as?("iPhone X (11.0.1)")
      expect(actual).to be false
    end

    it "returns false if major part of id does not match arg" do
      actual = device.simulator_instruments_identifier_same_as?("iPhone 8 (12.0.1)")
      expect(actual).to be false
    end

    it "returns false if minor part of id does not match arg" do
      actual = device.simulator_instruments_identifier_same_as?("iPhone 8 (12.1.1)")
      expect(actual).to be false
    end
  end

  describe '.device_with_identifier' do
    let(:simctl) { RunLoop::Simctl.new }
    let(:instruments) { RunLoop::Instruments.new }
    let(:options) do
      {
            :simctl => simctl,
            :instruments => instruments
      }
    end

    it 'raises an error if no simulator or device with UDID or name is found' do
      expect(simctl).to receive(:simulators).and_return([])
      expect(instruments).to receive(:physical_devices).and_return([])

      expect do
        RunLoop::Device.device_with_identifier('a string or udid', options)
      end.to raise_error ArgumentError
    end

    describe 'physical devices' do
      let(:device) { RunLoop::Device.new('denis',
                                         '8.3',
                                         '893688959205dc7eb48d603c558ede919ad8dd0c') }


      it 'find by name' do
        expect(simctl).to receive(:simulators).and_return([])
        expect(instruments).to receive(:physical_devices).and_return([device])

        actual = RunLoop::Device.device_with_identifier(device.name, options)
        expect(actual).to be_a_kind_of RunLoop::Device
      end

      it 'find by udid' do
        expect(simctl).to receive(:simulators).and_return([])
        expect(instruments).to receive(:physical_devices).and_return([device])

        actual = RunLoop::Device.device_with_identifier(device.udid, options)
        expect(actual).to be_a_kind_of RunLoop::Device
      end
    end

    describe 'simulators' do

      let(:device) {
        RunLoop::Device.new('iPhone 4s',
                            '8.3',
                            'CE5BA25E-9434-475A-8947-ECC3918E64E3')
      }
      let(:xcode) { Resources.shared.xcode }

      it 'find by name' do
        expect(simctl).to receive(:simulators).and_return([device])
        identifier = device.instruments_identifier

        actual = RunLoop::Device.device_with_identifier(identifier, options)
        expect(actual).to be_a_kind_of RunLoop::Device
      end

      it 'find by udid' do
        expect(simctl).to receive(:simulators).and_return([device])
        actual = RunLoop::Device.device_with_identifier(device.udid, options)
        expect(actual).to be_a_kind_of RunLoop::Device
      end
    end
  end

  context '#simulator?' do
    subject { device.simulator? }
    context 'is a simulator' do
      let(:device) {  RunLoop::Device.new('name', '7.1.2', '77DA3AC3-EB3E-4B24-B899-4A20E315C318', 'Shutdown') }
      it { is_expected.to be == true }
    end

    context 'is not a simulator' do
      let(:device) { RunLoop::Device.new('name', '7.1.2', '30c4b52a41d0f6c64a44bd01ff2966f03105de1e', 'Shutdown') }
      it { is_expected.to be == false }
    end
  end

  context '#physical_device?' do
    subject { device.physical_device? }
    context 'is a physical device' do
      let(:device) { RunLoop::Device.new('name', '7.1.2', '30c4b52a41d0f6c64a44bd01ff2966f03105de1e', 'Shutdown') }
      it { is_expected.to be == true }
    end

    context 'is not a physical device' do
      let(:device) {  RunLoop::Device.new('name', '7.1.2', '77DA3AC3-EB3E-4B24-B899-4A20E315C318', 'Shutdown') }
      it { is_expected.to be == false }
    end
  end

  context "#compatible_with_xcode_version?" do
    let(:device) do
      RunLoop::Device.new("name", "7.1.2",
                          "77DA3AC3-EB3E-4B24-B899-4A20E315C318",
                          "Shutdown")
    end

    it "returns true if iOS version is compatible with Xcode version" do
      device_version = RunLoop::Version.new("11.2")
      expect(device).to receive(:version).at_least(:once).and_return(device_version)

      xcode_version = RunLoop::Version.new("9.2")
      expect(device.compatible_with_xcode_version?(xcode_version)).to be_truthy

      xcode_version = RunLoop::Version.new("10.0")
      expect(device.compatible_with_xcode_version?(xcode_version)).to be_truthy

      xcode_version = RunLoop::Version.new("12.0")
      expect(device.compatible_with_xcode_version?(xcode_version)).to be_truthy

    end

    it "returns false if simulator iOS version is too low for Xcode version" do
      expect(device).to receive(:physical_device?).at_least(:once).and_return(false)
      device_version = RunLoop::Version.new("7.2")
      expect(device).to receive(:version).at_least(:once).and_return(device_version)

      xcode_version = RunLoop::Version.new("9.0")
      expect(device.compatible_with_xcode_version?(xcode_version)).to be_falsey
    end

    it "returns true if physical device iOS version was ever supported by the Xcode version" do
      # There is no known lower bound for support
      expect(device).to receive(:physical_device?).at_least(:once).and_return(true)
      device_version = RunLoop::Version.new("7.2")
      expect(device).to receive(:version).at_least(:once).and_return(device_version)

      xcode_version = RunLoop::Version.new("9.0")
      expect(device.compatible_with_xcode_version?(xcode_version)).to be_truthy
    end

    it "returns false if iOS version is too high for the Xcode version" do
      device_version = RunLoop::Version.new("11.2")
      expect(device).to receive(:version).at_least(:once).and_return(device_version)

      xcode_version = RunLoop::Version.new("8.0")
      expect(device.compatible_with_xcode_version?(xcode_version)).to be_falsey

      xcode_version = RunLoop::Version.new("9.0")
      expect(device.compatible_with_xcode_version?(xcode_version)).to be_falsey

      xcode_version = RunLoop::Version.new("9.1")
      expect(device.compatible_with_xcode_version?(xcode_version)).to be_falsey
    end

    it "returns false if iOS Simulator version is too low for the Xcode version" do
      device_version = RunLoop::Version.new("7.2")
      expect(device).to receive(:version).at_least(:once).and_return(device_version)

      xcode_version = RunLoop::Version.new("10.0")
      expect(device.compatible_with_xcode_version?(xcode_version)).to be_falsey

      xcode_version = RunLoop::Version.new("9.0")
      expect(device.compatible_with_xcode_version?(xcode_version)).to be_falsey

      xcode_version = RunLoop::Version.new("9.1")
      expect(device.compatible_with_xcode_version?(xcode_version)).to be_falsey

      xcode_version = RunLoop::Version.new("9.2")
      expect(device.compatible_with_xcode_version?(xcode_version)).to be_falsey
    end
  end

  describe '#instruments_identifier' do

    subject { device.instruments_identifier }

    let(:xcode) { RunLoop::Xcode.new }

    context 'physical device' do
      let(:device) { RunLoop::Device.new('name', '8.1.1', 'e60ef9ae876ab4a218ee966d0525c9fb79e5606d', 'Shutdown') }
      it { is_expected.to be == 'e60ef9ae876ab4a218ee966d0525c9fb79e5606d' }
    end

    context 'simulator with major.minor version' do
      let(:device) { RunLoop::Device.new('iPhone X', '10.2', '<udid>', 'Shutdown') }
      it { is_expected.to be == "iPhone X (10.2)" }
    end

    context 'simulator with major.minor.path version' do
      let(:device) { RunLoop::Device.new('iPhone X', '10.2.1', '<udid>', 'Shutdown') }
      it { is_expected.to be == "iPhone X (10.2.1)" }
    end
  end

  describe '#instruction_set' do
    describe 'is a physical device' do
      it 'raises an error' do
        device = RunLoop::Device.new('name', '7.1.2', '30c4b52a41d0f6c64a44bd01ff2966f03105de1e', 'Shutdown')
        expect { device.send(:instruction_set) }.to raise_error(RuntimeError)
      end
    end

    context 'CoreSimulators' do
      let (:device) { RunLoop::Device.new(name, '7.1.2', '77DA3AC3-EB3E-4B24-B899-4A20E315C318', 'Shutdown') }
      subject { device.send(:instruction_set) }
      context 'is an i386 Simulator' do
        ['iPhone 4s', 'iPhone 5', 'iPad 2', 'iPad Retina'].each do |sim_name|
          let(:name) { sim_name }
          it { is_expected.to be == 'i386' }
        end
      end

      context 'is any other simulator' do
        let(:name) { 'iPad Air' }
        it { is_expected.to be == 'x86_64' }
      end
    end
  end

  context "simulator files" do
    let(:physical) do
      RunLoop::Device.new("name", "7.1.2",
                          "30c4b52a41d0f6c64a44bd01ff2966f03105de1e")
    end

    let (:simulator) do
      RunLoop::Device.new("iPhone 5s", "7.1.2",
                          "77DA3AC3-EB3E-4B24-B899-4A20E315C318", "Shutdown")
    end

    context "#simulator_root_dir" do
      it "returns nil when physical device" do
        expect(physical.simulator_root_dir).to be == nil
      end

      it "returns path to Library/Developer/CoreSimulator/<UDID>" do
        expect(simulator.simulator_root_dir[/#{simulator.udid}/]).to be_truthy
      end
    end

    context "#simulator_log_file_path" do
      it "returns nil when physical device" do
        expect(physical.simulator_log_file_path).to be == nil
      end

      it "returns path to Library/Logs/CoreSimulator/<UDID>/system.log" do
        actual = simulator.simulator_log_file_path
        expect(actual[/#{simulator.udid}/]).to be_truthy
        expect(actual[/system.log/]).to be_truthy
      end
    end

    context "simulator plists" do
      let(:root_dir) do
        File.join(Resources.shared.local_tmp_dir, "CoreSimulator", "Devices",
                  simulator.udid)
      end

      before do
        FileUtils.rm_rf(root_dir)
        FileUtils.mkdir_p(root_dir)
      end

      context "#simulator_accessibility_plist_path" do
        it "returns nil when physical device" do
          expect(physical.simulator_accessibility_plist_path).to be == nil
        end

        it "returns path to Accessibility.plist when device is a simulator" do
          expect(simulator).to receive(:simulator_root_dir).and_return(root_dir)

          actual = simulator.simulator_accessibility_plist_path

          expect(actual[/com.apple.Accessibility.plist/]).to be_truthy
        end
      end

      context "#simulator_device_plist" do
        it "returns nil physical device" do
          expect(physical.simulator_device_plist).to be == nil
        end

        it "returns path to device.plist when device is a simulator" do
          expect(simulator).to receive(:simulator_root_dir).and_return(root_dir)

          actual = simulator.simulator_device_plist
          expect(actual[/device.plist/]).to be_truthy
        end
      end

      context "#simulator_global_preferences_path" do
        it "returns nil for physical devices" do
          expect(physical.simulator_global_preferences_path).to be == nil
        end

        it "returns path to the .GlobalPreferences.plist when simulator" do
          expect(simulator).to receive(:simulator_root_dir).and_return(root_dir)

          actual = simulator.simulator_global_preferences_path

          expect(actual[/.GlobalPreferences.plist/]).to be_truthy
        end
      end
    end

    it "#simulator_device_type" do
      plist = "path/to/udid/data/device.plist"
      expect(simulator).to receive(:simulator_device_plist).and_return(plist)
      pbuddy = RunLoop::PlistBuddy.new
      expect(simulator).to receive(:pbuddy).and_return(pbuddy)
      expect(pbuddy).to receive(:plist_read).with("deviceType", plist).and_return(:type)

      actual = simulator.send(:simulator_device_type)
      expect(actual).to be == :type
    end

    describe "#simulator_is_ipad?" do
      let(:ipad) { "com.apple.CoreSimulator.SimDeviceType.iPad-Retina" }
      let(:iphone) { "com.apple.CoreSimulator.SimDeviceType.iPhone-4s" }

      it "false" do
       expect(simulator).to receive(:simulator_device_type).and_return(iphone)

       actual = simulator.send(:simulator_is_ipad?)
       expect(actual).to be_falsey
      end

      it "true" do
       expect(simulator).to receive(:simulator_device_type).and_return(ipad)

       actual = simulator.send(:simulator_is_ipad?)
       expect(actual).to be_truthy
      end
    end
  end

  context "Simulator Language" do
    let(:device) { RunLoop::Device.new("iPhone 5s", "8.3", "udid") }
    let(:root_dir) do
      File.join(Resources.shared.local_tmp_dir, "CoreSimulator", "Devices",
                device.udid)
    end
    let(:pbuddy) { RunLoop::PlistBuddy.new }
    let(:out) { "Array {\n    en\n    en-US\n}" }

    before do
      FileUtils.rm_rf(root_dir)
      FileUtils.mkdir_p(root_dir)
      allow(device).to receive(:simulator_root_dir).and_return(root_dir)
      allow(device).to receive(:pbuddy).and_return(pbuddy)
    end

    context "#simulator_languages" do
      let(:plist) { device.simulator_global_preferences_path }

      it "returns a list of AppleLanguages from global plist" do
        expect(pbuddy).to(
          receive(:plist_read).with("AppleLanguages", plist).and_return(out)
        )

        expect(device.simulator_languages).to be == ["en", "en-US"]
      end

      it "catches errors and returns the string as an array" do
        expect(pbuddy).to(
          receive(:plist_read).with("AppleLanguages", plist).and_return(nil)
        )

        expect(device.simulator_languages).to be == [nil]
      end
    end

    context "#simulator_set_language" do
      it "raises error when this is a physical device" do
        expect(device).to receive(:physical_device?).and_return(true)

        expect do
          device.simulator_set_language("en")
        end.to raise_error RuntimeError, /This method is for Simulators only/
      end

      it "raises error language code is invalid" do
        expect do
          device.simulator_set_language("invalid code")
        end.to raise_error ArgumentError, /is not valid for this device/
      end

      it "raises error when pbuddy#unshift_array fails" do
        expect(pbuddy).to receive(:unshift_array).and_raise(RuntimeError)

        expect do
          device.simulator_set_language("en")
        end.to raise_error RuntimeError, /Could not update the Simulator languages/
      end

      it "sets the language so it is _first_" do
        actual = device.simulator_set_language("de")
        expect(actual).to be == ["de"]

        actual = device.simulator_set_language("en")
        expect(actual).to be == ["en", "de"]
      end
    end
  end

  describe "#simulator_set_locale" do
    describe "raises error" do
      it "is called on a physical device" do
        device = RunLoop::Device.new("denis",
                                     "8.3",
                                     "893688959205dc7eb48d603c558ede919ad8dd0c")
        expect do
          device.simulator_set_locale("en")
        end.to raise_error RuntimeError, /This method is for Simulators only/
      end

      it "the locale code is not valid" do
        device = RunLoop::Device.new("denis","8.3", "udid")

        expect do
          device.simulator_set_locale("xyz")
        end.to raise_error ArgumentError
      end
    end

    it "sets the AppleLocale of the .GlobalPreferences.plist" do
      device = RunLoop::Device.new("denis","8.3", "udid")

      expect(device).to receive(:simulator_global_preferences_path).and_return("a.plist")

      pbuddy = RunLoop::PlistBuddy.new
      expect(device).to receive(:pbuddy).and_return(pbuddy)

      args = ["AppleLocale", "string", "en", "a.plist"]
      expect(pbuddy).to receive(:plist_set).with(*args).and_return true

      locale = device.simulator_set_locale("en")
      expect(locale.code).to be == "en"
      expect(locale.name).to be == "English"
    end
  end

  describe "simulator stable state" do

    let(:simulator) { RunLoop::Device.new("denis", "9.0", "udid") }

    describe "#simulator_data_directory_sha" do
      let(:dir) { "path/to" }
      let(:path) { "path/to/data" }
      let(:options) { {:handle_errors_by => :ignoring} }

      before do
        expect(simulator).to receive(:simulator_root_dir).and_return(dir)
      end
      it "returns a sha" do
        expect(RunLoop::Directory).to receive(:directory_digest).with(path, options).and_return(:sha)

        actual = simulator.send(:simulator_data_directory_sha)
        expect(actual).to be == :sha
      end

      it "returns a random udid" do
        error = RuntimeError.new("sha error")
        expect(RunLoop::Directory).to receive(:directory_digest).with(path, options).and_raise(error)
        expect(SecureRandom).to receive(:uuid).and_return(:random)

        actual = simulator.send(:simulator_data_directory_sha)
        expect(actual).to be == :random
      end
    end

    describe "#simulator_log_file_sha" do
      let(:log) { "path/to/log/file" }

      before do
        expect(simulator).to receive(:simulator_log_file_path).and_return(log)
      end

      it "returns nil if log file does not exist" do
        expect(File).to receive(:exist?).and_return(false)

        actual = simulator.send(:simulator_log_file_sha)
        expect(actual).to be == nil
      end

      describe "log exists" do
        before do
          expect(File).to receive(:exist?).with(log).and_return(true)
        end

        it "return random udid if File.read errors" do
          error = RuntimeError.new("file read error")
          expect(File).to receive(:read).with(log).and_raise(error)
          expect(SecureRandom).to receive(:uuid).and_return(:random)

          actual = simulator.send(:simulator_log_file_sha)
          expect(actual).to be == :random
        end

        it "returns sha" do
          expect(File).to receive(:read).with(log).and_return("sha!")

          actual = simulator.send(:simulator_log_file_sha)
          expect(actual.to_s).to be == "0c3115eb0d6c2d05a964415fada251e49f9bebe3cfa76a9c38d56648783c92d6"
        end
      end
    end
  end

  describe 'updating the device state' do

    before do
      allow(RunLoop::Environment).to receive(:debug?).and_return true
    end

    let(:simulator) do
      RunLoop::Device.new('iPhone 4s',
                          '8.3',
                          'CE5BA25E-9434-475A-8947-ECC3918E64E3')
    end

    describe '#update_simulator_state' do
      it 'raises error if called on a physical device' do
        expect(simulator).to receive(:physical_device?).and_return true

        expect do
          simulator.update_simulator_state
        end.to raise_error RuntimeError, /This method is available only for simulators/
      end

      it 'sets the simulator state' do
        simctl = simulator.send(:simctl)
        expect(simctl).to receive(:simulator_state_as_string).and_return 'State'

        expect(simulator.update_simulator_state).to be == 'State'
        expect(simulator.instance_variable_get(:@state)).to be == 'State'
      end
    end

    describe "sorting out what device to launch" do
      let(:options)  do
        {
          :device => "device",
          :device_target => "device target",
          :udid => "udid"
        }
      end

      let(:xcode) { Resources.shared.xcode }
      let(:simctl) { Resources.shared.simctl }
      let(:instruments) { Resources.shared.instruments }
      let(:args) do
        {
          :simctl => simctl,
          :instruments => instruments
        }
      end

      let(:device) do
        RunLoop::Device.new("denis", "8.3", "893688959205dc7eb48d603c558ede919ad8dd0c")
      end

      let(:simulator) do
        RunLoop::Device.new("iPhone 4s", "8.3", "CE5BA25E-9434-475A-8947-ECC3918E64E3")
      end

      describe ".detect_physical_device_on_usb" do
        let(:udid) { "udid" }
        let(:hash) { {:out => "#{udid}#{$-0}" } }

        it "connected device" do
          expect(CommandRunner).to receive(:run).and_return(hash)

          actual = RunLoop::Device.send(:detect_physical_device_on_usb)
          expect(actual).to be == udid
        end

        it "no connected device" do
          hash[:out] = "#{$-0}"
          expect(CommandRunner).to receive(:run).and_return(hash)

          actual = RunLoop::Device.send(:detect_physical_device_on_usb)
          expect(actual).to be == nil
        end

        it "integration" do
          actual = RunLoop::Device.send(:detect_physical_device_on_usb)
          puts "udidetect => #{actual}"
        end
      end

      describe ".device_from_options" do
        it ":device" do
          actual = RunLoop::Device.send(:device_from_options, options)
          expect(actual).to be == options[:device]
        end

        it ":device_target" do
          options[:device] = nil
          actual = RunLoop::Device.send(:device_from_options, options)
          expect(actual).to be == options[:device_target]
        end

        it ":udid" do
          options[:device] = nil
          options[:device_target] = nil
          actual = RunLoop::Device.send(:device_from_options, options)
          expect(actual).to be == options[:udid]
        end
      end

      it ".device_from_environment" do
        expect(RunLoop::Environment).to receive(:device_target).and_return(:env)

        actual = RunLoop::Device.send(:device_from_environment)
        expect(actual).to be == :env
      end

      describe ".ensure_physical_device_connected" do
        it "device is connected" do

        end

        it "device is not connected" do

        end
      end

      describe ".detect_device" do
        it "options contains a RunLoop::Device" do
          expect(RunLoop::Device).to receive(:device_from_opts_or_env).and_return(simulator)

          actual = RunLoop::Device.detect_device(options, xcode, simctl, instruments)
          expect(actual).to be == simulator
        end

        describe "options or env say 'device'" do
          before do
            allow(RunLoop::Device).to receive(:device_from_opts_or_env).and_return("device")
          end

          it "device is connected" do
            udid = device.udid
            expect(RunLoop::Device).to receive(:detect_physical_device_on_usb).and_return(udid)
            expect(RunLoop::Device).to receive(:device_with_identifier).with(udid, args).and_return(device)

            actual = RunLoop::Device.detect_device(options, xcode, simctl, instruments)
            expect(actual).to be == device
          end

          it "device is not connected" do
            udid = device.udid
            expect(RunLoop::Device).to receive(:detect_physical_device_on_usb).and_return(nil)

            expect do
              RunLoop::Device.detect_device(options, xcode, simctl, instruments)
            end.to raise_error ArgumentError,
                               /Expected a physical device to be connected via USB/
          end
        end

        describe "no info or 'simulator'" do
          before do
            expect(RunLoop::Core).to receive(:default_simulator).and_return(:simulator)
            expect(RunLoop::Device).to receive(:device_with_identifier).with(:simulator, args).and_return(simulator)
          end

          it "nil" do
            expect(RunLoop::Device).to receive(:device_from_opts_or_env).with(options).and_return(nil)

            actual = RunLoop::Device.detect_device(options, xcode, simctl, instruments)
            expect(actual).to be == simulator
          end

          it "empty string" do
            expect(RunLoop::Device).to receive(:device_from_opts_or_env).with(options).and_return("")

            actual = RunLoop::Device.detect_device(options, xcode, simctl, instruments)
            expect(actual).to be == simulator
          end

          it "simulator" do
            expect(RunLoop::Device).to receive(:device_from_opts_or_env).with(options).and_return("simulator")

            actual = RunLoop::Device.detect_device(options, xcode, simctl, instruments)
            expect(actual).to be == simulator
          end
        end

        describe "passed some kind of legit identifier" do
          it "matches a simulator or device" do
            default_sim = RunLoop::Core.default_simulator
            expect(RunLoop::Device).to receive(:device_from_opts_or_env).with(options).and_return(default_sim)

            actual = RunLoop::Device.detect_device(options, xcode, simctl, instruments)
            expect(actual.simulator?).to be_truthy
          end

          it "does match a simulator or device" do
            expect(RunLoop::Device).to receive(:device_from_opts_or_env).with(options).and_return("no matching")

            expect do
              RunLoop::Device.detect_device(options, xcode, simctl, instruments)
            end.to raise_error ArgumentError,
                               /Could not find a device with a UDID or name matching/
          end
        end
      end

      describe ".ensure_physical_device_connected" do
        it "DEVICE_TARGET=device" do
          expect(RunLoop::Device).to receive(:device_from_environment).and_return("device")

          expect do
            RunLoop::Device.send(:ensure_physical_device_connected, nil, options)
          end.to raise_error ArgumentError,  /DEVICE_TARGET=device/
        end

        it "DEVICE_TARGET=< udid >" do
          expect(RunLoop::Device).to receive(:device_from_environment).and_return(device.udid)

          expect do
            RunLoop::Device.send(:ensure_physical_device_connected, nil, options)
          end.to raise_error ArgumentError,
                             /DEVICE_TARGET=#{device.udid} did not match any connected device/
        end

        describe "DEVICE_TARGET= but options imply a physical device" do
          before do
            allow(RunLoop::Device).to receive(:device_from_environment).and_return(nil)
          end

          it ":device" do
            expect do
              RunLoop::Device.send(:ensure_physical_device_connected, nil, options)
            end.to raise_error ArgumentError, /:device => "device"/
          end

          it ":device_target" do
            options[:device] = nil
            expect do
              RunLoop::Device.send(:ensure_physical_device_connected, nil, options)
            end.to raise_error ArgumentError, /:device_target => "device"/
          end

          it ":udid" do
            options[:device] = nil
            options[:device_target] = nil
            expect do
              RunLoop::Device.send(:ensure_physical_device_connected, nil, options)
            end.to raise_error ArgumentError, /:udid => "device"/
          end
        end
      end
    end
  end
end

