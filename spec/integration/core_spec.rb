require 'tmpdir'

describe RunLoop::Core do

  describe '.simulator_target?' do
    if RunLoop::XCTools.new.xcode_version_gte_6?
      describe "named simulator" do

        after(:each) do
          pid = fork do
            local_sim_control = RunLoop::SimControl.new
            simulators = local_sim_control.simulators
            simulators.each do |device|
              if device.name == 'rspec-test-device'
                udid = device.udid
                `xcrun simctl delete #{udid}`
                exit!
              end
            end
          end
          sleep(1)
          Process.kill('QUIT', pid)
        end

        it ":device_target => 'rspec-test-device'" do
          device_type_id = 'iPhone 5s'
          if RunLoop::XCTools.new.xcode_version_gte_61?
            runtime_id = 'com.apple.CoreSimulator.SimRuntime.iOS-8-1'
          else
            runtime_id = 'com.apple.CoreSimulator.SimRuntime.iOS-8-0'
          end
          cmd = "xcrun simctl create rspec-test-device \"#{device_type_id}\" \"#{runtime_id}\""
          udid = `#{cmd}`.strip
          sleep 2
          exit_code = $?.exitstatus
          expect(udid).to_not be == nil
          expect(exit_code).to be == 0
          options = { :device_target => 'rspec-test-device' }
          expect(RunLoop::Core.simulator_target?(options)).to be == true
        end
      end
    end
  end
end
