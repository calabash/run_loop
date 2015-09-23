if Resources.shared.core_simulator_env?
  describe 'Simulator/Binary Compatibility Check' do

    before do
      RunLoop::SimControl.terminate_all_sims
    end

    describe 'can launch if library is FAT' do

      let(:sim_control) {
        obj = RunLoop::SimControl.new
        obj.reset_sim_content_and_settings
        obj
      }

      it 'can launch if libraries are compatible' do
        options =
              {
                    :app => Resources.shared.cal_app_bundle_path,
                    :device_target => 'simulator',
                    :sim_control => sim_control
              }

        Resources.shared.launch_with_options(options) do |hash|
          expect(hash).not_to be nil
        end
      end

      it 'targeting x86_64 simulator with binary that contains only a i386 slice' do
        # The latest iPad Air
        air = sim_control.simulators.find do |device|
          device.name == 'iPad Air' &&
                device.version > RunLoop::Version.new('7.1')
        end

        expect(air).not_to be == nil
        options =
              {
                    :app => Resources.shared.app_bundle_path_i386,
                    :device_target => air.instruments_identifier(sim_control.xcode),
                    :sim_control => sim_control
              }

        Resources.shared.launch_with_options(options) do |hash|
          expect(hash).not_to be nil
        end
      end
    end

    describe 'raises an error if libraries are not compatible' do

      let(:sim_control) { RunLoop::SimControl.new }

      it 'target only has arm slices' do
        options =
              {
                    :app => Resources.shared.app_bundle_path_arm_FAT,
                    :device_target => 'simulator',
                    :sim_control => sim_control
              }

        expect { RunLoop.run(options) }.to raise_error RunLoop::IncompatibleArchitecture
      end

      if Resources.shared.core_simulator_env?
        it 'targeting i386 simulator with binary that contains only a x86_64 slice' do
          # The latest iPad 2; will eventually fail when the iPad 2 is no longer supported. :(
          ipad2 = sim_control.simulators.find do |device|
            device.name == 'iPad 2' &&
                  device.version > RunLoop::Version.new('7.1')
          end

          expect(ipad2).not_to be == nil
          options =
                {
                      :app => Resources.shared.app_bundle_path_x86_64,
                      :device_target => ipad2.instruments_identifier(sim_control.xcode),
                      :sim_control => sim_control
                }

          expect { RunLoop.run(options) }.to raise_error RunLoop::IncompatibleArchitecture
        end
      end
    end
  end
end
