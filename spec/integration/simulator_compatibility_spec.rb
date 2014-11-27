describe 'Simulator/Binary Compatibility Check' do

  let(:sim_control) {
    obj = RunLoop::SimControl.new
    obj.reset_sim_content_and_settings
    obj
  }

  describe 'can launch if library is FAT' do
    it 'can launch if libraries are compatible' do
      sim_control = RunLoop::SimControl.new
      sim_control.reset_sim_content_and_settings

      options =
            {
                  :app => Resources.shared.cal_app_bundle_path,
                  :device_target => 'simulator',
                  :sim_control => sim_control
            }

      hash = nil
      Retriable.retriable({:tries => Resources.shared.launch_retries}) do
        hash = RunLoop.run(options)
      end
      expect(hash).not_to be nil
    end

    it 'targeting x86_64 simulator with binary that contains only a i386 slice' do
      # The latest iPad Air
      air = sim_control.simulators.select do |device|
        device.name == 'iPad Air'
      end[-1]

      expect(air).not_to be == nil
      options =
            {
                  :app => Resources.shared.app_bundle_path_i386,
                  :device_target => air.instruments_identifier,
                  :sim_control => sim_control
            }

      hash = nil
      Retriable.retriable({:tries => Resources.shared.launch_retries}) do
        hash = RunLoop.run(options)
      end
      expect(hash).not_to be nil
    end
  end

  describe 'raises an error if libraries are not compatible' do
    it 'target only has arm slices' do
      options =
            {
                  :app => Resources.shared.app_bundle_path_arm_FAT,
                  :device_target => 'simulator',
                  :sim_control => sim_control
            }

      expect {  RunLoop.run(options) }.to raise_error RunLoop::IncompatibleArchitecture
    end

    if RunLoop::XCTools.new.xcode_version_gte_6?
      it 'targeting i386 simulator with binary that contains only a x86_64 slice' do
        # The latest iPad 2; will eventually fail when the iPad 2 is no longer supported. :(
         ipad2 = sim_control.simulators.select do |device|
          device.name == 'iPad 2'
        end[-1]

        expect(ipad2).not_to be == nil
        options =
              {
                    :app => Resources.shared.app_bundle_path_x86_64,
                    :device_target => ipad2.instruments_identifier,
                    :sim_control => sim_control
              }

        expect {  RunLoop.run(options) }.to raise_error RunLoop::IncompatibleArchitecture
      end
    end
  end
end
