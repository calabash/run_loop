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

  describe 'run on simulator' do
    it "Xcode #{Resources.shared.current_xcode_version}" do
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
    end
  end

  describe 'regression: run on simulators' do
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
                      :app => Resources.shared.cal_app_bundle_path,
                      :device_target => 'simulator',
                      :sim_control => sim_control
                }

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
