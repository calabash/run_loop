require 'tmpdir'

describe RunLoop::SimControl do

  subject(:sim_control) { RunLoop::SimControl.new }

  describe '.new' do
    it 'has xctools attr' do
      expect(sim_control.xctools).to be_a RunLoop::XCTools
    end

    it 'has plist_buddy attr' do
      expect(sim_control.pbuddy).to be_a RunLoop::PlistBuddy
    end
  end

  describe '#sim_name' do
    it 'for Xcode >= 6.0' do
      xctools = sim_control.xctools
      expect(xctools).to receive(:xcode_version).and_return(xctools.v60)
      expect(sim_control.instance_eval { sim_name }).to be == 'iOS Simulator'
    end

    it 'for Xcode < 6.0' do
      xctools = sim_control.xctools
      expect(xctools).to receive(:xcode_version).and_return(xctools.v51)
      expect(sim_control.instance_eval { sim_name }).to be == 'iPhone Simulator'
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
    it 'for Xcode >= 6.0' do
      xctools = sim_control.xctools
      expect(xctools).to receive(:xcode_developer_dir).and_return('/Xcode')
      expect(xctools).to receive(:xcode_version).and_return(xctools.v60)
      expected = '/Xcode/Applications/iOS Simulator.app'
      expect(sim_control.instance_eval { sim_app_path }).to be == expected
    end

    it 'for Xcode < 6.0' do
      xctools = sim_control.xctools
      expect(xctools).to receive(:xcode_developer_dir).and_return('/Xcode')
      expect(xctools).to receive(:xcode_version).and_return(xctools.v51)
      expected = '/Xcode/Platforms/iPhoneSimulator.platform/Developer/Applications/iPhone Simulator.app'
      expect(sim_control.instance_eval { sim_app_path }).to be == expected
    end

    it 'returns a path that exists' do
      path = sim_control.instance_eval { sim_app_path }
      expect(File.exist?(path)).to be == true
    end
  end

  describe '#existing_sim_support_sdk_dirs' do
    before(:each) {  RunLoop::SimControl.terminate_all_sims }

    it 'returns an Array of properly formatted paths' do
      local_sim_control = RunLoop::SimControl.new
      mocked_dir = Resources.shared.mocked_sim_support_dir
      expect(local_sim_control).to receive(:sim_app_support_dir).and_return(mocked_dir)
      actual = local_sim_control.instance_eval { existing_sim_sdk_or_device_data_dirs }
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
        expect { local_sim_control.instance_eval { enable_accessibility_in_sdk_dir :any_arg } }.to raise_error RuntimeError
      end
    end

    # Xcode 5 only method
    unless RunLoop::XCTools.new.xcode_version_gte_6?
      it "with Xcode #{Resources.shared.current_xcode_version}" do
        sdk_dir = File.expand_path(File.join(Dir.mktmpdir, '7.0.3-64'))
        plist_path = File.expand_path("#{sdk_dir}/Library/Preferences/com.apple.Accessibility.plist")
        expect(sim_control.instance_eval { enable_accessibility_in_sdk_dir(sdk_dir) }).to be == true
        expect(File.exist?(plist_path)).to be == true
      end
    end
  end

  describe '#enable_accessibility_in_sim_data_dir' do
    describe 'raises an error' do
      it 'on Xcode < 6' do
        local_sim_control = RunLoop::SimControl.new
        expect(local_sim_control).to receive(:xcode_version_gte_6?).and_return(false)
        expect { local_sim_control.instance_eval { enable_accessibility_in_sim_data_dir(nil, nil, nil) } }.to raise_error RuntimeError
      end
    end

    # Xcode >= 6 only method
    if RunLoop::XCTools.new.xcode_version_gte_6?
      describe "with Xcode #{Resources.shared.current_xcode_version}" do
        local_sim_control = RunLoop::SimControl.new
        sim_details = local_sim_control.instance_eval { sim_details(:udid) }
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
        it 'and sdk < 8.0' do
          sdk_dir = File.expand_path(File.join(Dir.mktmpdir, "#{sdk7_udid}/data"))
          plist_path = File.expand_path("#{sdk_dir}/Library/Preferences/com.apple.Accessibility.plist")
          expect(local_sim_control.instance_eval { enable_accessibility_in_sim_data_dir(sdk_dir, sim_details) }).to be == true
          expect(File.exist?(plist_path)).to be == true
        end

        it 'and sdk >= 8.0' do
          sdk_dir = File.expand_path(File.join(Dir.mktmpdir, "#{sdk8_udid}/data"))
          plist_path = File.expand_path("#{sdk_dir}/Library/Preferences/com.apple.Accessibility.plist")
          expect(local_sim_control.instance_eval { enable_accessibility_in_sim_data_dir(sdk_dir, sim_details) }).to be == true
          expect(File.exist?(plist_path)).to be == true
        end

        it 'can skip directories not reported by instruments' do
          sdk_dir = "~/Library/Developer/CoreSimulator/Devices/AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
          expect(local_sim_control.instance_eval { enable_accessibility_in_sim_data_dir(sdk_dir, sim_details) }).to be == true
        end
      end
    end
  end

  describe '#enable_keyboard_in_sim_data_dir' do
    describe 'raises an error' do
      it 'on Xcode < 6' do
        local_sim_control = RunLoop::SimControl.new
        expect(local_sim_control).to receive(:xcode_version_gte_6?).and_return(false)
        expect { local_sim_control.instance_eval { enable_keyboard_in_sim_data_dir(nil, nil, nil) } }.to raise_error RuntimeError
      end
    end

    if RunLoop::XCTools.new.xcode_version_gte_6?
      describe "with Xcode #{Resources.shared.current_xcode_version}" do
        local_sim_control = RunLoop::SimControl.new
        sim_details = local_sim_control.instance_eval { sim_details(:udid) }
        simulator_udid = nil
        sim_details.each do |key, value|
          simulator_udid = key
          break if simulator_udid
        end
        it 'sets the keyboard preferences' do
          sdk_dir = File.expand_path(File.join(Dir.mktmpdir, "#{simulator_udid}/data"))
          plist_path = File.expand_path("#{sdk_dir}/Library/Preferences/com.apple.Preferences.plist")
          expect(local_sim_control.instance_eval { enable_keyboard_in_sim_data_dir(sdk_dir, sim_details) }).to be == true
          expect(File.exist?(plist_path)).to be == true
        end

        it 'can skip directories not reported by instruments' do
          sdk_dir = "~/Library/Developer/CoreSimulator/Devices/AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
          expect(local_sim_control.instance_eval { enable_keyboard_in_sim_data_dir(sdk_dir, sim_details) }).to be == true
        end
      end
    end
  end

  describe '#sims_details' do
    describe 'raises an error when called' do
      it 'on XCode < 6' do
        local_sim_control = RunLoop::SimControl.new
        expect(local_sim_control).to receive(:xcode_version_gte_6?).and_return(false)
        expect { local_sim_control.instance_eval { sim_details(:any_arg) } }.to raise_error RuntimeError
      end

      if RunLoop::XCTools.new.xcode_version_gte_6?
        it 'is passed an invalid argument' do
          expect { sim_control.instance_eval { sim_details(:invalid_arg) } }.to raise_error ArgumentError
        end
      end
    end
  end

  describe '#simctl_list' do
    describe 'raises an error when called' do
      it 'on Xcode < 6' do
        local_sim_control = RunLoop::SimControl.new
        expect(local_sim_control).to receive(:xcode_version_gte_6?).and_return(false)
        expect { local_sim_control.instance_eval { simctl_list(:any_arg) } }.to raise_error RuntimeError
      end

      if RunLoop::XCTools.new.xcode_version_gte_6?
        it 'with an invalid argument' do
          expect { sim_control.instance_eval { simctl_list(:invalid_arg) } }.to raise_error ArgumentError
        end
      end
    end

    if RunLoop::XCTools.new.xcode_version_gte_6?
      describe 'valid arguments' do
        it ':devices' do
          expect(sim_control.instance_eval { simctl_list :devices }).to be_a Hash
        end

        it ':runtimes' do
          actual = sim_control.instance_eval { simctl_list :runtimes }
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
end
