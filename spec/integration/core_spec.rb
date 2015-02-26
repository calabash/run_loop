require 'tmpdir'

describe RunLoop::Core do

  before(:each) { ENV.delete('TRACE_TEMPLATE') }

  describe '.automation_template' do

    after(:each) { ENV.delete('TRACE_TEMPLATE') }

    it 'ignores the TRACE_TEMPLATE env var if the tracetemplate does not exist' do
      tracetemplate = '/tmp/some.tracetemplate'
      ENV['TRACE_TEMPLATE']=tracetemplate
      xctools = RunLoop::XCTools.new
      actual = RunLoop::Core.automation_template(xctools)
      expect(actual).not_to be == nil
      expect(actual).not_to be == tracetemplate
      if xctools.xcode_version_gte_6?
        expect(actual).to be == 'Automation'
      else
        expect(File.exist?(actual)).to be == true
      end
    end
  end

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

  describe '.default_tracetemplate' do
    describe 'returns a template for' do
      it "Xcode #{Resources.shared.current_xcode_version}" do
        xctools = RunLoop::XCTools.new
        default_template = RunLoop::Core.default_tracetemplate(xctools)
        if xctools.xcode_version_gte_6?
          if xctools.xcode_is_beta?
            expect(File.exist?(default_template)).to be true
          else
            expect(default_template).to be == 'Automation'
          end
        else
          expect(File.exist?(default_template)).to be true
        end
      end

      describe 'regression' do
        xcode_installs = Resources.shared.alt_xcode_details_hash
        if xcode_installs.empty?
          it 'no alternative versions of Xcode found' do
            expect(true).to be == true
          end
        else
          xcode_installs.each do |xcode_details|
            it "#{xcode_details[:path]} - #{xcode_details[:version]}" do
              Resources.shared.with_developer_dir(xcode_details[:path]) {
                xctools = RunLoop::XCTools.new
                default_template = RunLoop::Core.default_tracetemplate(xctools)
                if xctools.xcode_version_gte_6?
                  if xctools.xcode_is_beta?
                    expect(File.exist?(default_template)).to be true
                  else
                    expect(default_template).to be == 'Automation'
                  end
                else
                  expect(File.exist?(default_template)).to be true
                end
              }
            end
          end
        end
      end
    end
  end
end
