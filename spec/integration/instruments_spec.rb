describe RunLoop::Instruments do

  let (:instruments) { RunLoop::Instruments.new }

  before(:each) {
    RunLoop::SimControl.terminate_all_sims
  }

  after(:each) {
    Resources.shared.kill_fake_instruments_process
  }

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

        Resources.shared.launch_sim_with_options(options) do |hash|
          expect(hash).not_to be nil
          expect(instruments.instruments_running?).to be == true
          instruments.kill_instruments(sim_control.xctools)
          expect(instruments.instruments_running?).to be == false
        end
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
                Resources.shared.launch_sim_with_options(options) do |hash|
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

                Resources.shared.launch_sim_with_options(options) do |hash|
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

                    Resources.shared.launch_sim_with_options(options) do |hash|
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

      Resources.shared.launch_sim_with_options(options) do |hash|
        expect(hash).not_to be nil
        expect(instruments.instance_eval {
                 pids_from_ps_output.count
               }).to be == 1
      end
    end
  end
end
