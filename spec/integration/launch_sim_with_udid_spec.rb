describe RunLoop do

  before(:each) {
    RunLoop::SimControl.terminate_all_sims
  }

  def random_udid_sdk_8_sim(sim_control)
    candidates = sim_control.simulators.select do |device|
      device.version >= RunLoop::Version.new('8.0')
    end
    candidate = candidates.sample(1).first
    if RunLoop::Environment.debug?
      ap candidate
    end
    candidate.udid
  end

  def random_udid_sdk_7_sim(sim_control)
    sdk_7_sims = sim_control.simulators.select do |device|
      device.version < RunLoop::Version.new('8.0')
    end
    if sdk_7_sims.empty?
      candidate = nil
    else
      candidate = sdk_7_sims.sample(1).first.udid
    end
    if RunLoop::Environment.debug?
      ap candidate
    end
    candidate
  end

  if Resources.shared.current_xcode_version >= RunLoop::Version.new('6.0')
    let (:sim_control) { RunLoop::SimControl.new }
    let (:options) {
      {
            :app => Resources.shared.cal_app_bundle_path,
            :sim_control => sim_control
      }
    }

    before(:each) {
      sim_control.reset_sim_content_and_settings
    }

    describe 'launching on a sim with CoreSimulator UDID' do

      if Resources.shared.current_xcode_version < RunLoop::Version.new('6.2')
        describe 'Xcode < 6.2' do
          it 'works with SDK >= 8.0' do
            udid = random_udid_sdk_8_sim(sim_control)
            options[:device_target] = udid
            Resources.shared.launch_with_options(options) do |hash|
              expect(hash).to be_truthy
            end
          end

          unless Resources.shared.travis_ci?
            it 'works with SDK < 8.0' do
              udid = random_udid_sdk_7_sim(sim_control)
              if udid.nil?
                Luffa.log_warn('No simulators with SDK < 8.0 found; skipping test')
              else
                options[:device_target] = udid
                Resources.shared.launch_with_options(options) do |hash|
                  expect(hash).to be_truthy
                end
              end
            end
          end
        end
      else
        if Resources.shared.current_xcode_version == RunLoop::Version.new('6.2')
          describe 'Xcode >= 6.2' do
            it 'works with SDK > 8.0' do
              udid = random_udid_sdk_8_sim(sim_control)
              options[:device_target] = udid
              expect(launch(options)).to be_truthy
            end

            it 'does not work with SDK < 8.0' do
              udid = random_udid_sdk_7_sim(sim_control)
              if udid.nil?
                Luffa.log_warn('No simulators with SDK < 8.0 found; skipping test')
              else
                options[:device_target] = udid
                expect { launch(options, 1) }.to raise_error(RunLoop::TimeoutError)
              end
            end
          end
        else
          it 'works with SDK > 8.0' do
            udid = random_udid_sdk_8_sim(sim_control)
            options[:device_target] = udid
            Resources.shared.launch_with_options(options) do |hash|
              expect(hash).to be_truthy
            end
          end

          it 'works with SDK < 8.0' do
            udid = random_udid_sdk_7_sim(sim_control)
            if udid.nil?
              Luffa.log_warn('No simulators with SDK < 8.0 found; skipping test')
            else
              options[:device_target] = udid
              Resources.shared.launch_with_options(options) do |hash|
                expect(hash).to be_truthy
              end
            end
          end
        end
      end
    end
  end
end
