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

    end

    it 'when app is already installed and sha1 is different' do

    end

    it 'when the app is not installed' do

    end
  end

  describe '#uninstall' do
    it 'when the app is not installed' do

    end

    it 'when the app is installed' do

    end
  end

  describe '#wait_for_device_state' do
    it 'returns straight away if device is in state' do
      expect(device).to receive(:state).and_return 'Desired'

      expect(core_sim.send(:wait_for_device_state, 'Desired')).to be == true
    end

    it 'times out if state is never reached' do
      options = { :timeout => 0.02, :interval => 0.01 }
      stub_const('RunLoop::LifeCycle::CoreSimulator::WAIT_FOR_DEVICE_STATE_OPTS',
                 options)
      expect(device).to receive(:state).at_least(:once).and_return 'Undesired'
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
      expect(device).to receive(:state).at_least(:once).and_return 'Undesired'
      expect(device).to receive(:update_simulator_state).at_least(:once).and_return(*values)

      expect(core_sim.send(:wait_for_device_state, 'Desired')).to be_truthy
    end
  end
end
