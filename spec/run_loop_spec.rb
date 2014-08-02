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
          @sim_control = SimControl.new
          @options = {:launch_retries => 2,
                      :app => Resources.shared.app_bundle_path,
                      :device_target => 'simulator'}
          @sim_control.quit_simulator
        }

        it 'using current version of Xcode' do
          xctools = RunLoop::XCTools.new
          xcode_version = xctools.xcode_version
          puts "INFO: trying to launch Xcode '#{xcode_version}' simulator"

          if xcode_version >= xctools.xc60
            dev_dir =  `xcrun xcode-select --print-path`.chomp
            system "open -a \"#{dev_dir}/Applications/iOS Simulator.app\""
            sleep(2)
          end

          begin
            expect(RunLoop.run(@options)).not_to be nil
            @xcode_versions_tested << xcode_version
          ensure
            @sim_control.quit_simulator
          end
        end

        it 'using 5.1 <= Xcode < 6.0' do
          xcode_installs = Resources.shared.alt_xcode_install_paths '5.1'
          if xcode_installs.empty?
            puts 'INFO: no alternative Xcode versions found in /Xcode directory'
          else
            xcode_installs.each do |xcode_path|
              ENV['DEVELOPER_DIR'] = xcode_path
              xctools = RunLoop::XCTools.new
              xcode_version = xctools.xcode_version
              if @xcode_versions_tested.index { |elm| elm == xcode_version }
                puts "INFO:  skipping xcode version '#{xcode_version}' because we already tested it"
              else
                begin
                  expect(RunLoop.run(@options)).not_to be nil
                  @xcode_versions_tested << xcode_version
                ensure
                  @sim_control.quit_simulator
                end
              end
            end
          end
        end
      end
    end
  end
end
