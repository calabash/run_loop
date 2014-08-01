describe RunLoop do

  unless travis_ci?
    describe '.run' do
      describe 'launching on simulator' do

        # noinspection RailsParamDefResolve
        before(:context) {
          @xcode_versions_tested = []
        }

        before(:each) {
          @resources = Resources.new
          @sim_control = SimControl.new
          @options = {:launch_retries => 2,
                      :app => @resources.app_bundle_path,
                      :device_target => 'iPhone Retina (4-inch) - Simulator - iOS 7.1'}
          @sim_control.quit_simulator
        }

        it 'can launch current version of xcode' do
          xcode_version = RunLoop::Version.new(RunLoop::Core.xcode_version)
          if xcode_version >= RunLoop::Version.new('5.1') and xcode_version <= RunLoop::Version.new('5.1.1')
            expect(RunLoop.run(@options)).not_to be nil
            begin
              @xcode_versions_tested << xcode_version
            ensure
              @sim_control.quit_simulator
            end
          else
            pending "found Xcode version '#{xcode_version}' which we cannot test yet"
          end
        end

        it 'launches apps on simulator for 5.1 <= Xcode < 6.0' do
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


  # context 'when targeting an iOS 8 device' do
  #   it 'should be able to launch' do
  #     ENV['DEBUG'] = '1'
  #     ENV['DEBUG_READ'] = '1'
  #     options = { :bundle_id => 'com.lesspainful.example.LPSimpleExample-cal',
  #                 :launch_retries => 2,
  #                 :udid => '89b59706a3ac25e997770a91577ef4e6ad0ab7ba',
  #                 :device_target => '89b59706a3ac25e997770a91577ef4e6ad0ab7ba',
  #                 :app => 'com.lesspainful.example.LPSimpleExample-cal'}
  #     expect(RunLoop.run(options)).not_to be nil
  #   end
  # end

  # context 'when targeting the simulator' do
  #
  #   before :each do
  #     @sim_tools = RunLoop::SimTools.new
  #     @sim_tools.enable_accessibility_on_simulators
  #   end
  #
  #   it 'should be able to launch' do
  #     options = {:launch_retries => 3,
  #                :app => app_bundle_path,
  #                :device_target => 'iPhone Retina (4-inch) - Simulator - iOS 7.1'}
  #     expect(RunLoop.run(options)).not_to be nil
  #   end
  # end
end
