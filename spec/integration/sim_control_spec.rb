require 'tmpdir'

describe RunLoop::SimControl do

  before(:each) { ENV.delete('DEVELOPER_DIR') }

  subject(:sim_control) { RunLoop::SimControl.new }

  # flickering on Travis CI
  unless Resources.shared.travis_ci?
    describe '#quit_sim and #launch_sim' do
      before(:each) { RunLoop::SimControl.terminate_all_sims }

      it "with Xcode #{Resources.shared.current_xcode_version}" do
        sim_control.launch_sim({:hide_after => false})
        expect(sim_control.sim_is_running?).to be == true

        sim_control.quit_sim
        expect(sim_control.sim_is_running?).to be == false
      end

      xcode_installs = Resources.shared.alt_xcode_install_paths
      unless xcode_installs.empty?
        describe 'regression' do
          xcode_installs.each do |developer_dir|
            it "#{developer_dir}" do
              ENV['DEVELOPER_DIR'] = developer_dir
              local_sim_control = RunLoop::SimControl.new
              local_sim_control.launch_sim({:hide_after => true})
              expect(local_sim_control.sim_is_running?).to be == true

              local_sim_control.quit_sim
              expect(local_sim_control.sim_is_running?).to be == false
            end
          end
        end
      end
    end
  end

  describe '#relaunch_sim' do

    before(:each) { RunLoop::SimControl.terminate_all_sims }

    it "with Xcode #{Resources.shared.current_xcode_version}" do
      sim_control.relaunch_sim({:hide_after => true})
      expect(sim_control.sim_is_running?).to be == true
    end

    xcode_installs = Resources.shared.alt_xcode_install_paths
    unless xcode_installs.empty?
      describe 'regression' do
        xcode_installs.each do |developer_dir|
          it "#{developer_dir}" do
            ENV['DEVELOPER_DIR'] = developer_dir
            local_sim_control = RunLoop::SimControl.new
            local_sim_control.relaunch_sim({:hide_after => true})
            expect(local_sim_control.sim_is_running?).to be == true
          end
        end
      end
    end
  end

  describe '#sim_app_support_dir' do
    before(:each) {  RunLoop::SimControl.terminate_all_sims }
    it "with Xcode #{Resources.shared.current_xcode_version} returns a path that exists" do
      sim_control.relaunch_sim({:hide_after => true})
      path = sim_control.instance_eval { sim_app_support_dir }
      expect(File.exist?(path)).to be == true
    end

    describe 'regression' do
      xcode_installs = Resources.shared.alt_xcode_install_paths
      if xcode_installs.empty?
        it 'not alternative versions of Xcode found' do
          expect(true).to be == true
        end
      else
        xcode_installs.each do |developer_dir|
          it "returns a valid path for #{developer_dir}" do
            RunLoop::SimControl.terminate_all_sims
            ENV['DEVELOPER_DIR'] = developer_dir
            local_sim_control = RunLoop::SimControl.new
            local_sim_control.relaunch_sim({:hide_after => true})
            path = local_sim_control.instance_eval { sim_app_support_dir }
            expect(File.exist?(path)).to be == true
          end
        end
      end
    end
  end
end
