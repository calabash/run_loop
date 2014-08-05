describe RunLoop do

  before(:each) { ENV.delete('DEVELOPER_DIR') }

  unless travis_ci?
    describe '.run' do
      describe 'on simulators using' do

        before(:each) {
          RunLoop::SimControl.terminate_all_sims
          @options = {:launch_retries => 2,
                      :app => Resources.shared.app_bundle_path,
                      :device_target => 'simulator'}
        }

        it "Xcode #{RunLoop::XCTools.new.xcode_version}" do
          sim_control = RunLoop::SimControl.new
          sim_control.reset_sim_content_and_settings
          xctools = sim_control.xctools
          if xctools.xcode_version_gte_6?
            RunLoop::SimControl.new.launch_sim({:hide_after => true})
          end
          @options[:sim_control] = sim_control
          expect(RunLoop.run(@options)).not_to be nil
        end

        rspec_warn_log 'only testing Xcode 5.1 and Xcode 5.1.1 - need to test 5.0*'
        xcode_installs = Resources.shared.alt_xcode_install_paths '5.1'
        if xcode_installs.empty?
          rspec_info_log 'no alternative versions of Xcode >= 5.0 found in /Xcode directory'
        else
          xcode_installs.each do |xcode_path|
            it "#{xcode_path}" do
              ENV['DEVELOPER_DIR'] = xcode_path
              sim_control = RunLoop::SimControl.new
              @options[:sim_control] = sim_control
              expect(RunLoop.run(@options)).not_to be nil
            end
          end
        end
      end

      describe 'on physical devices using' do
        describe "Xcode #{RunLoop::XCTools.new.xcode_version}" do
          xctools = RunLoop::XCTools.new
          physical_devices = xctools.instruments :devices
          ios8 = RunLoop::Version.new('8.0')
          ios7 = RunLoop::Version.new('7.0')
          if physical_devices.empty?
            rspec_info_log 'no physical devices are connected to this Mac'
          else

            physical_devices.each do |device|
              if (xctools.xcode_version < xctools.v60 and device.version >= ios8) or
                    (xctools.xcode_version >= xctools.v60 and device.version < ios7)
                rspec_warn_log "skipping #{device.name} iOS #{device.version} because it is not supported on #{xctools.xcode_version}"
              else
                it "#{device.name} iOS #{device.version}" do
                  options =
                        {
                              :bundle_id => Resources.shared.bundle_id,
                              :launch_retries => 2,
                              :udid => device.udid,
                              :device_target => device.udid,
                              :sim_control => RunLoop::SimControl.new,
                              :app => Resources.shared.bundle_id

                        }
                  expect { Resources.shared.ideviceinstaller(device.udid, :install) }.to_not raise_error
                  expect(RunLoop.run(options)).not_to be nil
                end
              end
            end
          end
        end

        # describe 'Xcode 6b4' do
        #   ENV['DEVELOPER_DIR'] = '/Xcode/6b4/Xcode6-Beta4.app/Contents/Developer'
        #   xctools = RunLoop::XCTools.new
        #   physical_devices = xctools.instruments :devices
        #   ios8 = RunLoop::Version.new('8.0')
        #   if physical_devices.empty?
        #     rspec_info_log 'no physical devices are connected to this Mac'
        #   else
        #
        #     physical_devices.each do |device|
        #       if xctools.xcode_version < xctools.v60 and device.version >= ios8
        #         rspec_warn_log "skipping #{device.name} iOS #{device.version} because it is not supported on #{xctools.xcode_version}"
        #       else
        #         it "#{device.name} iOS #{device.version}" do
        #           ENV['DEVELOPER_DIR'] = '/Xcode/6b4/Xcode6-Beta4.app/Contents/Developer'
        #           options =
        #                 {
        #                       :bundle_id => Resources.shared.bundle_id,
        #                       :launch_retries => 2,
        #                       :udid => device.udid,
        #                       :device_target => device.udid,
        #                       :sim_control => RunLoop::SimControl.new,
        #                       :app => Resources.shared.bundle_id
        #
        #                 }
        #           expect { Resources.shared.ideviceinstaller(device.udid, :install) }.to_not raise_error
        #           expect(RunLoop.run(options)).not_to be nil
        #         end
        #       end
        #     end
        #   end
        # end


        rspec_warn_log 'only testing Xcode 5.1 and Xcode 5.1.1 - need to test 5.0*'
        xcode_installs = Resources.shared.alt_xcode_install_paths '5.1'
        if xcode_installs.empty?
          rspec_info_log 'no alternative versions of Xcode >= 5.0 found in /Xcode directory'
        else
          xcode_installs.each do |xcode_path|
            describe "using #{xcode_path}" do
              ENV['DEVELOPER_DIR'] = xcode_path
              xctools = RunLoop::XCTools.new
              ios8 = RunLoop::Version.new('8.0')
              ios7 = RunLoop::Version.new('7.0')
              physical_devices = xctools.instruments :devices
              physical_devices.each do |device|
                if (xctools.xcode_version < xctools.v60 and device.version >= ios8) or
                      (xctools.xcode_version >= xctools.v60 and device.version < ios7)
                else
                  it "#{device.name} iOS #{device.version}" do
                    ENV['DEVELOPER_DIR'] = xcode_path
                    options =
                          {
                                :bundle_id => Resources.shared.bundle_id,
                                :launch_retries => 2,
                                :udid => device.udid,
                                :device_target => device.udid,
                                :sim_control => RunLoop::SimControl.new,
                                :app => Resources.shared.bundle_id

                          }
                    expect { Resources.shared.ideviceinstaller(device.udid, :install) }.to_not raise_error
                    expect(RunLoop.run(options)).not_to be nil
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
