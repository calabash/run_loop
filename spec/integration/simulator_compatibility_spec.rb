describe "Simulator/Binary Compatibility Check" do

  let(:simctl) { Resources.shared.simctl }

  before do
    allow(RunLoop::Environment).to receive(:debug?).and_return(true)
    RunLoop::CoreSimulator.quit_simulator
  end

  it "can launch if app has i386 and x86_64 slices" do
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

  it "can launch i386 app on x86_64 simulator"  do
    ios_version = (Resources.shared.xcode.version.major + 2) * 1.0
    air = simctl.simulators.find do |device|
      device.name == "iPad Air" &&
        device.version >= RunLoop::Version.new(ios_version.to_s)
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

  it "raises an error if app is for arm but target is simulator" do
    options =
      {
        :app => Resources.shared.app_bundle_path_arm_FAT,
        :device_target => 'simulator',
        :simctl => simctl
      }

    expect do
      RunLoop.run(options)
    end.to raise_error RunLoop::IncompatibleArchitecture
  end

  it "raises an error if app contains only x86_64 slices but simulator is i386" do
    i368sim = simctl.simulators.find do |device|
      device.instruction_set == 'i386' && device.version >= RunLoop::Version.new('9.0')
    end

    expect(i368sim).not_to be == nil
    RunLoop::CoreSimulator.erase(i368sim)
    options =
      {
        :app => Resources.shared.app_bundle_path_x86_64,
        :device_target => i368sim.udid,
        :simctl => simctl
      }

    expect do
      RunLoop.run(options)
    end.to raise_error RunLoop::IncompatibleArchitecture
  end
end
