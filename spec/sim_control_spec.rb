require 'tmpdir'

describe RunLoop::SimControl do

  before(:each) { ENV.delete('DEVELOPER_DIR') }

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

  # flickering on Travis CI
  unless Resources.shared.travis_ci?
    describe '#quit_sim and #launch_sim' do
      before(:each) { RunLoop::SimControl.terminate_all_sims }

      it "with Xcode #{Resources.shared.current_xcode_version}" do
        sim_control.launch_sim({:hide_after => false})
        expect(sim_control.sim_is_running?).to be == true

        sim_control.quit_sim
        expect(sim_control.sim_is_running?).to be == false
      end

      xcode_installs = Resources.shared.alt_xcode_install_paths
      unless xcode_installs.empty?
        describe 'regression' do
          xcode_installs.each do |developer_dir|
            it "#{developer_dir}" do
              ENV['DEVELOPER_DIR'] = developer_dir
              local_sim_control = RunLoop::SimControl.new
              local_sim_control.launch_sim({:hide_after => true})
              expect(local_sim_control.sim_is_running?).to be == true

              local_sim_control.quit_sim
              expect(local_sim_control.sim_is_running?).to be == false
            end
          end
        end
      end
    end
  end

  describe '#relaunch_sim' do

    before(:each) { RunLoop::SimControl.terminate_all_sims }

    it "with Xcode #{Resources.shared.current_xcode_version}" do
      sim_control.relaunch_sim({:hide_after => true})
      expect(sim_control.sim_is_running?).to be == true
    end

    xcode_installs = Resources.shared.alt_xcode_install_paths
    unless xcode_installs.empty?
      describe 'regression' do
        xcode_installs.each do |developer_dir|
          it "#{developer_dir}" do
            ENV['DEVELOPER_DIR'] = developer_dir
            local_sim_control = RunLoop::SimControl.new
            local_sim_control.relaunch_sim({:hide_after => true})
            expect(local_sim_control.sim_is_running?).to be == true
          end
        end
      end
    end
  end

  describe '#sim_app_support_dir' do
    before(:each) {  RunLoop::SimControl.terminate_all_sims }
    it "with Xcode #{Resources.shared.current_xcode_version} returns a path that exists" do
      sim_control.relaunch_sim({:hide_after => true})
      path = sim_control.instance_eval { sim_app_support_dir }
      expect(File.exist?(path)).to be == true
    end

    describe 'regression' do
      xcode_installs = Resources.shared.alt_xcode_install_paths
      if xcode_installs.empty?
        it 'not alternative versions of Xcode found' do
          expect(true).to be == true
        end
      else
        xcode_installs.each do |developer_dir|
          it "returns a valid path for #{developer_dir}" do
            RunLoop::SimControl.terminate_all_sims
            ENV['DEVELOPER_DIR'] = developer_dir
            local_sim_control = RunLoop::SimControl.new
            local_sim_control.relaunch_sim({:hide_after => true})
            path = local_sim_control.instance_eval { sim_app_support_dir }
            expect(File.exist?(path)).to be == true
          end
        end
      end
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

  unless Resources.shared.travis_ci?
    describe '#reset_sim_content_and_settings' do

      before(:each) do
        RunLoop::SimControl.terminate_all_sims
        @opts = {:hide_after => true}
      end

      it "with Xcode #{Resources.shared.current_xcode_version}" do
        sim_control.reset_sim_content_and_settings(@opts)
        actual = sim_control.instance_eval { existing_sim_sdk_or_device_data_dirs }
        expect(actual).to be_a Array
        expect(actual.count).to be >= 1
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

    if RunLoop::XCTools.new.xcode_version_gte_6?
      describe 'returns a hash with the primary key' do
        it ':udid' do
          actual = sim_control.instance_eval { sim_details :udid }
          expect(actual).to be_a Hash
          expect(actual.count).to be > 1
        end

        it ':launch_name' do
          actual = sim_control.instance_eval { sim_details :launch_name }
          expect(actual).to be_a Hash
          expect(actual.count).to be > 1
        end
      end
    end
  end

  describe '#enable_accessibility_on_sims' do
    before(:each) {
      RunLoop::SimControl.terminate_all_sims
    }

    it "with Xcode #{Resources.shared.current_xcode_version}" do
      expect(sim_control.enable_accessibility_on_sims).to be == true
    end
  end

  describe '#simctl_reset' do
    before(:each) {
      RunLoop::SimControl.terminate_all_sims
    }

    it 'raises an error if on Xcode < 6' do
      local_sim_control = RunLoop::SimControl.new
      expect(local_sim_control).to receive(:xcode_version_gte_6?).and_return(false)
      expect { local_sim_control.instance_eval { simctl_reset } }.to raise_error RuntimeError
    end

    if RunLoop::XCTools.new.xcode_version_gte_6?
      it 'resets the _all_ simulators when sim_udid is nil' do
        expect( sim_control.instance_eval { simctl_reset }).to be == true
        sim_details = sim_control.instance_eval { sim_details(:udid) }
        sim_details.each_key { |udid|
          containers_dir = Resources.shared.core_simulator_device_containers_dir(udid)
          expect(File.exist? containers_dir).to be == false
        }
      end

      describe 'when sim_udid arg is not nil' do
        it 'raises an error when the sim_udid is invalid' do
          expect { sim_control.instance_eval { simctl_reset('unknown udid') } }.to raise_error RuntimeError
        end
        it 'resets the simulator with corresponding udid' do
          sim_details = sim_control.instance_eval { sim_details(:udid) }
          udid = sim_details.keys.sample
          expect( sim_control.instance_eval { simctl_reset(udid) } ).to be == true
          containers_dir = Resources.shared.core_simulator_device_containers_dir(udid)
          expect(File.exist? containers_dir).to be == false
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
