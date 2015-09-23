
if Resources.shared.current_xcode_version >= RunLoop::Version.new('7.0')

  Luffa.log_warn 'Skipping simctl unit tests on Xcode 7'

elsif !Resources.shared.core_simulator_env?

  Luffa.log_warn 'Skipping simctl unit tests; in non-CoreSimulator environment'

else

  describe RunLoop::Simctl::Bridge do

    let (:abp) { Resources.shared.cal_app_bundle_path }
    let (:sim_control) { RunLoop::SimControl.new }
    let (:device) { Resources.shared.random_simulator_device }

    let(:bridge) { RunLoop::Simctl::Bridge.new(device, abp) }

    describe '.new' do
      it 'populates its attributes' do
        expect(bridge.sim_control).to be_a_kind_of(RunLoop::SimControl)
        expect(bridge.app).to be_a_kind_of(RunLoop::App)
        expect(bridge.device).to be_a_kind_of(RunLoop::Device)
        expect(bridge.pbuddy).to be_a_kind_of(RunLoop::PlistBuddy)
        path_to_sim_bundle = bridge.instance_variable_get(:@path_to_ios_sim_app_bundle)
        expect(Dir.exist?(path_to_sim_bundle)).to be_truthy
      end

      it 'quits the simulator' do
        expect(sim_control.sim_is_running?).to be_falsey
      end

      it 'the device is shutdown' do
        expect(bridge.update_device_state).to be == 'Shutdown'
      end

      it 'raises an error if App cannot be created from app bundle path' do
        allow_any_instance_of(RunLoop::App).to receive(:valid?).and_return(false)
        expect {
          RunLoop::Simctl::Bridge.new(device, abp)
        }.to raise_error(RuntimeError)
      end
    end

    describe '#device_applications_dir' do
      it 'device version < 8.0' do
        expect(bridge.device).to receive(:version).and_return(RunLoop::Version.new('7.1'))
        path = bridge.device_applications_dir
        expect(path[/Bundle/,0]).to be_falsey
      end

      it 'device version >= 8.0' do
        expect(bridge.device).to receive(:version).and_return(RunLoop::Version.new('8.0'))
        path = bridge.device_applications_dir
        expect(path[/Bundle/,0]).to be_truthy
      end
    end

    describe '#update_device_state' do
      it 'raises error when no matching device can be found' do
        expect(bridge).to receive(:fetch_matching_device).and_return(nil)
        expect {
          bridge.update_device_state
        }.to raise_error(RuntimeError)
      end

      it 'returns valid device state' do
        expect(bridge).to receive(:fetch_matching_device).and_return(device)
        expect(device).to receive(:state).at_least(:once).and_return('Anything but nil or empty string')
        expect(bridge.update_device_state).to be == 'Anything but nil or empty string'

        # Unexpected.  Device#state is immutable, so we replace Simctl @device
        # when this method is called.
        expect(bridge.device).to be == device
      end
    end

    describe '#is_sdk_8?' do
      it 'returns true when sdk == 8.0' do
        expect(bridge.device).to receive(:version).and_return(RunLoop::Version.new('8.0'))
        expect(bridge.is_sdk_8?).to be_truthy
      end

      it 'returns true when sdk > 8.0' do
        expect(bridge.device).to receive(:version).and_return(RunLoop::Version.new('8.1'))
        expect(bridge.is_sdk_8?).to be_truthy
      end

      it 'returns false when sdk < 8.0' do
        expect(bridge.device).to receive(:version).and_return(RunLoop::Version.new('7.1'))
        expect(bridge.is_sdk_8?).to be_falsey
      end
    end

    it '#device_data_dir' do
      expect(Dir.exist?(bridge.device_data_dir)).to be_truthy
    end

    describe '#app_data_dir' do
      it 'returns nil if app data dir cannot be found' do
        expect(bridge).to receive(:fetch_app_dir).and_return(nil)
        expect(bridge.app_data_dir).to be == nil
      end

      it 'the data dir and the install dir are the same for sdk < 8.0' do
        expect(bridge.device).to receive(:version).and_return(RunLoop::Version.new('7.1'))
        expect(bridge).to receive(:fetch_app_dir).and_return('/some/path')
        expect(bridge.app_data_dir).to be == '/some/path'
      end

      describe 'sdk >= 8.0' do
        it 'returns a valid path when app is installed' do
          expect(bridge.device).to receive(:version).and_return(RunLoop::Version.new('8.0'))
          expect(bridge).to receive(:fetch_app_dir).and_return('/some/path')
          device_data_dir = Resources.shared.mock_core_simulator_device_data_dir(:sdk8)
          expect(bridge).to receive(:device_data_dir).and_return(device_data_dir)

          match = bridge.app_data_dir

          expect(File.exist?(match)).to be_truthy
          expect(File.directory?(match)).to be_truthy
        end

        it 'returns nil when app is not installed' do
          expect(bridge.device).to receive(:version).and_return(RunLoop::Version.new('8.0'))
          expect(bridge).to receive(:fetch_app_dir).and_return('/some/path')
          device_data_dir = Resources.shared.mock_core_simulator_device_data_dir(:sdk8)
          expect(bridge).to receive(:device_data_dir).and_return(device_data_dir)
          expect(bridge.app).to receive(:bundle_identifier).at_least(:once).and_return('com.example.app')
          expect(bridge.app_data_dir).to be == nil
        end
      end

      describe '#app_library_dir' do
        it 'returns valid file path when app is installed' do
          expect(bridge).to receive(:app_data_dir).and_return('/some/path')
          expect(bridge.app_library_dir.end_with? 'Library').to be_truthy
        end

        it 'returns nil otherwise' do
          expect(bridge).to receive(:app_data_dir).and_return(nil)
          expect(bridge.app_library_dir).to be == nil
        end
      end

      describe '#app_library_preferences_dir' do
        it 'returns valid file path when app is installed' do
          expect(bridge).to receive(:app_library_dir).and_return('/some/path')
          expect(bridge.app_library_preferences_dir.end_with? 'Preferences').to be_truthy
        end

        it 'returns nil otherwise' do
          expect(bridge).to receive(:app_library_dir).and_return(nil)
          expect(bridge.app_library_preferences_dir).to be == nil
        end
      end

      describe '#app_documents_dir' do
        it 'returns valid file path when app is installed' do
          expect(bridge).to receive(:app_data_dir).and_return('/some/path')
          expect(bridge.app_documents_dir.end_with? 'Documents').to be_truthy
        end

        it 'returns nil otherwise' do
          expect(bridge).to receive(:app_data_dir).and_return(nil)
          expect(bridge.app_documents_dir).to be == nil
        end
      end

      describe '#app_tmp_dir' do
        it 'returns valid file path when app is installed' do
          expect(bridge).to receive(:app_data_dir).and_return('/some/path')
          expect(bridge.app_tmp_dir.end_with? 'tmp').to be_truthy
        end

        it 'returns nil otherwise' do
          expect(bridge).to receive(:app_data_dir).and_return(nil)
          expect(bridge.app_tmp_dir).to be == nil
        end
      end

      def create_sandbox_dirs(sub_dir_names)
        base_dir = Dir.mktmpdir

        sub_dir_names.each do |name|
          sub_dir = File.join(base_dir, name)
          FileUtils.mkdir_p(sub_dir)
          FileUtils.touch(File.join(sub_dir, "a-#{name}-file.txt"))
          FileUtils.mkdir_p(File.join(sub_dir, "a-#{name}-dir"))
        end

        base_dir
      end

      describe '#reset_app_sandbox_internal_shared' do
        it 'erases Documents and tmp directories' do
          before = ['Documents', 'tmp']
          base_dir = create_sandbox_dirs(before)
          expect(bridge).to receive(:app_data_dir).at_least(:once).and_return(base_dir)
          bridge.send(:reset_app_sandbox_internal_shared)
          after = Dir.glob("#{base_dir}/**/*").map { |elm| File.basename(elm) }
          expect(after).to be == before
        end
      end

      describe '#reset_app_sandbox_internal_sdk_gte_8' do
        it 'erases all Library files, but preserves Preferences UIA plists' do
          before = ['Caches', 'Cookies', 'WebKit', 'Preferences']
          base_dir = create_sandbox_dirs(before)

          uia_plists = ['com.apple.UIAutomation.plist', 'com.apple.UIAutomationPlugIn.plist']
          uia_plists.each do |plist|
            FileUtils.touch(File.join(base_dir, 'Preferences', plist))
          end

          expect(bridge).to receive(:app_library_dir).at_least(:once).and_return(base_dir)
          bridge.send(:reset_app_sandbox_internal_sdk_gte_8)
          after = Dir.glob("#{base_dir}/**/*").map { |elm| File.basename(elm) }
          expect(after).to be == ['Preferences'] + uia_plists
        end
      end

      describe '#reset_app_sandbox_internal_sdk_lt_8' do
        it 'erases all Library files, preserves protected Preferences plists, but deletes device-app preferences' do
          before = ['lib-prefs-SubDir0', 'lib-prefs-SubDir1']
          base_dir = create_sandbox_dirs(before)

          protected_plists = ['.GlobalPreferences.plist', 'com.apple.PeoplePicker.plist']
          protected_plists.each do |plist|
            FileUtils.touch("#{base_dir}/#{plist}")
          end

          expect(bridge).to receive(:app_library_preferences_dir).at_least(:once).and_return(base_dir)

          device_lib_prefs_dir = Dir.mktmpdir
          bundle_id = 'com.example.Foo'
          lib_prefs_dir_path = File.join(device_lib_prefs_dir, 'Library', 'Preferences')
          FileUtils.mkdir_p(lib_prefs_dir_path)
          plist_path = File.join(lib_prefs_dir_path, "#{bundle_id}.plist")
          FileUtils.touch(plist_path)

          expect(bridge).to receive(:app_data_dir).at_least(:once).and_return(device_lib_prefs_dir)
          expect(bridge.app).to receive(:bundle_identifier).at_least(:once).and_return(bundle_id)

          bridge.send(:reset_app_sandbox_internal_sdk_lt_8)
          after = RunLoop::Directory.recursive_glob_for_entries(base_dir).map { |elm| File.basename(elm) }
          expect(after).to be == protected_plists

          expect(File.exist?(plist_path)).to be_falsey
        end
      end

      describe '#reset_app_sandbox_internal' do
        it 'SDK >= 8.0' do
          expect(bridge.device).to receive(:version).and_return(RunLoop::Version.new('8.0'))
          expect(bridge).to receive(:reset_app_sandbox_internal_shared)
          expect(bridge).to receive(:reset_app_sandbox_internal_sdk_gte_8)
          bridge.send(:reset_app_sandbox_internal)
        end

        it 'SDK < 8.0' do
          expect(bridge.device).to receive(:version).and_return(RunLoop::Version.new('7.1'))
          expect(bridge).to receive(:reset_app_sandbox_internal_shared).and_return nil
          expect(bridge).to receive(:reset_app_sandbox_internal_sdk_lt_8)
          bridge.send(:reset_app_sandbox_internal)
        end
      end
    end
  end
end

