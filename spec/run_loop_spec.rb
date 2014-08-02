describe RunLoop do

  before(:each) { ENV.delete('DEVELOPER_DIR') }

  unless travis_ci?
    describe '.run' do
      describe 'on simulators' do

        # noinspection RailsParamDefResolve
        before(:context) {
          @xcode_versions_tested = []
        }

        before(:each) {
          RunLoop::SimControl.terminate_all_sims
          @options = {:launch_retries => 2,
                      :app => Resources.shared.app_bundle_path,
                      :device_target => 'simulator'}
        }

        it 'using current version of Xcode' do
          xctools = RunLoop::XCTools.new
          xcode_version = xctools.xcode_version
          puts "INFO: trying to launch Xcode '#{xcode_version}' simulator"

          if xcode_version >= xctools.xc60
            RunLoop::SimControl.new.launch_sim({:hide_after => true})
          end

          expect(RunLoop.run(@options)).not_to be nil
          @xcode_versions_tested << xcode_version
        end

        it 'using 5.1 <= Xcode < 6.0' do
          warn 'WARN:  only testing Xcode 5.1 and Xcode 5.1.1 - need to test 5.0*'
          xcode_installs = Resources.shared.alt_xcode_install_paths '5.1'
          if xcode_installs.empty?
            puts 'INFO: no alternative Xcode versions found in /Xcode directory'
          else
            xcode_installs.each do |xcode_path|
              RunLoop::SimControl.terminate_all_sims
              ENV['DEVELOPER_DIR'] = xcode_path
              xctools = RunLoop::XCTools.new
              xcode_version = xctools.xcode_version
              if @xcode_versions_tested.index { |elm| elm == xcode_version }
                puts "INFO:  skipping xcode version '#{xcode_version}' because we already tested it"
              else
                puts "INFO:  RunLoop.run for xcode version '#{xcode_version}'"
                expect(RunLoop.run(@options)).not_to be nil
                @xcode_versions_tested << xcode_version
              end
            end
          end
        end
      end
    end
  end
end
