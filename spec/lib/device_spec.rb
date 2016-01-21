describe RunLoop::Device do

  describe "SIM_STABLE_STATE_OPTIONS" do
    it ":timeout" do
      if RunLoop::Environment.ci?
        expected = 120
      else
        expected = 30
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

  describe '.device_with_identifier' do
    let(:sim_control) { RunLoop::SimControl.new }
    let(:instruments) { RunLoop::Instruments.new }
    let(:xcode) { sim_control.xcode }
    let(:options) do
      {
            :sim_control => sim_control,
            :instruments => instruments
      }
    end

    it 'raises an error if no simulator or device with UDID or name is found' do
      expect(sim_control).to receive(:simulators).and_return([])
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
        expect(sim_control).to receive(:simulators).and_return([])
        expect(instruments).to receive(:physical_devices).and_return([device])

        actual = RunLoop::Device.device_with_identifier(device.name, options)
        expect(actual).to be_a_kind_of RunLoop::Device
      end

      it 'find by udid' do
        expect(sim_control).to receive(:simulators).and_return([])
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

      it 'find by name' do
        expect(sim_control).to receive(:simulators).and_return([device])
        identifier = device.instruments_identifier(xcode)

        actual = RunLoop::Device.device_with_identifier(identifier, options)
        expect(actual).to be_a_kind_of RunLoop::Device
      end

      it 'find by udid' do
        expect(sim_control).to receive(:simulators).and_return([device])
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

  context '#device?' do
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

  describe '#instruments_identifier' do

    subject { device.instruments_identifier(xcode) }

    let(:xcode) { RunLoop::Xcode.new }

    context 'physical device' do
      let(:device) { RunLoop::Device.new('name', '8.1.1', 'e60ef9ae876ab4a218ee966d0525c9fb79e5606d', 'Shutdown') }
      it { is_expected.to be == 'e60ef9ae876ab4a218ee966d0525c9fb79e5606d' }
    end

    describe 'simulator' do
      describe 'Xcode > 7.0' do
        before { expect(xcode).to receive(:version_gte_7?).and_return true }
        context 'with Major.Minor SDK version' do
          let(:device) { RunLoop::Device.new('Form Factor', '8.1.1', '14A15E35-C568-4775-9480-4FC0C2648236', 'Shutdown') }
          it { is_expected.to be == 'Form Factor (8.1)' }
        end

        context 'with Major.Minor.Patch SDK version' do
          let(:device) { RunLoop::Device.new('Form Factor', '7.0.3', '14A15E35-C568-4775-9480-4FC0C2648236', 'Shutdown') }
          it { is_expected.to be == 'Form Factor (7.0.3)' }
        end
      end

      describe '6.0 <= Xcode < 7.0' do
        before do
          expect(xcode).to receive(:version_gte_7?).and_return false
          expect(xcode).to receive(:version_gte_6?).and_return true
        end

        context 'with Major.Minor SDK version' do
          let(:device) { RunLoop::Device.new('Form Factor', '8.1.1', 'not a device udid', 'Shutdown') }
          it { is_expected.to be == 'Form Factor (8.1 Simulator)' }
        end

        context 'with Major.Minor.Patch SDK version' do
          let(:device) { RunLoop::Device.new('Form Factor', '7.0.3', 'not a device udid', 'Shutdown') }
          it { is_expected.to be == 'Form Factor (7.0.3 Simulator)' }
        end
      end

      describe '5.1 <= Xcode < 6' do
        before do
          expect(xcode).to receive(:version_gte_7?).and_return false
          expect(xcode).to receive(:version_gte_6?).and_return false
        end

        let(:device) { RunLoop::Device.new('Form Factor', '7.0.3', 'Xcode 5 Simulator', 'Shutdown') }
        it { is_expected.to be == 'Xcode 5 Simulator' }
      end
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

  describe 'simulator files' do
    let (:physical) {  RunLoop::Device.new('name',
                                           '7.1.2',
                                           '30c4b52a41d0f6c64a44bd01ff2966f03105de1e') }
    let (:simulator) { RunLoop::Device.new('iPhone 5s',
                                           '7.1.2',
                                           '77DA3AC3-EB3E-4B24-B899-4A20E315C318', 'Shutdown') }
    describe '#simulator_root_dir' do
      it 'is nil if physical device' do
        expect(physical.simulator_root_dir).to be_falsey
      end

      it 'is non nil if a simulator' do
        expect(simulator.simulator_root_dir[/#{simulator.udid}/,0]).to be_truthy
      end
    end

    describe '#simulator_accessibility_plist_path' do
      it 'is nil if physical device' do
        expect(physical.simulator_accessibility_plist_path).to be_falsey
      end

      it 'is non nil if a simulator' do
        expect(simulator.simulator_accessibility_plist_path[/#{simulator.udid}/,0]).to be_truthy
        expect(simulator.simulator_accessibility_plist_path[/com.apple.Accessibility.plist/,0]).to be_truthy
      end
    end

    describe '#simulator_preferences_plist_path' do
      it 'is nil if physical device' do
        expect(physical.simulator_preferences_plist_path).to be_falsey
      end

      it 'is non nil if a simulator' do
        expect(simulator.simulator_preferences_plist_path[/#{simulator.udid}/,0]).to be_truthy
        expect(simulator.simulator_preferences_plist_path[/com.apple.Preferences.plist/,0]).to be_truthy
      end
    end

    describe '#simulator_log_file_path' do
      it 'is nil if physical device' do
        expect(physical.simulator_log_file_path).to be_falsey
      end

      it 'is non nil if a simulator' do
        expect(simulator.simulator_log_file_path[/#{simulator.udid}/,0]).to be_truthy
        expect(simulator.simulator_log_file_path[/system.log/,0]).to be_truthy
      end
    end

    describe '#simulator_device_plist' do
      it 'is nil if a physical device' do
        expect(physical.simulator_device_plist).to be_falsey
      end

      it 'is non-nil for simulators' do
        actual = simulator.simulator_device_plist
        expect(actual[/#{simulator.udid}\/device.plist/, 0]).to be_truthy
      end
    end

    describe "#simulator_global_preferences_path" do
      it "is nil if a physical device" do
        expect(physical.simulator_global_preferences_path).to be_falsey
      end

      it "is non-nil for simulators" do
        actual = simulator.simulator_global_preferences_path
        expect(actual[/#{simulator.udid}/,0]).to be_truthy
        expect(actual[/\.GlobalPreferences.plist/, 0]).to be_truthy
      end
    end
  end

  describe "#simulator_languages" do
    let(:device) { RunLoop::Device.new("iPhone 5s", "8.3", "udid") }
    let(:pbuddy) { RunLoop::PlistBuddy.new }
    let(:plist) { "a.plist" }
    let(:out) { "Array {\n    en\n    en-US\n}" }

    before do
      expect(device).to receive(:simulator_global_preferences_path).and_return(plist)
      expect(device).to receive(:pbuddy).and_return(pbuddy)
    end

    it "returns a list of AppleLanguages from global plist" do
      expect(pbuddy).to receive(:plist_read).with("AppleLanguages", plist).and_return(out)

      expect(device.simulator_languages).to be == ["en", "en-US"]
    end

    it "catches errors and returns the string as an array" do
      expect(pbuddy).to receive(:plist_read).with("AppleLanguages", plist).and_return(nil)

      expect(device.simulator_languages).to be == [nil]
    end
  end

  describe "#simulator_set_language" do
    let(:device) { RunLoop::Device.new("iPhone 5s", "8.3", "udid") }

    describe "raises errors" do
      it "this is a physical device" do
        expect(device).to receive(:physical_device?).and_return(true)

        expect do
          device.simulator_set_language("en")
        end.to raise_error RuntimeError, /This method is for Simulators only/
      end

      it "language code is invalid" do
        expect do
          device.simulator_set_language("invalid code")
        end.to raise_error ArgumentError, /is not valid for this device/
      end
    end

    it "sets the language so it is _first_" do
      plist = Resources.shared.global_preferences_plist
      allow(device).to receive(:simulator_global_preferences_path).and_return(plist)

      actual = device.simulator_set_language("en")

      # Travis is running Xcode 6.1 which is not behaving the same as it
      # is locally.  This is passing locally for all Xcodes and on El Cap
      # Xcode 7.2.  Is it a difference in the PlistBuddy implementation?
      if Luffa::Environment.travis_ci?
        expect(actual).to be == ["en-US"]
      else
        expect(actual).to be == ["en", "en-US"]
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

  describe 'updating the device state' do

    before do
      allow(RunLoop::Environment).to receive(:debug?).and_return true
    end

    let(:simulator) do
      RunLoop::Device.new('iPhone 4s',
                          '8.3',
                          'CE5BA25E-9434-475A-8947-ECC3918E64E3')
    end

    describe '#discern_state_from_line' do

      it 'unavailable' do
        line = 'iPhone 5 (AC1509A2-9DE3-4BDD-9820-258BB7D5B41F) (Shutdown) (unavailable, runtime profile not found)'

        expect(simulator.send(:detect_state_from_line, line)).to be == 'Unavailable'
      end

      it 'unknown state' do
        line = 'some line'

        expect(simulator.send(:detect_state_from_line, line)).to be == 'Unknown'
      end

      it 'booted' do
        line = 'iPad Air 2 (43A6049E-AFD6-4D9D-8510-E129FBB3FE0F) (Booted)'

        expect(simulator.send(:detect_state_from_line, line)).to be == 'Booted'
      end

      it 'shutdown' do
        line = 'iPad Air 2 (43A6049E-AFD6-4D9D-8510-E129FBB3FE0F) (Shutdown)'

        expect(simulator.send(:detect_state_from_line, line)).to be == 'Shutdown'
      end
    end

    describe '#fetch_simulator_state' do
      it 'raises an error if the device is not a simulator' do
        expect(simulator).to receive(:physical_device?).and_return true

        expect do
          simulator.send(:fetch_simulator_state)
        end.to raise_error RuntimeError, /This method is available only for simulators/
      end

      it 'raises an error if the udid matches no simulator' do
        xcrun = RunLoop::Xcrun.new
        args = ['simctl', 'list', 'devices']
        expect(xcrun).to receive(:exec).with(args).and_return({:out => ''})
        expect(simulator).to receive(:xcrun).and_return xcrun

        expect do
          simulator.send(:fetch_simulator_state)
        end.to raise_error RuntimeError, /Expected a simulator with udid/
      end

      it 'returns the state of the device' do
        line = 'iPad Air 2 (CE5BA25E-9434-475A-8947-ECC3918E64E3) (Shutdown)'
        hash = {:out => line}
        xcrun = RunLoop::Xcrun.new
        args = ['simctl', 'list', 'devices']
        expect(xcrun).to receive(:exec).with(args).and_return(hash)
        expect(simulator).to receive(:xcrun).and_return xcrun

        expect(simulator.send(:fetch_simulator_state)).to be == 'Shutdown'
      end
    end

    describe '#update_simulator_state' do
      it 'raises error if called on a physical device' do
        expect(simulator).to receive(:physical_device?).and_return true

        expect do
          simulator.update_simulator_state
        end.to raise_error RuntimeError, /This method is available only for simulators/
      end

      it 'sets the simulator state' do
        expect(simulator).to receive(:fetch_simulator_state).and_return 'State'

        expect(simulator.update_simulator_state).to be == 'State'
        expect(simulator.instance_variable_get(:@state)).to be == 'State'
      end
    end
  end
end

