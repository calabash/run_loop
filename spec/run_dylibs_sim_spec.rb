# Disabling the dylib tests because they fail in Xcode 6 environments.
unless Resources.shared.travis_ci? or true

  describe RunLoop do

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
    }

    describe 'injecting a dylib targeting the simulator with' do
      it "Xcode #{Resources.shared.current_xcode_version}" do
        sim_control = RunLoop::SimControl.new
        sim_control.reset_sim_content_and_settings

        options =
              {
                    :app => Resources.shared.app_bundle_path,
                    :device_target => 'simulator',
                    :sim_control => sim_control,
                    :inject_dylib => Resources.shared.sim_dylib_path
              }
        hash = nil
        Retriable.retriable({:tries => Resources.shared.travis_ci? ? 7 : 2}) do
          hash = RunLoop.run(options)
        end
        expect(hash).not_to be nil
      end
    end

    unless Resources.shared.travis_ci?
      describe 'regression: injecting a dylib targeting the simulator with' do
        # Regression testing is not stable.  Use 'true' to skip the tests and
        # 'false' to run them.
        if false
          rspec_warn_log 'Skipping regression testing dylib injection b/c they are not stable.'
        else
          xcode_installs = Resources.shared.alt_xcode_details_hash
          if xcode_installs.empty?
            it 'no alternative Xcode installs' do
              expect(true).to be == true
            end
          else
            xcode_installs.each do |install_hash|
              version = install_hash[:version]
              path = install_hash[:path]
              it "Xcode #{version} @ #{path}" do
                expect(ENV.has_value? 'DEVELOPER_DIR').to be == false
                ENV['DEVELOPER_DIR'] = path
                sim_control = RunLoop::SimControl.new
                sim_control.reset_sim_content_and_settings
                expect(sim_control.xctools.xcode_version).to be == version
                options =
                      {
                            :app => Resources.shared.app_bundle_path,
                            :device_target => 'simulator',
                            :sim_control => sim_control,
                            :inject_dylib => Resources.shared.sim_dylib_path
                      }

                hash = nil
                Retriable.retriable({:tries => Resources.shared.travis_ci? ? 5 : 2}) do
                  hash = RunLoop.run(options)
                end
                expect(hash).not_to be == nil
              end
            end
          end
        end
      end
    end
  end
end
