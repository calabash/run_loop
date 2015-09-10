describe RunLoop::LifeCycle::CoreSimulator do

  before do
    allow_any_instance_of(RunLoop::LifeCycle::CoreSimulator).to(
          receive(:terminate_core_simulator_processes).and_return true
    )

    allow(RunLoop::SimControl).to receive(:terminate_all_sims).and_return true
    allow(RunLoop::Environment).to receive(:debug?).and_return true
  end

  it '.new' do
    core_sim = RunLoop::LifeCycle::CoreSimulator.new(:a, :b)

    expect(core_sim.instance_variable_get(:@app)).to be == :a
    expect(core_sim.instance_variable_get(:@device)).to be == :b
    expect(core_sim.instance_variable_get(:@sim_control)).to be_a_kind_of RunLoop::SimControl

    core_sim = RunLoop::LifeCycle::CoreSimulator.new(:a, :b, :c)
    expect(core_sim.instance_variable_get(:@sim_control)).to be == :c
  end

  it '#pbuddy' do
    core_sim = RunLoop::LifeCycle::CoreSimulator.new(:a, :b)

    pbuddy = core_sim.pbuddy
    expect(pbuddy).to be_a_kind_of(RunLoop::PlistBuddy)
    expect(core_sim.pbuddy).to be == pbuddy
    expect(core_sim.instance_variable_get(:@pbuddy)).to be == pbuddy
  end

  let(:app) { RunLoop::App.new(Resources.shared.cal_app_bundle_path) }
  let(:device) { RunLoop::Device.new('iPhone 5s', '8.1',
                                     'A08334BE-77BD-4A2F-BA25-A0E8251A1A80') }
  let(:core_sim) { RunLoop::LifeCycle::CoreSimulator.new(app, device) }

  describe 'Mocked file system' do

    describe '#sdk_gte_8?' do
      it 'returns true' do
        expect(core_sim.sdk_gte_8?).to be_truthy
      end

      it 'returns false' do
        expect(device).to receive(:version).and_return RunLoop::Version.new('7.1')

        expect(core_sim.sdk_gte_8?).to be_falsey
      end
    end

    it '#device_data_dir' do
      base = RunLoop::LifeCycle::CoreSimulator::CORE_SIMULATOR_DEVICE_DIR
      expected = File.join(base, device.udid, 'data')

      actual = core_sim.device_data_dir
      expect(actual).to be == expected
      expect(core_sim.instance_variable_get(:@device_data_dir)).to be == expected
    end

    describe '#device_applications_dir' do
      before do
        expect(core_sim).to receive(:device_data_dir).and_return '/'
      end

      it 'iOS >= 8.0' do
        expected = '/Containers/Bundle/Application'

        expect(core_sim.device_applications_dir).to be == expected
        expect(core_sim.instance_variable_get(:@device_app_dir)).to be == expected
      end

      it 'iOS < 8.0' do
        expect(device).to receive(:version).and_return RunLoop::Version.new('7.1')

        expected = '/Applications'

        expect(core_sim.device_applications_dir).to be == expected
        expect(core_sim.instance_variable_get(:@device_app_dir)).to be == expected
      end
    end

    describe '#app_sandbox_dir' do
      it 'returns nil if there is no app bundle' do
        expect(core_sim).to receive(:installed_app_bundle_dir).and_return nil

        expect(core_sim.app_sandbox_dir).to be == nil
      end

      describe 'app is installed' do
        before do
          expect(core_sim).to receive(:installed_app_bundle_dir).and_return '/'
        end

        it 'iOS >= 8.0' do
          expect(core_sim).to receive(:app_sandbox_dir_sdk_gte_8).and_return 'match'

          expect(core_sim.app_sandbox_dir).to be == 'match'
        end

        it 'iOS < 8.0' do
          expect(device).to receive(:version).and_return RunLoop::Version.new('7.1')

          expect(core_sim.app_sandbox_dir).to be == '/'
        end
      end
    end

    describe '#app_library_dir' do
      it 'returns nil when app is not installed' do
        expect(core_sim).to receive(:app_sandbox_dir).and_return nil

        expect(core_sim.app_library_dir).to be == nil
      end

      it 'returns Library dir when app is installed' do
        expect(core_sim).to receive(:app_sandbox_dir).and_return '/'

        expect(core_sim.app_library_dir).to be == '/Library'
      end
    end

    describe '#app_library_preferences_dir' do
      it 'returns nil when app is not installed' do
        expect(core_sim).to receive(:app_library_dir).and_return nil

        expect(core_sim.app_library_preferences_dir).to be == nil
      end

      it 'returns Library/Preferences dir when app is installed' do
        expect(core_sim).to receive(:app_library_dir).and_return '/'

        expect(core_sim.app_library_preferences_dir).to be == '/Preferences'
      end
    end

    describe '#app_documents_dir' do
      it 'returns nil when app is not installed' do
        expect(core_sim).to receive(:app_sandbox_dir).and_return nil

        expect(core_sim.app_documents_dir).to be == nil
      end

      it 'returns Documents dir when app is installed' do
        expect(core_sim).to receive(:app_sandbox_dir).and_return '/'

        expect(core_sim.app_documents_dir).to be == '/Documents'
      end
    end

    describe '#app_tmp_dir' do
      it 'returns nil when app is not installed' do
        expect(core_sim).to receive(:app_sandbox_dir).and_return nil

        expect(core_sim.app_tmp_dir).to be == nil
      end

      it 'returns tmp dir when app is installed' do
        expect(core_sim).to receive(:app_sandbox_dir).and_return '/'

        expect(core_sim.app_tmp_dir).to be == '/tmp'
      end
    end

    describe '#app_is_installed?' do
      it 'returns false when app is not installed' do
        expect(core_sim).to receive(:installed_app_bundle_dir).and_return nil

        expect(core_sim.app_is_installed?).to be == false
      end

      it 'returns true when app is installed' do
        expect(core_sim).to receive(:installed_app_bundle_dir).and_return '/'

        expect(core_sim.app_is_installed?).to be == true
      end
    end
  end

  describe 'Canned file system' do

    let(:tmp_dir) { Dir.mktmpdir }
    let(:directory) { File.join(tmp_dir, 'CoreSimulator') }

    let(:device_with_app) do
      RunLoop::Device.new('iPhone 5s', '9.0', '69BD76CA-415A-4981-81AC-2CC9EE4FC177')
    end

    let(:device_without_app) do
      RunLoop::Device.new('iPhone 5s', '8.4', '6386C48A-E029-4C1A-932D-355F652F66B9')
    end

    let(:sdk_71_device_with_app) do
      RunLoop::Device.new('iPhone 5s', '7.1', 'B88A172B-CF92-4D3A-8A88-96FF4A6303D3')
    end

    let(:sdk_71_device_without_app) do
      RunLoop::Device.new('iPhone 5', '7.1', '8DE4DF9B-09A4-4CFF-88E1-C62C88DD1503')
    end

    before do
      source = File.join(Resources.shared.resources_dir, 'CoreSimulator')
      FileUtils.cp_r(source, tmp_dir)
      stub_const('RunLoop::LifeCycle::CoreSimulator::CORE_SIMULATOR_DEVICE_DIR',
                 directory)
    end

    describe '#installed_app_bundle_dir' do
      describe 'iOS >= 8' do
        it 'app is installed' do
          core_sim = RunLoop::LifeCycle::CoreSimulator.new(app, device_with_app)

          actual = core_sim.installed_app_bundle_dir
          expect(actual).to be_truthy
          expect(File.exist?(actual)).to be_truthy
        end

        it 'app is not installed' do
          core_sim = RunLoop::LifeCycle::CoreSimulator.new(app, device_without_app)

          actual = core_sim.installed_app_bundle_dir
          expect(actual).to be_falsey
        end
      end

      describe 'iOS < 8' do
        it 'app is installed' do
          core_sim = RunLoop::LifeCycle::CoreSimulator.new(app, sdk_71_device_with_app)

          actual = core_sim.installed_app_bundle_dir
          expect(actual).to be_truthy
          expect(File.exist?(actual)).to be_truthy
        end

        it 'app is not installed' do
          core_sim = RunLoop::LifeCycle::CoreSimulator.new(app, sdk_71_device_without_app)

          actual = core_sim.installed_app_bundle_dir
          expect(actual).to be_falsey
        end
      end
    end

    describe '#app_sandbox_dir' do

      describe 'iOS >= 8' do
        it 'app is installed' do
          core_sim = RunLoop::LifeCycle::CoreSimulator.new(app, device_with_app)

          actual = core_sim.app_sandbox_dir
          expect(actual).to be_truthy
          expect(File.exist?(actual)).to be_truthy
        end

        it 'app is not installed' do
          core_sim = RunLoop::LifeCycle::CoreSimulator.new(app, device_without_app)

          actual = core_sim.app_sandbox_dir
          expect(actual).to be_falsey
        end
      end

      describe 'iOS < 8' do
        it 'app is installed' do
          core_sim = RunLoop::LifeCycle::CoreSimulator.new(app, sdk_71_device_with_app)

          actual = core_sim.app_sandbox_dir
          expect(actual).to be_truthy
          expect(File.exist?(actual)).to be_truthy
        end

        it 'app is not installed' do
          core_sim = RunLoop::LifeCycle::CoreSimulator.new(app, sdk_71_device_without_app)

          actual = core_sim.app_sandbox_dir
          expect(actual).to be_falsey
        end
      end
    end

    describe '#uninstall_app_and_sandbox' do
      it 'iOS >= 8' do
        core_sim = RunLoop::LifeCycle::CoreSimulator.new(app, device_with_app)
        expect(core_sim).to receive(:wait_for_device_state).with('Shutdown').and_return true

        sandbox = core_sim.app_sandbox_dir
        installed_app_dir = core_sim.installed_app_bundle_dir
        container = File.dirname(installed_app_dir)

        expect(File.exist?(sandbox)).to be_truthy
        expect(File.exist?(container)).to be_truthy

        core_sim.send(:uninstall_app_and_sandbox, installed_app_dir)

        expect(File.exist?(sandbox)).to be_falsey
        expect(File.exist?(container)).to be_falsey
        expect(core_sim.app_is_installed?).to be_falsey
      end

      it 'iOS < 8' do
        core_sim = RunLoop::LifeCycle::CoreSimulator.new(app, sdk_71_device_with_app)
        expect(core_sim).to receive(:wait_for_device_state).with('Shutdown').and_return true

        sandbox = core_sim.app_sandbox_dir
        installed_app_dir = core_sim.installed_app_bundle_dir
        container = File.dirname(installed_app_dir)

        expect(File.exist?(sandbox)).to be_truthy
        expect(File.exist?(container)).to be_truthy

        core_sim.send(:uninstall_app_and_sandbox, installed_app_dir)

        expect(File.exist?(sandbox)).to be_falsey
        expect(File.exist?(container)).to be_falsey
        expect(core_sim.app_is_installed?).to be_falsey
      end
    end

    describe '#reinstall_existing_app_and_clear_sandbox' do
      it 'iOS >= 8' do
        core_sim = RunLoop::LifeCycle::CoreSimulator.new(app, device_with_app)
        expect(core_sim).to receive(:wait_for_device_state).with('Shutdown').and_return true

        installed_app_dir = core_sim.installed_app_bundle_dir

        core_sim.send(:reinstall_existing_app_and_clear_sandbox, installed_app_dir)

        expect(File.exist?(core_sim.app_sandbox_dir)).to be_truthy
        expect(core_sim.app_is_installed?).to be_truthy
        expect(app.sha1).to be == core_sim.installed_app_sha1
      end

      it 'iOS < 8' do
        core_sim = RunLoop::LifeCycle::CoreSimulator.new(app, sdk_71_device_with_app)
        expect(core_sim).to receive(:wait_for_device_state).with('Shutdown').and_return true

        installed_app_dir = core_sim.installed_app_bundle_dir

        core_sim.send(:reinstall_existing_app_and_clear_sandbox, installed_app_dir)

        expect(File.exist?(core_sim.app_sandbox_dir)).to be_truthy
        expect(core_sim.app_is_installed?).to be_truthy
        expect(app.sha1).to be == core_sim.installed_app_sha1
      end
    end

    it '#existing_app_container_uuids' do
      core_sim = RunLoop::LifeCycle::CoreSimulator.new(app, device_with_app)
      array = core_sim.send(:existing_app_container_uuids)
      expect(array.include?('478A57E8-1914-4A67-BABC-8D09FDD0F889')).to be_truthy
    end

    it '#generate_unique_udid' do
      core_sim = RunLoop::LifeCycle::CoreSimulator.new(app, device_with_app)
      array = core_sim.send(:existing_app_container_uuids)
      expect do
        core_sim.send(:generate_unique_uuid, array)
      end.not_to raise_error
    end

    describe '#install_new_app' do
      it 'iOS >= 8' do
        app = RunLoop::App.new(Resources.shared.app_bundle_path)
        core_sim = RunLoop::LifeCycle::CoreSimulator.new(app, device_with_app)
        expect(core_sim).to receive(:wait_for_device_state).with('Shutdown').and_return true

        uuid = 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA'
        expect(core_sim).to receive(:generate_unique_uuid).and_return uuid

        actual = core_sim.send(:install_new_app)

        expect(actual[/#{uuid}/, 0]).to be_truthy
        expect(core_sim.app_is_installed?).to be_truthy
        expect(app.sha1).to be == core_sim.installed_app_sha1
      end

      it 'iOS < 8' do
        app = RunLoop::App.new(Resources.shared.app_bundle_path)
        core_sim = RunLoop::LifeCycle::CoreSimulator.new(app, sdk_71_device_with_app)
        expect(core_sim).to receive(:wait_for_device_state).with('Shutdown').and_return true

        uuid = 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA'
        expect(core_sim).to receive(:generate_unique_uuid).and_return uuid

        actual = core_sim.send(:install_new_app)

        expect(actual[/#{uuid}/, 0]).to be_truthy
        expect(core_sim.app_is_installed?).to be_truthy
        expect(app.sha1).to be == core_sim.installed_app_sha1
      end
    end
  end

  describe '#installed_app_sha1' do
    it 'returns nil if app is not installed' do
      expect(core_sim).to receive(:installed_app_bundle_dir).and_return nil

      expect(core_sim.installed_app_sha1).to be == nil
    end

    it 'returns the sha1 of the installed app' do
      path = '/path/to/installed.app'
      expect(core_sim).to receive(:installed_app_bundle_dir).and_return path
      expect(RunLoop::Directory).to receive(:directory_digest).with(path).and_return 'sha1'

      expect(core_sim.installed_app_sha1).to be == 'sha1'
    end
  end

  describe '#same_sha1_as_installed?' do
    it 'returns false if they are different' do
      expect(app).to receive(:sha1).and_return 'a'
      expect(core_sim).to receive(:installed_app_sha1).and_return 'b'

      expect(core_sim.same_sha1_as_installed?).to be_falsey
    end

    it 'returns true if they are the same' do
      expect(app).to receive(:sha1).and_return 'a'
      expect(core_sim).to receive(:installed_app_sha1).and_return 'a'

      expect(core_sim.same_sha1_as_installed?).to be_truthy
    end
  end

  describe '#install' do
    it 'when app is already installed and sha1 is the same' do
      expect(core_sim).to receive(:installed_app_bundle_dir).and_return '/path'
      expect(core_sim).to receive(:same_sha1_as_installed?).and_return true

      expect(core_sim.install).to be == '/path'
    end

    it 'when app is already installed and sha1 is different' do
      expect(core_sim).to receive(:installed_app_bundle_dir).and_return '/path'
      expect(core_sim).to receive(:same_sha1_as_installed?).and_return false
      method_name = :reinstall_existing_app_and_clear_sandbox
      expect(core_sim).to receive(method_name).with('/path').and_return('/new/path')

      expect(core_sim.install).to be == '/new/path'
    end

    it 'when the app is not installed' do
      expect(core_sim).to receive(:installed_app_bundle_dir).and_return nil
      expect(core_sim).to receive(:install_new_app).and_return '/new/path'

      expect(core_sim.install).to be == '/new/path'
    end
  end

  describe '#uninstall' do
    it 'when the app is not installed' do
      expect(core_sim).to receive(:installed_app_bundle_dir).and_return nil

      expect(core_sim.uninstall).to be == :not_installed
    end

    it 'when the app is installed' do
      expect(core_sim).to receive(:installed_app_bundle_dir).and_return '/path'
      expect(core_sim).to receive(:uninstall_app_and_sandbox).with('/path').and_return nil

      expect(core_sim.uninstall).to be == :uninstalled
    end
  end

  describe '#wait_for_device_state' do
    it 'times out if state is never reached' do
      options = { :timeout => 0.02, :interval => 0.01 }
      stub_const('RunLoop::LifeCycle::CoreSimulator::WAIT_FOR_DEVICE_STATE_OPTS',
                 options)
      expect(device).to receive(:update_simulator_state).at_least(:once).and_return 'Undesired'

      expect do
        core_sim.send(:wait_for_device_state, 'Desired')
      end.to raise_error RuntimeError, /Expected/
    end

    it 'waits for a state' do
      options = { :timeout => 0.1, :interval => 0.01 }
      stub_const('RunLoop::LifeCycle::CoreSimulator::WAIT_FOR_DEVICE_STATE_OPTS',
                 options)
      values = ['Undesired', 'Undesired', 'Desired']
      expect(device).to receive(:update_simulator_state).at_least(:once).and_return(*values)

      expect(core_sim.send(:wait_for_device_state, 'Desired')).to be_truthy
    end
  end

  describe 'Clearing the app sandbox' do

    # Helper method.
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

    describe '#reset_app_sandbox' do
      it 'does nothing if app is not installed' do
        expect(core_sim).to receive(:app_is_installed?).and_return false
        expect(core_sim).not_to receive(:reset_app_sandbox_internal)

        expect(core_sim.reset_app_sandbox).to be_truthy
      end

      it 'calls reset_app_sandbox_internal otherwise' do
        expect(core_sim).to receive(:app_is_installed?).and_return true
        expect(core_sim).to receive(:wait_for_device_state).with('Shutdown').and_return true
        expect(core_sim).to receive(:reset_app_sandbox_internal).and_return true

        expect(core_sim.reset_app_sandbox).to be_truthy
      end
    end

    describe '#reset_app_sandbox_internal_shared' do
      it 'erases Documents and tmp directories' do
        before = ['Documents', 'tmp']
        base_dir = create_sandbox_dirs(before)
        expect(core_sim).to receive(:app_sandbox_dir).at_least(:once).and_return(base_dir)

        core_sim.send(:reset_app_sandbox_internal_shared)
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

        expect(core_sim).to receive(:app_library_dir).at_least(:once).and_return(base_dir)

        core_sim.send(:reset_app_sandbox_internal_sdk_gte_8)
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

        expect(core_sim).to receive(:app_library_preferences_dir).at_least(:once).and_return(base_dir)

        device_lib_prefs_dir = Dir.mktmpdir
        bundle_id = 'com.example.Foo'
        lib_prefs_dir_path = File.join(device_lib_prefs_dir, 'Library', 'Preferences')
        FileUtils.mkdir_p(lib_prefs_dir_path)
        plist_path = File.join(lib_prefs_dir_path, "#{bundle_id}.plist")
        FileUtils.touch(plist_path)

        expect(core_sim).to receive(:app_sandbox_dir).at_least(:once).and_return(device_lib_prefs_dir)
        expect(app).to receive(:bundle_identifier).at_least(:once).and_return(bundle_id)

        core_sim.send(:reset_app_sandbox_internal_sdk_lt_8)
        after = RunLoop::Directory.recursive_glob_for_entries(base_dir).map { |elm| File.basename(elm) }

        expect(after).to be == protected_plists
        expect(File.exist?(plist_path)).to be_falsey
      end
    end

    describe '#reset_app_sandbox_internal' do
      it 'SDK >= 8.0' do
        expect(device).to receive(:version).and_return(RunLoop::Version.new('8.0'))
        expect(core_sim).to receive(:reset_app_sandbox_internal_shared)
        expect(core_sim).to receive(:reset_app_sandbox_internal_sdk_gte_8)

        core_sim.send(:reset_app_sandbox_internal)
      end

      it 'SDK < 8.0' do
        expect(device).to receive(:version).and_return(RunLoop::Version.new('7.1'))
        expect(core_sim).to receive(:reset_app_sandbox_internal_shared).and_return nil
        expect(core_sim).to receive(:reset_app_sandbox_internal_sdk_lt_8)

        core_sim.send(:reset_app_sandbox_internal)
      end
    end
  end

  it '#generate_uuid' do
    actual = core_sim.send(:generate_uuid)
    expect(actual[RunLoop::Regex::CORE_SIMULATOR_UDID_REGEX, 0]).to be_truthy
  end

  describe '#generate_unique_udid' do
    it 'keeps trying until unique' do
      existing = [:a, :b, :c]
      generated = existing + [:d]
      expect(core_sim).to receive(:generate_uuid).and_return(*generated)

      actual = core_sim.send(:generate_unique_uuid, existing)
      expect(actual).to be == :d
    end

    it 'times out if a uuid cannot be created' do
      existing = [:a]
      expect(core_sim).to receive(:generate_uuid).at_least(:once).and_return(:a)

      expect do
        core_sim.send(:generate_unique_uuid, existing, 0.02)
      end.to raise_error RuntimeError, /Expected to be able to generate a unique uuid in/
    end
  end
end
