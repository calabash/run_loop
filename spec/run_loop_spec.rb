describe RunLoop do

  before(:each) { ENV.delete('DEVELOPER_DIR') }

  unless travis_ci?
    describe '.run' do
      describe 'on simulators' do

        before(:each) {
          RunLoop::SimControl.terminate_all_sims
          @options = {:launch_retries => 2,
                      :app => Resources.shared.app_bundle_path,
                      :device_target => 'simulator'}
        }

        it 'using the current version of Xcode' do
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
              it "using Xcode '#{xcode_path}'" do
                ENV['DEVELOPER_DIR'] = xcode_path
                sim_control = RunLoop::SimControl.new
                @options[:sim_control] = sim_control
                expect(RunLoop.run(@options)).not_to be nil
            end
          end
        end
      end
    end
  end
end
