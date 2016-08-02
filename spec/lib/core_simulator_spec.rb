describe RunLoop::CoreSimulator do

  before do
    allow(RunLoop::Environment).to receive(:debug?).and_return true
  end

  describe ".simulator_pid" do

    after do
      RunLoop::CoreSimulator.class_variable_set(:@@simulator_pid, nil)
    end

    it "sets the class variable" do
      RunLoop::CoreSimulator.simulator_pid = :foo
      expect(RunLoop::CoreSimulator.class_variable_get(:@@simulator_pid)).to be == :foo
      expect(RunLoop::CoreSimulator.simulator_pid).to be == :foo
    end
  end

  it '.quit_simulator' do
    expect(RunLoop::CoreSimulator).to receive(:term_or_kill).at_least(:once).and_return true

    RunLoop::CoreSimulator.quit_simulator
    expect(RunLoop::CoreSimulator.class_variable_get(:@@simulator_pid)).to be == nil
  end

  it '.terminate_core_simulator_processes' do
    expect(RunLoop::CoreSimulator).to receive(:quit_simulator).and_return true
    expect(RunLoop::CoreSimulator).to receive(:term_or_kill).at_least(:once).and_return true

    RunLoop::CoreSimulator.terminate_core_simulator_processes
  end

  describe ".erase" do
      let(:xcrun) { RunLoop::Xcrun.new }

      let(:options) do
        {
          :xcrun => xcrun,
          :timeout => 100
        }
      end

      let(:device) { RunLoop::Device.new("name", "8.1", "udid") }

      let(:erase_args) do
        [
          ["simctl", "erase", "udid"],
          {
            :log_cmd => true,
            :timeout => 100
          }
        ]
      end

      let(:shutdown_args) do
        [
          ["simctl", "shutdown", "udid"],
          {
            :log_cmd => true,
            :timeout => 100
          }
        ]
      end

      let(:erase_hash) do
        {
          :out => "",
          :exit_status => 0
        }
      end

    before do
      allow(RunLoop::CoreSimulator).to receive(:quit_simulator).and_return true
    end

    it "raises an error if simulator argument is a physical device" do
      # Device#to_s calls physical_device?
      expect(device).to receive(:physical_device?).twice.and_return true

      expect do
        RunLoop::CoreSimulator.erase(device, options)
      end.to raise_error(ArgumentError, /is a physical device/)
    end

    it "calls erase if sim is shutdown" do
      expect(device).to receive(:update_simulator_state).and_return "Shutdown"
      expect(xcrun).to receive(:run_command_in_context).with(*erase_args).and_return(erase_hash)

      expect(RunLoop::CoreSimulator.erase(device, options)).to be_truthy
    end

    it "waits for sim to shutdown" do
      expect(device).to receive(:update_simulator_state).once.and_return("Unknown")
      expect(xcrun).to receive(:run_command_in_context).with(*shutdown_args).and_return true
      expect(RunLoop::CoreSimulator).to receive(:wait_for_simulator_state).and_return true
      expect(xcrun).to receive(:run_command_in_context).with(*erase_args).and_return(erase_hash)

      expect(RunLoop::CoreSimulator.erase(device, options)).to be_truthy
    end

    it "raises error if device cannot be shutdown" do
      expect(device).to receive(:update_simulator_state).once.and_return("Unknown")
      expect(xcrun).to receive(:run_command_in_context).with(*shutdown_args).and_return true
      expect(RunLoop::CoreSimulator).to receive(:wait_for_simulator_state).and_raise RuntimeError, "Not shutdown"

      expect do
        RunLoop::CoreSimulator.erase(device, options)
      end.to raise_error RuntimeError, /Could not erase simulator because it could not be Shutdown/
    end

    it "raises error if device cannot be erased" do
      expect(device).to receive(:update_simulator_state).and_return "Shutdown"
      hash = {:exit_status => 1, :out => "Simulator domain error"}
      expect(xcrun).to receive(:run_command_in_context).with(*erase_args).and_return(hash)

      expect do
        RunLoop::CoreSimulator.erase(device, options)
      end.to raise_error RuntimeError, /Simulator domain error/
    end
  end

  describe ".set_locale" do

    let(:device) { RunLoop::Device.new("denis", "8.3", "udid") }

    before do
      allow(RunLoop::CoreSimulator).to receive(:quit_simulator).and_return(true)
    end

    describe "raises error" do
      it "device arg is RunLoop::Device that is not a simulator" do
        expect(device).to receive(:physical_device?).at_least(:once).and_return(true)

        expect do
          RunLoop::CoreSimulator.set_locale(device, "en")
        end.to raise_error ArgumentError, /The locale cannot be set on physical devices/
      end

      it "device arg is a String that does not match any simulator" do
        expect do
          RunLoop::CoreSimulator.set_locale("no matching sim", "en")
        end.to raise_error ArgumentError
      end

      it "locale_code is not valid for the device" do
        device = RunLoop::Device.new("denis", "8.3", "udid")

        expect do
          RunLoop::CoreSimulator.set_locale(device, "invalid locale code")
        end.to raise_error ArgumentError
      end
    end

    describe "sets the locale" do
      it "when device is a RunLoop::Device" do
        expect(device).to receive(:simulator_set_locale).and_return(true)

        expect(RunLoop::CoreSimulator.set_locale(device, "en")).to be_truthy
      end

      it "when device is a string identifier" do
        expect(RunLoop::Device).to receive(:device_with_identifier).and_return(device)
        expect(device).to receive(:simulator_set_locale).and_return(true)

        expect(RunLoop::CoreSimulator.set_locale("identifier", "en")).to be_truthy
      end
    end
  end

  describe ".set_language" do

    let(:device) { RunLoop::Device.new("denis", "8.3", "udid") }

    before do
      allow(RunLoop::CoreSimulator).to receive(:quit_simulator).and_return(true)
    end

    describe "raises error" do
      it "device arg is RunLoop::Device that is not a simulator" do
        expect(device).to receive(:physical_device?).at_least(:once).and_return(true)

        expect do
          RunLoop::CoreSimulator.set_language(device, "en")
        end.to raise_error ArgumentError, /The language cannot be set on physical devices/
      end

      it "device arg is a String that does not match any simulator" do
        expect do
          RunLoop::CoreSimulator.set_language("no matching sim", "en")
        end.to raise_error ArgumentError
      end

      it "locale_code is not valid for the device" do
        device = RunLoop::Device.new("denis", "8.3", "udid")

        expect do
          RunLoop::CoreSimulator.set_language(device, "invalid locale code")
        end.to raise_error ArgumentError
      end
    end

    describe "sets the language" do
      it "when device is a RunLoop::Device" do
        expect(device).to receive(:simulator_set_language).and_return(true)

        expect(RunLoop::CoreSimulator.set_language(device, "en")).to be_truthy
      end

      it "when device is a string identifier" do
        expect(RunLoop::Device).to receive(:device_with_identifier).and_return(device)
        expect(device).to receive(:simulator_set_language).and_return(true)

        expect(RunLoop::CoreSimulator.set_language("identifier", "en")).to be_truthy
      end
    end
  end

  describe 'instance methods' do
    before do
      allow(RunLoop::CoreSimulator).to receive(:terminate_core_simulator_processes).and_return true
      allow(RunLoop::CoreSimulator).to receive(:term_or_kill).and_return true
      allow_any_instance_of(RunLoop::CoreSimulator).to receive(:rm_instruments_pipe).and_return true
    end

    describe '.new' do

      it 'sets instance variable from arguments' do
        core_sim = RunLoop::CoreSimulator.new(:a, :b)

        expect(core_sim.instance_variable_get(:@device)).to be == :a
        expect(core_sim.instance_variable_get(:@app)).to be == :b
      end

      describe 'respects options' do
        let(:options) { { } }

        describe ':xcode' do
          it 'uses when available' do
            options[:xcode] = :xcode
            core_sim = RunLoop::CoreSimulator.new(:a, :b, options)

            expect(core_sim.instance_variable_get(:@xcode)).to be == :xcode
          end

          it 'ignores if not' do
            core_sim = RunLoop::CoreSimulator.new(:a, :b, options)

            expect(core_sim.instance_variable_get(:@xcode)).to be == nil
          end
        end

        describe ':quit_on_init' do
          it 'does not quit the simulator' do
            options[:quit_sim_on_init] = false
            expect(RunLoop::CoreSimulator).not_to receive(:quit_simulator)

            RunLoop::CoreSimulator.new(:a, :b, options)
          end

          it 'does quit the simulator' do
            expect(RunLoop::CoreSimulator).to receive(:quit_simulator).and_return true

            RunLoop::CoreSimulator.new(:a, :b, options)
          end
        end
      end
    end

    describe 'attrs' do
      let(:core_sim) { RunLoop::CoreSimulator.new(:a, :b) }

      it '#pbuddy' do
        pbuddy = core_sim.pbuddy
        expect(pbuddy).to be_a_kind_of(RunLoop::PlistBuddy)
        expect(core_sim.pbuddy).to be == pbuddy
        expect(core_sim.instance_variable_get(:@pbuddy)).to be == pbuddy
      end

      it '#xcode' do
        xcode = core_sim.xcode
        expect(xcode).to be_a_kind_of(RunLoop::Xcode)
        expect(core_sim.xcode).to be == xcode
        expect(core_sim.instance_variable_get(:@xcode)).to be == xcode
      end

      it '#xcrun' do
        xcrun = core_sim.xcrun
        expect(xcrun).to be_a_kind_of(RunLoop::Xcrun)
        expect(core_sim.xcrun).to be == xcrun
        expect(core_sim.instance_variable_get(:@xcrun)).to be == xcrun
      end
    end

    let(:app) { RunLoop::App.new(Resources.shared.cal_app_bundle_path) }
    let(:device) { RunLoop::Device.new('iPhone 5s', '8.1',
                                       'A08334BE-77BD-4A2F-BA25-A0E8251A1A80') }
    let(:core_sim) { RunLoop::CoreSimulator.new(device, app) }
    let(:simctl) { RunLoop::Simctl.new }
    let(:xcode) { RunLoop::Xcode.new }

    describe '#uninstall_app_and_sandbox' do
      it 'does nothing if the app is not installed' do
        expect(core_sim).to receive(:app_is_installed?).and_return false

        expect(core_sim.uninstall_app_and_sandbox).to be_truthy
      end

      it 'launches the simulator and installs the app with simctl' do
        expect(core_sim).to receive(:app_is_installed?).and_return true
        expect(core_sim).to receive(:launch_simulator).and_return true
        args = ["simctl", 'uninstall', device.udid, app.bundle_identifier]

        timeout = RunLoop::CoreSimulator::DEFAULT_OPTIONS[:uninstall_app_timeout]
        options = { log_cmd: true, timeout: timeout }
        expect(core_sim.xcrun).to receive(:run_command_in_context).with(args, options).and_return true

        expect(core_sim.device).to receive(:simulator_wait_for_stable_state).and_return true

        expect(core_sim.uninstall_app_and_sandbox).to be_truthy
      end
    end

    describe "#running_simulator_pid" do
      let(:hash) do
        {
          :exit_status => 0,
          :out => "something, anything"
        }
      end

      it "xcrun exit status is non-zero" do
        hash[:exit_status] = 1
        expect(core_sim).to receive(:run_shell_command).and_return hash

        expect do
          core_sim.send(:running_simulator_pid)
        end.to raise_error RuntimeError, /Command exited with status/
      end

      describe "xcrun returns no :out" do
        it "out is nil" do
          hash[:out] = nil
          expect(core_sim).to receive(:run_shell_command).and_return hash

          expect do
            core_sim.send(:running_simulator_pid)
          end.to raise_error RuntimeError, /Command had no output/
        end

        it "out is empty string" do
          hash[:out] = ""
          expect(core_sim).to receive(:run_shell_command).and_return hash

          expect do
            core_sim.send(:running_simulator_pid)
          end.to raise_error RuntimeError, /Command had no output/
        end
      end

      it "no matching process is found" do
        hash[:out] =
          %Q{
27247 login -pf moody
46238 tmate
31098 less run_loop.out
32976 vim lib/run_loop/xcrun.rb
7656 /bin/ps x -o pid,command
}
        expect(core_sim).to receive(:run_shell_command).and_return hash

        expect(core_sim.send(:running_simulator_pid)).to be == nil
      end

      it "returns integer pid" do
        hash[:out] =
