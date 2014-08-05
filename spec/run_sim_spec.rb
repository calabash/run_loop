describe RunLoop do

  before(:each) {
    ENV.delete('DEVELOPER_DIR')
    RunLoop::SimControl.terminate_all_sims
  }

  describe 'run on simulator' do
    it "Xcode #{Resources.shared.current_xcode_version}" do
      sim_control = RunLoop::SimControl.new
      sim_control.reset_sim_content_and_settings

      options = {
            :launch_retries => 2,
            :app => Resources.shared.app_bundle_path,
            :device_target => 'simulator',
            :sim_control => sim_control
      }
      expect(RunLoop.run(options)).not_to be nil
    end
  end

  context 'regression: run on simulators' do
    unless travis_ci?
      xcode_installs = Resources.shared.alt_xcodes_gte_xc51_hash
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
            options = {
                  :launch_retries => 2,
                  :app => Resources.shared.app_bundle_path,
                  :device_target => 'simulator',
                  :sim_control => sim_control
            }
            expect(RunLoop.run(options)).not_to be nil
          end
        end
      end
    end
  end
end
