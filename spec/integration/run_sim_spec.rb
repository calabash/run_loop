describe RunLoop do

  before(:each) {
    ENV.delete('DEBUG')
    ENV.delete('DEBUG_UNIX_CALLS')
    RunLoop::SimControl.terminate_all_sims
  }

  after(:each) {
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

    xcode_installs = Resources.shared.alt_xcode_install_paths
    unless xcode_installs.empty?
      describe 'regression' do
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
