require 'tmpdir'

describe RunLoop::SimControl do

  subject(:sim_control) { RunLoop::SimControl.new }
  let(:xcode) { sim_control.xcode }

  def cached_simulator_details
    if Resources.shared.core_simulator_env?
      @cached_sim_details ||= sim_control.send(:sim_details, :udid)
    end
  end

  def cached_simulators
    if Resources.shared.core_simulator_env?
      @cached_simulators ||= sim_control.simulators
    end
  end

  def cached_ios_lt_80_sim
    if Resources.shared.core_simulator_env?
      cached_simulators.find do |device|
        device.version < RunLoop::Version.new('8.0')
      end
    end
  end

  def cached_ios_gte_80_sim
    if Resources.shared.core_simulator_env?
      cached_simulators.find do |device|
        device.version >= RunLoop::Version.new('8.0')
      end
    end
  end

  describe '.new' do
    it 'plist_buddy' do
      pbuddy = sim_control.pbuddy
      expect(pbuddy).to be_a RunLoop::PlistBuddy
      expect(sim_control.instance_variable_get(:@pbuddy)).to be == pbuddy
    end

    it 'xcode' do
      xcode = sim_control.xcode
      expect(xcode).to be_a RunLoop::Xcode
      expect(sim_control.instance_variable_get(:@xcode)).to be == xcode
    end
  end

  it '#xcrun' do
    xcrun = sim_control.xcrun

    expect(xcrun).to be_a_kind_of(RunLoop::Xcrun)
    expect(sim_control.xcrun).to be == xcrun
    expect(sim_control.instance_variable_get(:@xcrun)).to be == xcrun
  end

  describe '#sim_name' do
    it 'Xcode >= 7.0' do
      expect(sim_control).to receive(:xcode_version_gte_7?).and_return true
      expect(sim_control.send(:sim_name)).to be == 'Simulator'
    end

    it '6.0 <= Xcode < 7.0' do
      expect(sim_control).to receive(:xcode_version_gte_7?).and_return false
      expect(sim_control).to receive(:xcode_version_gte_6?).and_return true
      expect(sim_control.send(:sim_name)).to be == 'iOS Simulator'
    end

    it 'Xcode < 6.0' do
      expect(sim_control).to receive(:xcode_version_gte_7?).and_return false
      expect(sim_control).to receive(:xcode_version_gte_6?).and_return false
      expect(sim_control.send(:sim_name)).to be == 'iPhone Simulator'
    end
  end

  describe '#sim_udid? returns' do
    it 'true when arg is an Xcode >= 6.0 simulator udid' do
      expect(sim_control.sim_udid? '578A16BE-C31F-46E5-836E-66A2E77D89D4').to be == true
    end

    describe 'false when arg is not an Xcode => 6.0 simulator udid' do
      it 'length is not correct' do
        expect(sim_control.sim_udid? 'foo').to be == false
      end

      it 'pattern does not match' do
        expect(sim_control.sim_udid? 'C31F-578A16BE-46E5-836E-66A2E77D89D4').to be == false
      end
    end
  end

  describe '#sim_app_path' do
    describe 'per version' do
      before do
        expect(sim_control).to receive(:xcode_developer_dir).and_return('/Xcode')
      end

      it 'Xcode >= 7.0' do
        expect(sim_control).to receive(:xcode_version_gte_7?).and_return true
        expected = '/Xcode/Applications/Simulator.app'

        expect(sim_control.send(:sim_app_path)).to be == expected
        expect(sim_control.instance_variable_get(:@sim_app_path)).to be == expected
        expect(sim_control.send(:sim_app_path)).to be == expected
      end

      it '6.0 <= Xcode < 7.0' do
        expect(sim_control).to receive(:xcode_version_gte_7?).and_return false
        expect(sim_control).to receive(:xcode_version_gte_6?).and_return true

        expected = '/Xcode/Applications/iOS Simulator.app'
        expect(sim_control.send(:sim_app_path)).to be == expected
        expect(sim_control.instance_variable_get(:@sim_app_path)).to be == expected
        expect(sim_control.send(:sim_app_path)).to be == expected
      end

      it 'Xcode < 6.0' do
        expect(sim_control).to receive(:xcode_version_gte_7?).and_return false
        expect(sim_control).to receive(:xcode_version_gte_6?).and_return false

        expected = '/Xcode/Platforms/iPhoneSimulator.platform/Developer/Applications/iPhone Simulator.app'
        expect(sim_control.send(:sim_app_path)).to be == expected
        expect(sim_control.instance_variable_get(:@sim_app_path)).to be == expected
        expect(sim_control.send(:sim_app_path)).to be == expected
      end
    end

    it 'returns a path that exists' do
      path = sim_control.send(:sim_app_path)
      expect(File.exist?(path)).to be == true
    end
  end

  describe '#existing_sim_support_sdk_dirs' do
    before(:each) {  RunLoop::SimControl.terminate_all_sims }

    it 'returns an Array of properly formatted paths' do
      mocked_dir = Resources.shared.mocked_sim_support_dir
      expect(sim_control).to receive(:sim_app_support_dir).and_return(mocked_dir)

      actual = sim_control.send(:existing_sim_sdk_or_device_data_dirs)
      expect(actual).to be_a Array
      expect(actual.count).to be == 6

      if sim_control.xcode_version_gte_6?
        expect(actual.all? { |elm| elm =~ /^.*\/data$/ }).to be == true
      end
    end
  end

  describe '#enable_accessibility_in_sdk_dir' do
    describe 'raises an error' do
      it 'Xcode >= 6' do
        expect(sim_control).to receive(:xcode_version_gte_6?).and_return(true)

        expect do
          sim_control.send(:enable_accessibility_in_sdk_dir, :any_arg)
        end.to raise_error RuntimeError
      end
    end

    it 'Xcode < 6' do
      expect(xcode).to receive(:version).at_least(:once).and_return xcode.v51
      sdk_dir = File.expand_path(File.join(Dir.mktmpdir, '7.0.3-64'))
      plist_path = File.expand_path("#{sdk_dir}/Library/Preferences/com.apple.Accessibility.plist")

      expect(sim_control.send(:enable_accessibility_in_sdk_dir, sdk_dir)).to be == true
      expect(File.exist?(plist_path)).to be == true
    end
  end

  describe '#enable_accessibility_in_sim_data_dir' do
    it 'Xcode < 6 raises error' do
      expect(sim_control).to receive(:xcode_version_gte_6?).and_return(false)

      expect do
        sim_control.send(:enable_accessibility_in_sim_data_dir, nil, nil, nil)
      end.to raise_error RuntimeError
    end

    describe 'Xcode >= 6.0' do
      let(:sim_details) { cached_simulator_details }

      it 'iOS < 8.0' do
        if !Resources.shared.core_simulator_env?
          Luffa.log_warn 'Skipping test: Xcode < 6.0 detected'
        else
          simulator = cached_ios_lt_80_sim

          if simulator
            udid = simulator.udid
            sdk_dir = File.expand_path(File.join(Dir.mktmpdir, "#{udid}/data"))
            plist_path = File.expand_path("#{sdk_dir}/Library/Preferences/com.apple.Accessibility.plist")

            actual = sim_control.send(:enable_accessibility_in_sim_data_dir, sdk_dir, sim_details)
            expect(actual).to be_truthy
            expect(File.exist?(plist_path)).to be == true
          else
            Luffa.log_warn 'Skipping test: No iOS < 8.0 Simulators installed'
          end
        end
      end

      it 'iOS >= 8.0' do
        if !Resources.shared.core_simulator_env?
          Luffa.log_warn 'Skipping test: Xcode < 6.0 detected'
        else
          simulator = cached_ios_gte_80_sim

          if simulator
            udid = simulator.udid
            sdk_dir = File.expand_path(File.join(Dir.mktmpdir, "#{udid}/data"))
            plist_path = File.expand_path("#{sdk_dir}/Library/Preferences/com.apple.Accessibility.plist")

            actual = sim_control.send(:enable_accessibility_in_sim_data_dir, sdk_dir, sim_details)
            expect(actual).to be_truthy
            expect(File.exist?(plist_path)).to be == true
          else
            Luffa.log_warn 'Skipping test: No iOS >= 8.0 Simulators installed'
          end
        end
      end

      it 'can skip directories not reported by instruments' do
        if !Resources.shared.core_simulator_env?
          Luffa.log_warn 'Skipping test: Xcode < 6.0 detected'
        else
          sdk_dir = "~/Library/Developer/CoreSimulator/Devices/AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"

          actual = sim_control.send(:enable_keyboard_in_sim_data_dir, sdk_dir, sim_details)
          expect(actual).to be_truthy
        end
      end
    end
  end

  describe '#enable_keyboard_in_sim_data_dir' do
    it 'raises error Xcode < 6' do
      expect(sim_control).to receive(:xcode_version_gte_6?).and_return(false)
      expect do
        sim_control.send(:enable_keyboard_in_sim_data_dir, nil, nil, nil)
      end.to raise_error RuntimeError
    end

    describe 'Xcode >= 6.0' do
      let(:sim_details) { cached_simulator_details }

      it 'any iOS version' do
        if !Resources.shared.core_simulator_env?
          Luffa.log_warn 'Skipping test: Xcode < 6.0 detected'
        else
          simulator = cached_ios_gte_80_sim

          if simulator
            udid = simulator.udid
            sdk_dir = File.expand_path(File.join(Dir.mktmpdir, "#{udid}/data"))
            plist_path = File.expand_path("#{sdk_dir}/Library/Preferences/com.apple.Preferences.plist")

            actual = sim_control.send(:enable_keyboard_in_sim_data_dir, sdk_dir, sim_details)
            expect(actual).to be_truthy
            expect(File.exist?(plist_path)).to be == true
          else
            Luffa.log_warn 'Skipping test: No iOS >= 8.0 Simulators installed'
          end
        end
      end

      it 'can skip directories not reported by instruments' do
        if !Resources.shared.core_simulator_env?
          Luffa.log_warn 'Skipping test: Xcode < 6.0 detected'
        else
          sdk_dir = "~/Library/Developer/CoreSimulator/Devices/AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
          expect(sim_control.send(:enable_keyboard_in_sim_data_dir, sdk_dir, sim_details)).to be == true
        end
      end
    end
  end

  describe '#sim_details' do
    describe 'raises an error when' do
      it 'Xcode < 6' do
        expect(sim_control).to receive(:xcode_version_gte_6?).and_return(false)
        expect do
          sim_control.send(:sim_details, :any_arg)
        end.to raise_error RuntimeError
      end

      it 'is passed an invalid argument' do
        expect(sim_control).to receive(:xcode_version_gte_6?).and_return(true)

        expect do
          sim_control.send(:sim_details, :invalid_arg)
        end.to raise_error ArgumentError
      end
    end
  end

  describe '#simctl_list' do
    let(:xcrun) { sim_control.xcrun }

    let(:devices_out) do
      {
            :out => RunLoop::RSpec::Simctl::SIMCTL_DEVICE_XCODE_71
      }
    end

    let(:runtimes_out) do
      {
            :out => RunLoop::RSpec::Simctl::SIMCTL_RUNTIMES_XCODE_71
      }
    end
    describe 'raises an error when' do
      it 'Xcode < 6' do
        expect(sim_control).to receive(:xcode_version_gte_6?).and_return(false)

        expect do
          sim_control.send(:simctl_list, :any_arg)
        end.to raise_error RuntimeError
      end

      it 'invalid argument' do
        expect(sim_control).to receive(:xcode_version_gte_6?).and_return(true)

        expect do
          sim_control.send(:simctl_list, :invalid_arg)
        end.to raise_error ArgumentError
      end
    end

    describe 'valid arguments' do

      before do
       expect(sim_control).to receive(:xcrun).and_return xcrun
      end

      # it ':devices' do
      #   args = ['simctl' 'list', 'devices']
      #   expect(xcrun).to receive(:exec).with(args).and_return(devices_out)
      #
      #   actual = sim_control.send(:simctl_list, :devices)
      #
      #   ap actual
      #
      #   expect(actual).to be_a Hash
      #   expect(actual.length).to be == 12
      #
      # end

      it ':runtimes' do
        args = ['simctl', 'list', 'runtimes']
        expect(xcrun).to receive(:exec).with(args).and_return(runtimes_out)

        actual = sim_control.send(:simctl_list, :runtimes)

        ap actual

        expect(actual).to be_a Hash
        expect(actual.length).to be == 3

        expect(actual[:iOS]).to be_truthy
        expect(actual[:tvOS]).to be_truthy
        expect(actual[:watchOS]).to be_truthy


        expect(actual[:iOS][RunLoop::Version.new('8.1')]).to be_truthy
        expect(actual[:iOS][RunLoop::Version.new('8.2')]).to be_truthy
        expect(actual[:iOS][RunLoop::Version.new('8.3')]).to be_truthy
        expect(actual[:iOS][RunLoop::Version.new('8.4')]).to be_truthy

        v91 = RunLoop::Version.new('9.1')
        expect(actual[:iOS][v91]).to be_truthy

        expect(actual[:iOS][v91][:runtime]).to be == 'com.apple.CoreSimulator.SimRuntime.iOS-9-1'
        expect(actual[:iOS][v91][:name]).to be == 'iOS'
        expect(actual[:iOS][v91][:complete]).to be_truthy
      end
    end
  end

  describe '#simulators' do
    it 'raises an error Xcode < 6' do
      expect(sim_control).to receive(:xcode_version_gte_6?).and_return(false)
      expect { sim_control.simulators }.to raise_error RuntimeError
    end

    it 'returns a list RunLoop::Device instances' do
      if Resources.shared.core_simulator_env?
        sims = sim_control.simulators
        expect(sims).to be_a Array
        expect(sims.empty?).to be == false
      else
        Luffa.log_warn("Skipping test; Xcode < 6 detcted")
      end
    end
  end

  describe 'device based accessibility' do
    let(:device) {
      RunLoop::Device.new('iPhone 5s',
                          '7.1.2',
                          '77DA3AC3-EB3E-4B24-B899-4A20E315C318', 'Shutdown')
    }

    let(:sdk71) { RunLoop::Version.new('7.1') }
    let(:sdk80) { RunLoop::Version.new('8.1') }

    let(:sdk71_enabled) { Resources.shared.access_plist_for_sdk(sdk71, true) }
    let(:sdk71_not_enabled) { Resources.shared.access_plist_for_sdk(sdk71, false) }

    let(:sdk80_enabled) { Resources.shared.access_plist_for_sdk(sdk80, true) }
    let(:sdk80_not_enabled) { Resources.shared.access_plist_for_sdk(sdk80, false) }

    describe '#accessibility_enabled' do
      it 'returns false if plist does not exist' do
        expect(device).to receive(:simulator_accessibility_plist_path).and_return('/path/to/file.plist')
        expect(sim_control.accessibility_enabled?(device)).to be_falsey
      end

      describe 'SDK < 8.0' do
        it 'returns true when accessibility is enabled' do
          expect(device).to receive(:version).and_return sdk71
          expect(device).to receive(:simulator_accessibility_plist_path).and_return(sdk71_enabled)
          expect(sim_control.accessibility_enabled?(device)).to be_truthy
        end

        it 'returns false when accessibility is not enabled' do
          expect(device).to receive(:version).and_return sdk71
          expect(device).to receive(:simulator_accessibility_plist_path).and_return(sdk71_not_enabled)
          expect(sim_control.accessibility_enabled?(device)).to be_falsey
        end
      end

      describe 'SDK >= 8.0' do
        it 'returns true when accessibility is enabled' do
          expect(device).to receive(:version).and_return sdk80
          expect(device).to receive(:simulator_accessibility_plist_path).and_return(sdk80_enabled)
          expect(sim_control.accessibility_enabled?(device)).to be_truthy
        end

        it 'returns false when accessibility is not enabled' do
          expect(device).to receive(:version).and_return sdk80
          expect(device).to receive(:simulator_accessibility_plist_path).and_return(sdk80_not_enabled)
          expect(sim_control.accessibility_enabled?(device)).to be_falsey
        end
      end
    end

    describe '#ensure_accessibility' do
      it 'returns true when accessibility is enabled' do
        expect(sim_control).to receive(:accessibility_enabled?).with(device).and_return(true)
        expect(sim_control.ensure_accessibility(device)).to be_truthy
      end

      it 'returns true if it enabled accessibility' do
        expect(sim_control).to receive(:accessibility_enabled?).with(device).and_return(false)
        expect(sim_control).to receive(:enable_accessibility).with(device).and_return(true)
        expect(sim_control.ensure_accessibility(device)).to be_truthy
      end
    end
  end

  describe 'device based software keyboard enable' do
    let(:device) {
      RunLoop::Device.new('iPhone 5s',
                          '7.1.2',
                          '77DA3AC3-EB3E-4B24-B899-4A20E315C318', 'Shutdown')
    }

    let(:keyboard_enabled) { Resources.shared.plist_with_software_keyboard(true) }
    let(:keyboard_not_enabled) { Resources.shared.plist_with_software_keyboard(false) }

    describe '#keyboard_enabled' do
      it 'returns false if plist does not exist' do
        expect(device).to receive(:simulator_preferences_plist_path).and_return('/path/to/file.plist')
        expect(sim_control.software_keyboard_enabled?(device)).to be_falsey
      end

      it 'returns true when keyboard is enabled' do
        expect(device).to receive(:simulator_preferences_plist_path).and_return(keyboard_enabled)
        expect(sim_control.software_keyboard_enabled?(device)).to be_truthy
      end

      it 'returns false when keyboard is not enabled' do
        expect(device).to receive(:simulator_preferences_plist_path).and_return(keyboard_not_enabled)
        expect(sim_control.software_keyboard_enabled?(device)).to be_falsey
      end
    end

    describe '#ensure_keyboard' do
      it 'returns true when keyboard is enabled' do
        expect(sim_control).to receive(:software_keyboard_enabled?).with(device).and_return(true)
        expect(sim_control.ensure_software_keyboard(device)).to be_truthy
      end

      it 'returns true if it enabled the keyboard' do
        expect(sim_control).to receive(:software_keyboard_enabled?).with(device).and_return(false)
        expect(sim_control).to receive(:enable_software_keyboard).with(device).and_return(true)
        expect(sim_control.ensure_software_keyboard(device)).to be_truthy
      end
    end
  end
end

