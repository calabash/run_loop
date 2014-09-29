describe RunLoop::Instruments do

  let (:instruments) { RunLoop::Instruments.new }

  before(:each) {
    ENV.delete('DEVELOPER_DIR')
    ENV.delete('DEBUG')
    ENV.delete('DEBUG_UNIX_CALLS')
    RunLoop::SimControl.terminate_all_sims
  }

  after(:each) {
    ENV.delete('DEVELOPER_DIR')
    ENV.delete('DEBUG')
    ENV.delete('DEBUG_UNIX_CALLS')
    #RunLoop::SimControl.terminate_all_sims
    Resources.shared.kill_fake_instruments_process
  }

  describe '.new' do
    it 'creates a new RunLoop::Instruments instance' do
      expect(RunLoop::Instruments.new).to be_a RunLoop::Instruments
    end
  end

  describe '#ps_for_instruments' do
    it 'can find instruments processes' do
      cmd = 'ps x -o pid,command | grep -v grep | grep fake-instruments'
      3.times { Resources.shared.fork_fake_instruments_process }
      output = []
      instruments.instance_eval {
        output = ps_for_instruments(cmd).strip.split("\n")
      }
      expect(output.count).to be == 3
    end
  end

  describe '#is_instruments_process?' do
    describe 'returns false when process description' do
      it 'is nil' do
        expect(instruments.instance_eval {
          is_instruments_process?(nil)
        }).to be == false
      end

      it 'does not match instruments regex' do
        expect( instruments.instance_eval {
          is_instruments_process?('/usr/bin/foo')
        }).to be == false
        expect( instruments.instance_eval {
          is_instruments_process?('instruments')
        }).to be == false
      end
    end

    describe 'returns true when process description' do
      it "starts with 'sh -c xcrun instruments'" do
        description = "sh -c xcrun instruments -w \"43be3f89d9587e9468c24672777ff6241bd91124\" < args >"
        expect( instruments.instance_eval {
          is_instruments_process?(description)
        }).to be == true
      end

      it "contains '/usr/bin/instruments'" do
        description = "/Xcode/6.0.1/Xcode.app/Contents/Developer/usr/bin/instruments -w \"43be3f89d9587e9468c24672777ff6241bd91124\" < args >"
        expect( instruments.instance_eval {
          is_instruments_process?(description)
        }).to be == true
      end
    end
  end

  describe '#pids_from_ps_output' do
    it 'when no instruments process are running returns an empty array' do
      ps_cmd = 'ps x -o pid,command | grep -v grep | grep a-process-that-does-not-exist'
      expect( instruments.instance_eval {
        pids_from_ps_output(ps_cmd).count
      }).to be == 0
    end

    it 'can parse pids from typical ps output' do
      ps_output = ["98081 sh -c xcrun instruments -w \"43be3f89d9587e9468c24672777ff6241bd91124\" < args >",
                   "98082 /Xcode/6.0.1/Xcode.app/Contents/Developer/usr/bin/instruments -w < args >"].join("\n")
      expect(instruments).to receive(:ps_for_instruments).and_return(ps_output)
      expected = [98081, 98082]
      actual = []
      instruments.instance_eval { actual = pids_from_ps_output }
      expect(actual).to match_array expected
    end

    it 'when instruments process is running returns 1 process' do
      sim_control = RunLoop::SimControl.new
      sim_control.reset_sim_content_and_settings
      options =
            {
                  :app => Resources.shared.cal_app_bundle_path,
                  :device_target => 'simulator',
                  :sim_control => sim_control
            }

      hash = nil
      Retriable.retriable({:tries => Resources.shared.travis_ci? ? 5 : 2}) do
        hash = RunLoop.run(options)
      end
      expect(hash).not_to be nil
      expect(instruments.instance_eval {
        pids_from_ps_output.count
      }).to be == 1
    end
  end

  describe '#instruments_pids' do
    it 'when no block is passed it returns a list of processes' do
      expected = [98081, 98082]
      expect(instruments).to receive(:pids_from_ps_output).and_return(expected)
      actual = instruments.instruments_pids
      expect(actual).to match_array expected
    end

    it 'when a block is passed it is applied to the processes' do
      pids = [98081, 98082]
      expect(instruments).to receive(:pids_from_ps_output).and_return(pids)
      expected = ["98081", "98082"]
      collected = []
      instruments.instruments_pids do |pid|
        collected << pid.to_s
      end
      expect(collected).to match_array expected
    end
  end

  describe '#instruments_running?' do
    it 'returns false when no instruments process are found' do
      expect(instruments).to receive(:instruments_pids).and_return([])
      expect(instruments.instruments_running?).to be == false
    end

    it 'return true when instruments process are found' do
      expect(instruments).to receive(:instruments_pids).and_return([1])
      expect(instruments.instruments_running?).to be == true
    end
  end

  describe '#kill_signal' do
    it 'the current Xcode version' do
      xcode_tools = RunLoop::XCTools.new
      expected =  xcode_tools.xcode_version_gte_6? ? 'QUIT' : 'TERM'
      expect(instruments.instance_eval {
        kill_signal(xcode_tools)
      }).to be == expected
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
            ENV['DEVELOPER_DIR'] = developer_dir
            xcode_tools = RunLoop::XCTools.new
            expected =  xcode_tools.xcode_version_gte_6? ? 'QUIT' : 'TERM'
            expect(instruments.instance_eval {
              kill_signal(xcode_tools)
            }).to be == expected
          end
        end
      end
    end
  end

  describe '#wait_for_process_to_terminate' do
    describe 'raises an error if' do
      it 'the process is still alive and :raise_on_no_terminate => true' do
        Resources.shared.fork_fake_instruments_process
        pid = Resources.shared.fake_instruments_pids.first
        options = {:raise_on_no_terminate => true}
        expect { instruments.instance_eval {
          wait_for_process_to_terminate(pid, options)
        }}.to raise_error
      end
    end

    describe 'does not raise an error' do
      it 'if process is terminated' do
        Resources.shared.fork_fake_instruments_process
        pid = Resources.shared.fake_instruments_pids.first
        sleep 1.0
        Resources.shared.kill_fake_instruments_process
        expect { instruments.instance_eval {
          wait_for_process_to_terminate(pid, { :raise_on_no_terminate => true})
        }}.not_to raise_error
      end

      it 'by default if the process is still alive' do
        Resources.shared.fork_fake_instruments_process
        pid = Resources.shared.fake_instruments_pids.first
        expect { instruments.instance_eval {
          wait_for_process_to_terminate pid
        }}.not_to raise_error
      end
    end
  end


  describe '#kill_instruments' do
    it 'terminates instruments processes' do
      3.times { Resources.shared.fork_fake_instruments_process }
      pids = Resources.shared.fake_instruments_pids
      expect(instruments).to receive(:instruments_pids).and_return(pids)

      # Terminating with 'QUIT' spawns a crash dialog in the Finder.
      expect(instruments).to receive(:kill_signal).and_return('TERM')

      instruments.kill_instruments

      Resources.shared.fake_instruments_pids = []
      cmd = 'ps x -o pid,command | grep -v grep | grep fake-instruments'
      actual = `#{cmd}`
      expect(actual).to be == ''
    end

    # @todo Sometimes the 'No such process' error is not thrown.
    it 'suppresses Process.kill exceptions' do
      Resources.shared.fork_fake_instruments_process
      pids = Resources.shared.fake_instruments_pids

      # Wait so no SIGTERM exception is thrown
      sleep 1.0
      # Kill the process process we just forked to induce kill_instruments to
      # raise 'Errno::ESRCH: No such process'.
      Resources.shared.kill_fake_instruments_process

      # Terminating with 'QUIT' spawns a crash dialog in the Finder.
      expect(instruments).to receive(:kill_signal).and_return('TERM')
      expect(instruments).to receive(:instruments_pids).and_return(pids)
      expect { instruments.kill_instruments }.not_to raise_exception
    end

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
        Retriable.retriable({:tries => Resources.shared.travis_ci? ? 5 : 2}) do
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
              ENV['DEVELOPER_DIR'] = developer_dir
              sim_control = RunLoop::SimControl.new
              sim_control.reset_sim_content_and_settings
              options =
                    {
                          :app => Resources.shared.cal_app_bundle_path,
                          :device_target => 'simulator',
                          :sim_control => sim_control
                    }

              hash = nil
              Retriable.retriable({:tries => Resources.shared.travis_ci? ? 5 : 2}) do
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

    unless Resources.shared.travis_ci?
      describe 'running against devices' do
        xctools = RunLoop::XCTools.new
        physical_devices = xctools.instruments :devices
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
            if device.version >= RunLoop::Version.new('8.0') and xctools.xcode_version < RunLoop::Version.new('6.0')
              it "combination not supported - skipping #{device.name} iOS #{device.version} Xcode #{xctools.xcode_version}" do
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
        xcode_installs = Resources.shared.alt_xcodes_gte_xc51_hash
        physical_devices = xctools.instruments :devices
        if not xcode_installs.empty? and Resources.shared.ideviceinstaller_available? and not physical_devices.empty?
          xcode_installs.each do |install_hash|
            version = install_hash[:version]
            path = install_hash[:path]
            physical_devices.each do |device|
              if device.version >= RunLoop::Version.new('8.0') and version < RunLoop::Version.new('6.0')
                it "combination not supported - skipping #{device.name} iOS #{device.version} Xcode #{version}" do
                  expect(true).to be == true
                end
              else
                it "Xcode #{version} @ #{path} #{device.name} iOS #{device.version}" do
                  ENV['DEVELOPER_DIR'] = path
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
