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
          @resources = Resources.new
          @sim_control = SimControl.new
          @options = {:launch_retries => 2,
                      :app => @resources.app_bundle_path,
                      :device_target => 'simulator'}
          @sim_control.quit_simulator
        }

        it 'using current version of Xcode' do
          xcode_version = RunLoop::Version.new(RunLoop::Core.xcode_version)
          puts "INFO: trying to launch Xcode '#{xcode_version}' simulator"

          if xcode_version >= RunLoop::Version.new('6.0')
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
          xcode_installs = Dir.glob('/Xcode/*/*.app/Contents/Developer').select { |elm| elm =~ /\/Xcode\/(5.1)/ }
          if xcode_installs.empty?
            puts 'INFO: no alternative Xcode versions found in /Xcode directory'
          else
            xcode_installs.each do |xcode_path|
              ENV['DEVELOPER_DIR'] = xcode_path
              xcode_version = RunLoop::Version.new(RunLoop::Core.xcode_version)
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
