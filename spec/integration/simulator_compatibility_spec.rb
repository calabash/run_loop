describe 'Simulator/Binary Compatibility Check' do

  let(:simctl) { Resources.shared.simctl }

  before do
    RunLoop::CoreSimulator.quit_simulator
  end

  describe 'can launch if library is FAT' do

    it 'can launch if libraries are compatible' do
      options =
        {
          :app => Resources.shared.cal_app_bundle_path,
          :device_target => 'simulator',
          :simctl => simctl
        }
      Resources.shared.launch_with_options(options) do |hash|
        expect(hash).not_to be nil
      end
    end

    it 'targeting x86_64 simulator with binary that contains only a i386 slice' do
      # The latest iPad Air
      air = simctl.simulators.find do |device|
        device.name == 'iPad Air' &&
          device.version > RunLoop::Version.new('7.1')
      end

      expect(air).not_to be == nil
      RunLoop::CoreSimulator.erase(air)

      options =
        {
          :app => Resources.shared.app_bundle_path_i386,
          :device_target => air.udid,
          :simctl => simctl
        }

      Resources.shared.launch_with_options(options) do |hash|
        expect(hash).not_to be nil
      end
    end
  end

  describe 'raises an error if libraries are not compatible' do

    it 'target only has arm slices' do
      options =
        {
          :app => Resources.shared.app_bundle_path_arm_FAT,
          :device_target => 'simulator',
          :simctl => simctl
        }

      expect { RunLoop.run(options) }.to raise_error RunLoop::IncompatibleArchitecture
    end

    it 'targeting i386 simulator with binary that contains only a x86_64 slice' do
      # The latest iPad 2
      ipad2 = simctl.simulators.find do |device|
        device.name == 'iPad 2' &&
          device.version > RunLoop::Version.new('7.1')
      end

      expect(ipad2).not_to be == nil
      RunLoop::CoreSimulator.erase(ipad2)
      options =
        {
          :app => Resources.shared.app_bundle_path_x86_64,
          :device_target => ipad2.udid,
          :simctl => simctl
        }

      expect { RunLoop.run(options) }.to raise_error RunLoop::IncompatibleArchitecture
    end
  end
end
