require 'tmpdir'

describe RunLoop::Core do

  describe '.automation_template' do

    it 'ignores the TRACE_TEMPLATE env var if the tracetemplate does not exist' do
      tracetemplate = '/tmp/some.tracetemplate'
      expect(RunLoop::Environment).to receive(:trace_template).and_return(tracetemplate)
      instruments = Resources.shared.instruments
      xcode = Resources.shared.xcode

      actual = RunLoop::Core.automation_template(instruments)
      expect(actual).not_to be == nil
      expect(actual).not_to be == tracetemplate
      if xcode.version_gte_6?
        if xcode.beta?
          expect(actual[/Automation.tracetemplate/, 0]).to be_truthy
        else
          expect(actual).to be == 'Automation'
        end

      else
        expect(File.exist?(actual)).to be == true
      end
    end
  end

  describe '.simulator_target?' do
    if Resources.shared.core_simulator_env?
      describe "named simulator" do

        after(:each) do
          pid = fork do
            local_sim_control = Resources.shared.sim_control
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
          xcode = Resources.shared.xcode
          if xcode.version < xcode.v64
            Luffa.log_warn("Skipping test: Xcode < 6.4 detected (#{version.to_s}")
          else

            device_type_id = 'iPhone 5s'

            if xcode.version_gte_71?
              runtime_id = 'com.apple.CoreSimulator.SimRuntime.iOS-9-1'
            elsif xcode.version_gte_7?
              runtime_id = 'com.apple.CoreSimulator.SimRuntime.iOS-9-0'
            else
              runtime_id = 'com.apple.CoreSimulator.SimRuntime.iOS-8-4'
            end
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
      xcode = Resources.shared.xcode

      it "Xcode #{xcode.version}" do
        instruments = Resources.shared.instruments
        default_template = RunLoop::Core.default_tracetemplate(instruments)
        if xcode.version_gte_6?
          if xcode.beta?
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
                instruments = RunLoop::Instruments.new
                default_template = RunLoop::Core.default_tracetemplate(instruments)
                internal_xcode = RunLoop::Xcode.new
                if internal_xcode.version_gte_6?
                  if internal_xcode.beta?
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
