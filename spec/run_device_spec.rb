unless Resources.shared.travis_ci?

  describe RunLoop do

    before(:each) {
      ENV.delete('DEVELOPER_DIR')
      ENV.delete('DEBUG')
      ENV.delete('DEBUG_UNIX_CALLS')
    }

    after(:each) {
      ENV.delete('DEVELOPER_DIR')
      ENV.delete('DEBUG')
      ENV.delete('DEBUG_UNIX_CALLS')
    }

    context 'running on physical devices' do
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
        ios8 = RunLoop::Version.new('8.0')
        ios7 = RunLoop::Version.new('7.0')
        physical_devices.each do |device|
          if (xctools.xcode_version < xctools.v60 and device.version >= ios8) or
                (xctools.xcode_version >= xctools.v60 and device.version < ios7)
            it "skipping #{device.name} iOS #{device.version} because it is not supported on #{xctools.xcode_version}" do
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
            end
          end
        end
      end
    end


    describe 'regression: running on physical devices' do
      outer_xctools = RunLoop::XCTools.new
      xcode_installs = Resources.shared.alt_xcodes_gte_xc51_hash
      physical_devices = outer_xctools.instruments :devices
      if not xcode_installs.empty? and Resources.shared.ideviceinstaller_available? and not physical_devices.empty?
        xcode_installs.each do |install_hash|
          version = install_hash[:version]
          path = install_hash[:path]
          physical_devices.each do |device|
            it "Xcode #{version} @ #{path} #{device.name} iOS #{device.version}" do
              ENV['DEVELOPER_DIR'] = path
              inner_tools = RunLoop::XCTools.new
              ios8 = RunLoop::Version.new('8.0')
              ios7 = RunLoop::Version.new('7.0')
              unless (inner_tools.xcode_version < inner_tools.v60 and device.version >= ios8) or
                    (inner_tools.xcode_version >= inner_tools.v60 and device.version < ios7)
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
              end
            end
          end
        end
      end
    end
  end
end