describe RunLoop do

  before do
    allow(RunLoop::Environment).to receive(:debug?).and_return(true)
    RunLoop::CoreSimulator.quit_simulator
  end

  describe 'run on simulator' do
    it "Xcode #{Resources.shared.current_xcode_version}" do
      options =
        {
          :app => Resources.shared.cal_app_bundle_path,
          :simctl => RunLoop::Simctl.new
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
              options =
                    {
                          :app => Resources.shared.cal_app_bundle_path,
                          :simctl => RunLoop::Simctl.new
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