%Q{
27247 login -pf moody
46238 tmate
31098 less run_loop.out
32976 MacOS/Simulator
7656 /MacOS/SillySim
}
        expect(core_sim).to receive(:sim_name).and_return("SillySim")
        expect(core_sim).to receive(:run_shell_command).and_return hash

        expect(core_sim.send(:running_simulator_pid)).to be == 7656
      end
    end

    describe 'Mocked file system' do

      describe '#sdk_gte_8?' do
        it 'returns true' do
          expect(core_sim.send(:sdk_gte_8?)).to be_truthy
        end

        it 'returns false' do
          expect(device).to receive(:version).and_return RunLoop::Version.new('7.1')

          expect(core_sim.send(:sdk_gte_8?)).to be_falsey
        end
      end

      it '#device_data_dir' do
        base = RunLoop::CoreSimulator::CORE_SIMULATOR_DEVICE_DIR
        expected = File.join(base, device.udid, 'data')

        actual = core_sim.send(:device_data_dir)
        expect(actual).to be == expected
        expect(core_sim.instance_variable_get(:@device_data_dir)).to be == expected
      end

      describe '#device_applications_dir' do
        before do
          expect(core_sim).to receive(:device_data_dir).and_return '/'
        end

        it 'iOS >= 8.0' do
          expected = '/Containers/Bundle/Application'

          expect(core_sim.send(:device_applications_dir)).to be == expected
          expect(core_sim.instance_variable_get(:@device_app_dir)).to be == expected
        end

        it 'iOS < 8.0' do
          expect(device).to receive(:version).and_return RunLoop::Version.new('7.1')

          expected = '/Applications'

          expect(core_sim.send(:device_applications_dir)).to be == expected
          expect(core_sim.instance_variable_get(:@device_app_dir)).to be == expected
        end
      end

      describe "#complete_app_install" do
        let(:tmp) { Resources.shared.local_tmp_dir }
        let(:working_dir) { File.join(tmp, "complete-app-install") }
        let(:app_bundle) { File.join(working_dir, "My.app") }
        let(:plist) { File.join(working_dir,  RunLoop::CoreSimulator::METADATA_PLIST) }

        before do
          [working_dir, app_bundle].each do |path|
            FileUtils.rm_rf(path)
            FileUtils.mkdir_p(path)
          end

          FileUtils.touch(plist)
        end

        it "true" do
          expect(core_sim.send(:complete_app_install?, app_bundle)).to be_truthy
        end

        it "false" do
          FileUtils.rm_rf(plist)
          expect(core_sim.send(:complete_app_install?, app_bundle)).to be_falsey
        end
      end

      describe "#ensure_complete_app_installation" do
        let(:tmp) { Resources.shared.local_tmp_dir }
        let(:working_dir) { File.join(tmp, "ensure-complete-app-install") }
        let(:app_bundle) { File.join(working_dir, "My.app") }
        let(:plist) { File.join(working_dir,  RunLoop::CoreSimulator::METADATA_PLIST) }

        before do
          [working_dir, app_bundle].each do |path|
            FileUtils.rm_rf(path)
            FileUtils.mkdir_p(path)
          end

          FileUtils.touch(plist)
        end

        it "bundle is nil" do
          actual = core_sim.send(:ensure_complete_app_installation, nil)
          expect(actual).to be == nil
        end

        it "complete" do
          expect(core_sim).to receive(:complete_app_install?).with(app_bundle).and_return(true)

          actual = core_sim.send(:ensure_complete_app_installation, app_bundle)
          expect(actual).to be == app_bundle
        end

        it "incomplete" do
          expect(core_sim).to receive(:complete_app_install?).with(app_bundle).and_return(false)
          expect(core_sim).to receive(:remove_stale_data_containers).and_return(true)

          actual = core_sim.send(:ensure_complete_app_installation, app_bundle)
          expect(actual).to be == nil
          expect(File.exist?(working_dir)).to be_falsey
        end
      end

      describe "#remove_stale_data_containers" do
        let(:tmp) { Resources.shared.local_tmp_dir }
        let(:working_dir) { File.join(tmp, "remove-stale-data-containers") }
        let(:container_a) { File.join(working_dir, "Containers", "Data", "Application", "A") }
        let(:plist_a) { File.join(container_a,  RunLoop::CoreSimulator::METADATA_PLIST) }
        let(:container_b) { File.join(working_dir, "Containers", "Data", "Application", "B") }
        let(:plist_b) { File.join(container_b,  RunLoop::CoreSimulator::METADATA_PLIST) }
        let(:container_c) { File.join(working_dir, "Containers", "Data", "Application", "C") }
        let(:plist_c) { File.join(container_c,  RunLoop::CoreSimulator::METADATA_PLIST) }
        let(:pbuddy) { RunLoop::PlistBuddy.new }
        let(:bundle_id) { "com.example.MyApp" }

        before do
          [working_dir, container_a, container_b, container_c].each do |path|
            FileUtils.rm_rf(path)
            FileUtils.mkdir_p(path)
          end

          [plist_a, plist_b, plist_c].each do |path|
            FileUtils.touch(path)
          end

          allow(core_sim).to receive(:pbuddy).and_return(pbuddy)
          allow(core_sim.app).to receive(:bundle_identifier).and_return(bundle_id)
          allow(core_sim).to receive(:device_data_dir).and_return(working_dir)
          expect(pbuddy).to receive(:plist_read).with("MCMMetadataIdentifier", plist_a).and_return(bundle_id)
          expect(pbuddy).to receive(:plist_read).with("MCMMetadataIdentifier", plist_b).and_return("com.does.not.match")
          expect(pbuddy).to receive(:plist_read).with("MCMMetadataIdentifier", plist_c).and_return(bundle_id)
        end

        it "clears matching data containers" do
          core_sim.send(:remove_stale_data_containers)
          expect(File.exist?(container_a)).to be_falsey
          expect(File.exist?(container_b)).to be_truthy
          expect(File.exist?(container_c)).to be_falsey
        end
      end

      describe "#installed_app_bundle_dir" do
        let(:app_dir) do
          path = File.join(Resources.shared.local_tmp_dir, "Containers/Bundle/Application")
          FileUtils.mkdir_p(path)
          path
        end

        before do
          expect(core_sim).to receive(:device_applications_dir).and_return(app_dir)
        end

        it "device applications dir does not exist" do
          expect(File).to receive(:exist?).with(app_dir).and_return(false)

          expect(core_sim.send(:installed_app_bundle_dir)).to be == nil
        end
      end

      describe '#app_sandbox_dir' do
        it 'returns nil if there is no app bundle' do
          expect(core_sim).to receive(:installed_app_bundle_dir).and_return nil

          expect(core_sim.send(:app_sandbox_dir)).to be == nil
        end

        describe 'app is installed' do
          before do
            expect(core_sim).to receive(:installed_app_bundle_dir).and_return '/'
          end

          it 'iOS >= 8.0' do
            expect(core_sim).to receive(:app_sandbox_dir_sdk_gte_8).and_return 'match'

            expect(core_sim.send(:app_sandbox_dir)).to be == 'match'
          end

          it 'iOS < 8.0' do
            expect(device).to receive(:version).and_return RunLoop::Version.new('7.1')

            expect(core_sim.send(:app_sandbox_dir)).to be == '/'
          end
        end
      end

      describe '#app_library_dir' do
        it 'returns nil when app is not installed' do
          expect(core_sim).to receive(:app_sandbox_dir).and_return nil

          expect(core_sim.send(:app_library_dir)).to be == nil
        end

        it 'returns Library dir when app is installed' do
          expect(core_sim).to receive(:app_sandbox_dir).and_return '/'

          expect(core_sim.send(:app_library_dir)).to be == '/Library'
        end
      end

      describe '#app_library_preferences_dir' do
        it 'returns nil when app is not installed' do
          expect(core_sim).to receive(:app_library_dir).and_return nil

          expect(core_sim.send(:app_library_preferences_dir)).to be == nil
        end

        it 'returns Library/Preferences dir when app is installed' do
          expect(core_sim).to receive(:app_library_dir).and_return '/'

          expect(core_sim.send(:app_library_preferences_dir)).to be == '/Preferences'
        end
      end

      describe '#app_documents_dir' do
        it 'returns nil when app is not installed' do
          expect(core_sim).to receive(:app_sandbox_dir).and_return nil

          expect(core_sim.send(:app_documents_dir)).to be == nil
        end

        it 'returns Documents dir when app is installed' do
          expect(core_sim).to receive(:app_sandbox_dir).and_return '/'

          expect(core_sim.send(:app_documents_dir)).to be == '/Documents'
        end
      end

      describe '#app_tmp_dir' do
        it 'returns nil when app is not installed' do
          expect(core_sim).to receive(:app_sandbox_dir).and_return nil

          expect(core_sim.send(:app_tmp_dir)).to be == nil
        end

        it 'returns tmp dir when app is installed' do
          expect(core_sim).to receive(:app_sandbox_dir).and_return '/'

          expect(core_sim.send(:app_tmp_dir)).to be == '/tmp'
        end
      end

      it '#device_library_cache_dir' do
        expect(core_sim).to receive(:device_data_dir).and_return('/')

        expect(core_sim.send(:device_caches_dir)).to be == '/Library/Caches'
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

      before do
        source = File.join(Resources.shared.resources_dir, 'CoreSimulator')
        FileUtils.cp_r(source, tmp_dir)
        stub_const('RunLoop::CoreSimulator::CORE_SIMULATOR_DEVICE_DIR', directory)
      end

      # Not yet.
      # it '#app_uia_crash_logs' do
      #   core_sim = RunLoop::CoreSimulator.new(device_with_app, app)
      #
      #   lib_dir = core_sim.send(:app_library_dir)
      #   expect(lib_dir).not_to be == nil
      #   expect(File.exist?(lib_dir)).to be_truthy
      #
      #   logs_dir = File.join(lib_dir, 'CrashReporter', 'UIALogs')
      #   FileUtils.mkdir_p(logs_dir)
      #   FileUtils.touch(File.join(logs_dir, 'a.plist'))
      #   FileUtils.touch(File.join(logs_dir, 'a.png'))
      #   FileUtils.touch(File.join(logs_dir, 'b.plist'))
      #
      #   logs = core_sim.send(:app_uia_crash_logs)
      #   expect(logs).not_to be == nil
      #   expect(logs.count).to be == 2
      # end

      describe '#app_sandbox_dir' do
        it 'app is installed' do
          core_sim = RunLoop::CoreSimulator.new(device_with_app, app)
          expect(core_sim).to receive(:installed_app_bundle_dir).and_return("path/My.app")

          actual = core_sim.send(:app_sandbox_dir)
          expect(actual).to be_truthy
          expect(File.exist?(actual)).to be_truthy
        end

        it 'app is not installed' do
          core_sim = RunLoop::CoreSimulator.new(device_without_app, app)

          actual = core_sim.send(:app_sandbox_dir)
          expect(actual).to be_falsey
        end
      end

      describe '#clear_device_launch_cssstore' do

        let(:counter) do
          lambda do |path|
            Dir.glob(File.join(path, "com.apple.LaunchServices-*.csstore")).count
          end
        end

        it 'no matching' do
          core_sim = RunLoop::CoreSimulator.new(device_with_app, app)
          device_caches_dir = core_sim.send(:device_caches_dir)

          before_count =  counter.call(device_caches_dir)
          expect(before_count).to be == 0

          core_sim.send(:clear_device_launch_csstore)

          after_count = counter.call(device_caches_dir)
          expect(after_count).to be == 0
        end

        it 'matching' do
          core_sim = RunLoop::CoreSimulator.new(device_without_app, app)
          device_caches_dir = core_sim.send(:device_caches_dir)

          before_count =  counter.call(device_caches_dir)
          expect(before_count).to be == 4

          core_sim.send(:clear_device_launch_csstore)

          after_count = counter.call(device_caches_dir)
          expect(after_count).to be == 0
        end
      end
    end

    describe '#installed_app_sha1' do
      it 'returns nil if app is not installed' do
        expect(core_sim).to receive(:installed_app_bundle_dir).and_return nil

        expect(core_sim.send(:installed_app_sha1)).to be == nil
      end

      it 'returns the sha1 of the installed app' do
        path = '/path/to/installed.app'
        expect(core_sim).to receive(:installed_app_bundle_dir).and_return path
        expect(RunLoop::Directory).to receive(:directory_digest).with(path).and_return 'sha1'

        expect(core_sim.send(:installed_app_sha1)).to be == 'sha1'
      end
    end

    describe '#same_sha1_as_installed?' do
      it 'returns false if they are different' do
        expect(app).to receive(:sha1).and_return 'a'
        expect(core_sim).to receive(:installed_app_sha1).and_return 'b'

        expect(core_sim.send(:same_sha1_as_installed?)).to be_falsey
      end

      it 'returns true if they are the same' do
        expect(app).to receive(:sha1).and_return 'a'
        expect(core_sim).to receive(:installed_app_sha1).and_return 'a'

        expect(core_sim.send(:same_sha1_as_installed?)).to be_truthy
      end
    end

    describe '#install' do
      it 'when app is already installed and sha1 is the same' do
        expect(core_sim).to receive(:installed_app_bundle_dir).and_return '/path'
        expect(core_sim).to receive(:ensure_app_same).and_return true

        expect(core_sim.install).to be == '/path'
      end

      it 'when the app is not installed' do
        expect(core_sim).to receive(:installed_app_bundle_dir).and_return nil
        expect(core_sim).to receive(:install_app_with_simctl).and_return '/new/path'

        expect(core_sim.install).to be == '/new/path'
      end

      it '#install_app_with_simctl' do
        expect(core_sim).to receive(:launch_simulator).and_return true
        args = ["simctl", 'install', device.udid, app.path]
        timeout = RunLoop::CoreSimulator::DEFAULT_OPTIONS[:install_app_timeout]
        options = { :log_cmd => true, :timeout => timeout }

        expect(core_sim.xcrun).to receive(:run_command_in_context).with(args, options).and_return({})
        expect(core_sim.device).to receive(:simulator_wait_for_stable_state).and_return true

        expect(core_sim).to receive(:installed_app_bundle_dir).and_return('/new/path')

        expect(core_sim.send(:install_app_with_simctl)).to be == '/new/path'
      end
    end

    it "#launch_app_with_simctl" do
      args = ["simctl", "launch", device.udid, app.bundle_identifier]
      timeout = RunLoop::CoreSimulator::DEFAULT_OPTIONS[:launch_app_timeout]
      options = { :log_cmd => true, :timeout => timeout }
      expect(core_sim.xcrun).to receive(:run_command_in_context).with(args, options).and_return({})

      expect(core_sim.send(:launch_app_with_simctl)).to be == {}
    end

    it "#handle_failed_app_launch" do
      hash = {
        :out => "The error output",
        :exit_status => 1
      }

      actual = core_sim.send(:handle_failed_app_launch, hash, 2, 5, 0)
      expect(actual).to be == hash[:out]
    end

    describe "#attempt_to_launch_with_simctl" do
      let(:error) { RunLoop::Xcrun::TimeoutError.new("My timeout") }
      let (:hash) do
        {
          :exit_status => 1,
          :out => error.message
        }
      end

      it "successful launch" do
        hash[:exit_status] = 0
        hash[:out] = nil
        expect(core_sim).to receive(:launch_app_with_simctl).and_return(hash)

        actual = core_sim.send(:attempt_to_launch_app_with_simctl)
        expect(actual).to be == hash
      end

      it "timeout error" do
        expect(core_sim).to receive(:launch_app_with_simctl).and_raise(error)
        expect(RunLoop::CoreSimulator).to receive(:terminate_core_simulator_processes).and_return(true)
        expect(core_sim).to receive(:launch_simulator).and_return(true)
        expect(Kernel).to receive(:sleep).with(0.5).and_return(true)

        actual = core_sim.send(:attempt_to_launch_app_with_simctl)
        expect(actual).to be == hash
      end

      it "any other error" do
        expect(core_sim).to receive(:launch_app_with_simctl).and_raise(RuntimeError)

        expect do
          core_sim.send(:attempt_to_launch_app_with_simctl)
        end.to raise_error RuntimeError
      end
    end

    describe "#launch" do
      let(:tries) { 3 }

      before do
        expect(core_sim).to receive(:install).and_return(true)
        expect(core_sim).to receive(:launch_simulator).and_return(true)
        expect(RunLoop::Environment).to receive(:ci?).and_return(false)
      end

      it "launches on the first try" do
        hash = {
          :out => nil,
          :exit_status => 0
        }
        expect(core_sim).to receive(:attempt_to_launch_app_with_simctl).and_return(hash)
        expect(core_sim).to receive(:wait_for_app_launch).and_return(:launched)

        expect(core_sim.launch).to be == :launched
      end

      it "never launches" do
        hash = {
          :out => "My launch error",
          :exit_status => 1
        }

        expect(core_sim).to receive(:attempt_to_launch_app_with_simctl).exactly(tries).times.and_return(hash)
        expect(core_sim).to receive(:handle_failed_app_launch).exactly(tries).times.and_return(hash[:out])

        expect do
          core_sim.launch
        end.to raise_error RuntimeError, /#{hash[:out]}/
      end

      it "launches after 2 tries" do
        bad = {
          :out => "My launch error",
          :exit_status => 1
        }

        good = {
          :out => nil,
          :exit_status => 0
        }

        values = [bad, bad, good]

        expect(core_sim).to receive(:attempt_to_launch_app_with_simctl).and_return(*values)
        expect(core_sim).to receive(:handle_failed_app_launch).exactly(tries - 1).times.and_return(bad)
        expect(core_sim).to receive(:wait_for_app_launch).and_return(:launched)

        expect(core_sim.launch).to be == :launched
      end
    end

    describe '.wait_for_simulator_state' do
      before do
        stub_const("RunLoop::CoreSimulator::WAIT_FOR_SIMULATOR_STATE_INTERVAL", 0)

        options = { :wait_for_state_timeout => 0.2 }
        stub_const('RunLoop::CoreSimulator::DEFAULT_OPTIONS', options)
      end

      it 'times out if state is never reached' do
        expect(device).to receive(:update_simulator_state).at_least(:once).and_return 'Undesired'

        expect do
          RunLoop::CoreSimulator.wait_for_simulator_state(device, 'Desired')
        end.to raise_error RuntimeError, /Expected/
      end

      it 'waits for a state' do
        values = ['Undesired', 'Undesired', 'Desired']
        expect(device).to receive(:update_simulator_state).at_least(:once).and_return(*values)

        expect(RunLoop::CoreSimulator.wait_for_simulator_state(device, "Desired")).to be_truthy
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
          args = [core_sim.device, "Shutdown"]
          expect(RunLoop::CoreSimulator).to receive(:wait_for_simulator_state).with(*args).and_return true
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

    describe '#ensure_app_same' do
      it 'does nothing if app is not installed' do
        expect(core_sim).to receive(:installed_app_bundle_dir).and_return nil

        expect(core_sim.send(:ensure_app_same)).to be_truthy
      end

      it 'does nothing if the app is the same' do
        expect(core_sim).to receive(:installed_app_bundle_dir).and_return '/some/path'
        expect(core_sim.app).to receive(:sha1).and_return :sha1
        expect(core_sim).to receive(:installed_app_sha1).and_return :sha1

        expect(core_sim.send(:ensure_app_same)).to be_truthy
      end

      it 'installs the new app' do
        path = '/some/path'
        expect(core_sim).to receive(:installed_app_bundle_dir).and_return '/some/path'
        expect(core_sim.app).to receive(:sha1).and_return :a
        expect(core_sim).to receive(:installed_app_sha1).and_return :b

        allow(FileUtils).to receive(:rm_rf).with(path).and_return true

        args = ['ditto', app.path, '/some/CalSmoke-cal.app']
        options = {:log_cmd => true}
        expect(core_sim.xcrun).to receive(:run_command_in_context).with(args, options).and_return({})

        expect(core_sim).to receive(:clear_device_launch_csstore).and_return true

        expect(core_sim.send(:ensure_app_same)).to be_truthy
      end
    end

    describe '#sim_name' do
      it 'Xcode >= 7.0' do
        expect(core_sim.xcode).to receive(:version_gte_7?).and_return true
        expect(core_sim.send(:sim_name)).to be == 'Simulator'
      end

      it '6.0 <= Xcode < 7.0' do
        expect(core_sim.xcode).to receive(:version_gte_7?).and_return false
        expect(core_sim.send(:sim_name)).to be == 'iOS Simulator'
      end
    end

    describe '#sim_app_path' do
      describe 'per version' do
        before do
          expect(core_sim.xcode).to receive(:developer_dir).and_return('/Xcode')
        end

        it 'Xcode >= 7.0' do
          expect(core_sim.xcode).to receive(:version_gte_7?).and_return true
          expected = '/Xcode/Applications/Simulator.app'

          expect(core_sim.send(:sim_app_path)).to be == expected
          expect(core_sim.instance_variable_get(:@sim_app_path)).to be == expected
          expect(core_sim.send(:sim_app_path)).to be == expected
        end

        it '6.0 <= Xcode < 7.0' do
          expect(core_sim.xcode).to receive(:version_gte_7?).and_return false

          expected = '/Xcode/Applications/iOS Simulator.app'
          expect(core_sim.send(:sim_app_path)).to be == expected
          expect(core_sim.instance_variable_get(:@sim_app_path)).to be == expected
          expect(core_sim.send(:sim_app_path)).to be == expected
        end
      end

      it 'returns a path that exists' do
        path = core_sim.send(:sim_app_path)
        expect(File.exist?(path)).to be == true
      end

      Resources.shared.alt_xcode_install_paths.each do |path|
        it "#{path}" do
          Resources.shared.with_developer_dir(path) do
            path = core_sim.send(:sim_app_path)
            expect(path).not_to be == nil
            expect(File.exist?(path)).to be_truthy
          end
        end
      end
    end
  end
end
