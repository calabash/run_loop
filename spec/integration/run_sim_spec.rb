describe RunLoop do

  before(:each) {
    RunLoop::SimControl.terminate_all_sims
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

      Resources.shared.launch_with_options(options) do |hash|
        expect(hash).not_to be nil
      end
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

              Resources.shared.launch_with_options(options) do |hash|
                expect(hash).not_to be nil
              end

            end
          end
        end
      end
    end
  end
end
