describe RunLoop::Instruments do

  let (:instruments) { RunLoop::Instruments.new }

  before(:each) {
    RunLoop::SimControl.terminate_all_sims
  }

  after(:each) {
    Resources.shared.kill_fake_instruments_process
  }

  describe '#spawn' do
    it 'spawns an instruments process that launches an app' do

      # Try to kill any instruments processes.
      instruments.kill_instruments

      udid = RunLoop::Core.default_simulator
      results_dir = Dir.mktmpdir('run_loop')
      trace_dir = File.join(results_dir, 'trace')
      FileUtils.mkdir_p(trace_dir)

      script = File.join(results_dir, '_run_loop.js')
      FileUtils.cp(Resources.shared.infinite_run_loop_script, script)

      log_file = File.join(results_dir, 'run_loop.out')

      app = Resources.shared.cal_app_bundle_path
      options =
            {
                  :udid => udid,
                  :results_dir_trace => trace_dir,
                  :bundle_dir_or_bundle_id => app,
                  :script => script,
                  :results_dir => results_dir,
                  :args => ['-NSDoubleLocalizedStrings', 'YES']
            }

      automation_template = RunLoop::Core.default_tracetemplate

      # Enable Accessibility on the specific simulator.
      sim_control = RunLoop::SimControl.new
      simulators = sim_control.send(:sim_details, :launch_name)
      directories = sim_control.send(:existing_sim_sdk_or_device_data_dirs)
      my_simulator = simulators[udid]
      my_directory = directories.select do |path|
        path =~ /#{my_simulator[:udid]}/
      end.first
      simulators = sim_control.send(:sim_details, :udid)
      sim_control.send(:enable_accessibility_in_sim_data_dir, my_directory, simulators)

      launch_timeout = Resources.shared.travis_ci? ? 20 : 10

      curl_for_server = lambda do
        begin
          Timeout.timeout(launch_timeout) do
            loop do
              # Server responds with '405 Method Not Allowed'.  Surprise!
              http_code = `xcrun curl -s -o /dev/null -I -w "%{http_code}" http://localhost:37265/version`
              break if http_code != '000'
              sleep 0.5
            end
          end
        rescue Timeout::Error
          raise RuntimeError, 'Calabash server did not respond to ping; application did not launch'
        end
      end

      # Kill instruments and quit the simulator on a retry.
      on_retry = Proc.new do |_, _, _, _|
        instruments.kill_instruments
        RunLoop::SimControl.terminate_all_sims
      end

      pid = nil
      retry_opts = RunLoop::RetryOpts.tries_and_interval(Resources.shared.launch_retries,
                                                         launch_timeout + 10,
                                                         {:on_retry => on_retry})
      Retriable.retriable(retry_opts) do
        pid = instruments.spawn(automation_template, options, log_file)
        curl_for_server.call
      end
      expect(pid).to_not be == nil
      expect(pid).to be_a(Integer)
      expect(instruments.instruments_running?).to be == true
    end
  end

  describe '#kill_instruments' do
    describe 'running against simulators' do
      it 'the current Xcode version' do

        sim_control = RunLoop::SimControl.new
        sim_control.reset_sim_content_and_settings
        options =
              {
                    :app => Resources.shared.cal_app_bundle_path,
                    :device_target => 'simulator',
                    :sim_control => sim_control
              }

        hash = nil
        Retriable.retriable({:tries => Resources.shared.launch_retries}) do
          hash = RunLoop.run(options)
        end
        expect(hash).not_to be nil
        expect(instruments.instruments_running?).to be == true
        instruments.kill_instruments(sim_control.xctools)
        expect(instruments.instruments_running?).to be == false
      end

      describe 'regression' do
        xcode_installs = Resources.shared.alt_xcode_install_paths
        if xcode_installs.empty?
          it 'no alternative versions of Xcode found' do
            expect(true).to be == true
          end
        else
          xcode_installs.each do |developer_dir|
            it "#{developer_dir}" do
              Resources.shared.with_developer_dir(developer_dir) do
                sim_control = RunLoop::SimControl.new
                sim_control.reset_sim_content_and_settings
                options =
                      {
                            :app => Resources.shared.cal_app_bundle_path,
                            :device_target => 'simulator',
                            :sim_control => sim_control
                      }

                hash = nil
                Retriable.retriable({:tries => Resources.shared.launch_retries}) do
                  hash = RunLoop.run(options)
                end
                expect(hash).not_to be nil
                expect(instruments.instruments_running?).to be == true
                instruments.kill_instruments(sim_control.xctools)
                expect(instruments.instruments_running?).to be == false
              end
            end
          end
        end
      end
    end

    unless Resources.shared.travis_ci?
      describe 'running against devices' do
        xctools = RunLoop::XCTools.new
        physical_devices = Resources.shared.physical_devices_for_testing(xctools)
        if physical_devices.empty?
          it 'no devices attached to this computer' do
            expect(true).to be == true
          end
        elsif not Resources.shared.ideviceinstaller_available?
          it 'device testing requires ideviceinstaller to be available in the PATH' do
            expect(true).to be == true
          end
        else
          physical_devices.each do |device|
            if Resources.shared.incompatible_xcode_ios_version(device.version, xctools.xcode_version)
              it "Skipping #{device.name} iOS #{device.version} Xcode #{xctools.xcode_version} - combination not supported" do
                expect(true).to be == true
              end
            else
              it "on #{device.name} iOS #{device.version} Xcode #{xctools.xcode_version}" do
                options =
                      {
                            :bundle_id => Resources.shared.bundle_id,
                            :udid => device.udid,
                            :device_target => device.udid,
                            :sim_control => RunLoop::SimControl.new,
                            :app => Resources.shared.bundle_id
                      }
                expect { Resources.shared.ideviceinstaller(device.udid, :install) }.to_not raise_error

                hash = nil
                Retriable.retriable({:tries => 2}) do
                  hash = RunLoop.run(options)
                end
                expect(hash).not_to be nil
                expect(instruments.instruments_running?).to be == true
                instruments.kill_instruments(xctools)
                expect(instruments.instruments_running?).to be == false
              end
            end
          end
        end
      end

      describe 'regression: running on physical devices' do
        xctools = RunLoop::XCTools.new
        physical_devices = Resources.shared.physical_devices_for_testing(xctools)
        xcode_installs = Resources.shared.alt_xcode_details_hash
        if not xcode_installs.empty? and Resources.shared.ideviceinstaller_available? and not physical_devices.empty?
          xcode_installs.each do |install_hash|
            version = install_hash[:version]
            path = install_hash[:path]
            physical_devices.each do |device|
              if Resources.shared.incompatible_xcode_ios_version(device.version, version)
                it "Skipping #{device.name} iOS #{device.version} Xcode #{version} - combination not supported" do
                  expect(true).to be == true
                end
              else
                it "Xcode #{version} @ #{path} #{device.name} iOS #{device.version}" do
                  Resources.shared.with_developer_dir(path) do
                    options =
                          {
                                :bundle_id => Resources.shared.bundle_id,
                                :udid => device.udid,
                                :device_target => device.udid,
                                :sim_control => RunLoop::SimControl.new,
                                :app => Resources.shared.bundle_id

                          }
                    expect { Resources.shared.ideviceinstaller(device.udid, :install) }.to_not raise_error
                    hash = nil
                    Retriable.retriable({:tries => 2}) do
                      hash = RunLoop.run(options)
                    end
                    expect(hash).not_to be nil
                    expect(instruments.instruments_running?).to be == true
                    instruments.kill_instruments(xctools)
                    expect(instruments.instruments_running?).to be == false
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  describe '#instruments_app_running?' do

    before(:each) { Resources.shared.kill_instruments_app }
    after(:each) { Resources.shared.kill_instruments_app }

    it 'returns true when Instruments.app is running' do
      Resources.shared.launch_instruments_app
      sleep 1
      expect(instruments.instruments_app_running?).to be == true
    end

    it 'returns false when Instruments.app is not running' do
      Resources.shared.kill_instruments_app(instruments)
      expect(instruments.instruments_app_running?).to be == false
    end
  end

  describe '#pids_from_ps_output' do
    it 'when instruments process is running return 1 process' do
      sim_control = RunLoop::SimControl.new
      sim_control.reset_sim_content_and_settings
      options =
            {
                  :app => Resources.shared.cal_app_bundle_path,
                  :device_target => 'simulator',
                  :sim_control => sim_control
            }

      hash = nil
      Retriable.retriable({:tries => Resources.shared.launch_retries}) do
        hash = RunLoop.run(options)
      end
      expect(hash).not_to be nil
      expect(instruments.instance_eval {
        pids_from_ps_output.count
      }).to be == 1
    end
  end
end
