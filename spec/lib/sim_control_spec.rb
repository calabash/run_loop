require 'tmpdir'

describe RunLoop::SimControl do

  subject(:sim_control) { RunLoop::SimControl.new }

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

    it 'instruments' do
      instruments = sim_control.instruments
      expect(instruments).to be_a RunLoop::Instruments
      expect(sim_control.instance_variable_get(:@instruments)).to be == instruments
    end
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
      ap path
      expect(File.exist?(path)).to be == true
    end
  end

  describe '#existing_sim_support_sdk_dirs' do
    before(:each) {  RunLoop::SimControl.terminate_all_sims }

    it 'returns an Array of properly formatted paths' do
      local_sim_control = RunLoop::SimControl.new
      mocked_dir = Resources.shared.mocked_sim_support_dir
      expect(local_sim_control).to receive(:sim_app_support_dir).and_return(mocked_dir)
      actual = local_sim_control.send(:existing_sim_sdk_or_device_data_dirs)
      expect(actual).to be_a Array
      expect(actual.count).to be == 6

      if local_sim_control.xcode_version_gte_6?
        expect(actual.all? { |elm| elm =~ /^.*\/data$/ }).to be == true
      end

    end
  end

  describe '#enable_accessibility_in_sdk_dir' do
    describe 'raises an error' do
      it 'on Xcode 6' do
        local_sim_control = RunLoop::SimControl.new
        expect(local_sim_control).to receive(:xcode_version_gte_6?).and_return(true)
        expect do
          local_sim_control.send(:enable_accessibility_in_sdk_dir, :any_arg)
        end.to raise_error RuntimeError
      end
    end

    # Xcode 5 only method
    unless RunLoop::XCTools.new.xcode_version_gte_6?
      it "with Xcode #{Resources.shared.current_xcode_version}" do
        sdk_dir = File.expand_path(File.join(Dir.mktmpdir, '7.0.3-64'))
        plist_path = File.expand_path("#{sdk_dir}/Library/Preferences/com.apple.Accessibility.plist")
        expect(sim_control.send(:enable_accessibility_in_sdk_dir, sdk_dir)).to be == true
        expect(File.exist?(plist_path)).to be == true
      end
    end
  end

  describe '#enable_accessibility_in_sim_data_dir' do
    describe 'raises an error' do
      it 'on Xcode < 6' do
        local_sim_control = RunLoop::SimControl.new
        expect(local_sim_control).to receive(:xcode_version_gte_6?).and_return(false)
        expect do
          local_sim_control.send(:enable_accessibility_in_sim_data_dir, nil, nil, nil)
        end.to raise_error RuntimeError
      end
    end

    # Xcode >= 6 only method
    if RunLoop::XCTools.new.xcode_version_gte_6?
      describe "with Xcode #{Resources.shared.current_xcode_version}" do
        local_sim_control = RunLoop::SimControl.new
        sim_details = local_sim_control.send(:sim_details, :udid)
        sdk7_udid = nil
        sdk8_udid = nil
        sim_details.each do |key, value|
          if value[:sdk_version] >= RunLoop::Version.new('8.0')
            sdk8_udid = key
          elsif value[:sdk_version] < RunLoop::Version.new('8.0')
            sdk7_udid = key
          end
          break if sdk8_udid and sdk7_udid
        end

        unless Resources.shared.travis_ci?
          it 'and sdk < 8.0' do
            sdk_dir = File.expand_path(File.join(Dir.mktmpdir, "#{sdk7_udid}/data"))
            plist_path = File.expand_path("#{sdk_dir}/Library/Preferences/com.apple.Accessibility.plist")
            expect(local_sim_control.instance_eval { enable_accessibility_in_sim_data_dir(sdk_dir, sim_details) }).to be == true
            expect(File.exist?(plist_path)).to be == true
          end
        end

        it 'and sdk >= 8.0' do
          sdk_dir = File.expand_path(File.join(Dir.mktmpdir, "#{sdk8_udid}/data"))
          plist_path = File.expand_path("#{sdk_dir}/Library/Preferences/com.apple.Accessibility.plist")
          expect(local_sim_control.send(:enable_accessibility_in_sim_data_dir, sdk_dir, sim_details)).to be == true
          expect(File.exist?(plist_path)).to be == true
        end

        it 'can skip directories not reported by instruments' do
          sdk_dir = "~/Library/Developer/CoreSimulator/Devices/AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
          expect(local_sim_control.send(:enable_accessibility_in_sim_data_dir, sdk_dir, sim_details)).to be == true
        end
      end
    end
  end

  describe '#enable_keyboard_in_sim_data_dir' do
    describe 'raises an error' do
      it 'on Xcode < 6' do
        local_sim_control = RunLoop::SimControl.new
        expect(local_sim_control).to receive(:xcode_version_gte_6?).and_return(false)
        expect do
          local_sim_control.send(:enable_keyboard_in_sim_data_dir, nil, nil, nil)
        end.to raise_error RuntimeError
      end
    end

    if RunLoop::XCTools.new.xcode_version_gte_6?
      describe "with Xcode #{Resources.shared.current_xcode_version}" do
        local_sim_control = RunLoop::SimControl.new
        sim_details = local_sim_control.send(:sim_details, :udid)
        simulator_udid = nil
        sim_details.each do |key, _|
          simulator_udid = key
          break if simulator_udid
        end
        it 'sets the keyboard preferences' do
          sdk_dir = File.expand_path(File.join(Dir.mktmpdir, "#{simulator_udid}/data"))
          plist_path = File.expand_path("#{sdk_dir}/Library/Preferences/com.apple.Preferences.plist")
          expect(local_sim_control.send(:enable_keyboard_in_sim_data_dir, sdk_dir, sim_details)).to be == true
          expect(File.exist?(plist_path)).to be == true
        end

        it 'can skip directories not reported by instruments' do
          sdk_dir = "~/Library/Developer/CoreSimulator/Devices/AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
          expect(local_sim_control.send(:enable_keyboard_in_sim_data_dir, sdk_dir, sim_details)).to be == true
        end
      end
    end
  end

  describe '#sims_details' do
    describe 'raises an error when called' do
      it 'on XCode < 6' do
        local_sim_control = RunLoop::SimControl.new
        expect(local_sim_control).to receive(:xcode_version_gte_6?).and_return(false)
        expect do
          local_sim_control.send(:sim_details, :any_arg)
        end.to raise_error RuntimeError
      end

      if RunLoop::XCTools.new.xcode_version_gte_6?
        it 'is passed an invalid argument' do
          expect do
            sim_control.send(:sim_details, :invalid_arg)
          end.to raise_error ArgumentError
        end
      end
    end
  end

  describe '#simctl_list' do
    describe 'raises an error when called' do
      it 'on Xcode < 6' do
        local_sim_control = RunLoop::SimControl.new
        expect(local_sim_control).to receive(:xcode_version_gte_6?).and_return(false)
        expect do
          local_sim_control.send(:simctl_list, :any_arg)
        end.to raise_error RuntimeError
      end

      if RunLoop::XCTools.new.xcode_version_gte_6?
        it 'with an invalid argument' do
          expect do
            sim_control.send(:simctl_list, :invalid_arg)
          end.to raise_error ArgumentError
        end
      end
    end

    if RunLoop::XCTools.new.xcode_version_gte_6?
      describe 'valid arguments' do
        it ':devices' do
          expect(sim_control.send(:simctl_list, :devices)).to be_a Hash
        end

        it ':runtimes' do
          actual = sim_control.send(:simctl_list, :runtimes)
          expect(actual).to be_a Hash
        end
      end
    end
  end

  describe '#simulators' do
    describe 'raises an error when called' do
      it 'on Xcode < 5.1' do
        local_sim_control = RunLoop::SimControl.new
        expect(local_sim_control).to receive(:xcode_version_gte_51?).and_return(false)
        expect { local_sim_control.simulators }.to raise_error RuntimeError
      end

      if RunLoop::XCTools.new.xcode_version == RunLoop::Version.new('5.1.1')
        it 'on Xcode == 5.1.1 b/c it is not implemented yet' do
          expect { sim_control.simulators }.to raise_error NotImplementedError
        end
      end
    end

    if RunLoop::XCTools.new.xcode_version_gte_6?
      it 'returns a list RunLoop::Device instances' do
        sims = sim_control.simulators
        expect(sims).to be_a Array
        expect(sims.empty?).to be == false
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
