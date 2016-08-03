describe RunLoop::CoreSimulator do
  let(:simulator) do
    Resources.shared.simctl.simulators.sample
  end

  let(:app) { RunLoop::App.new(Resources.shared.cal_app_bundle_path) }
  let(:xcrun) { RunLoop::Xcrun.new }

  let(:core_sim) do
    RunLoop::CoreSimulator.new(simulator, app)
  end

  before do
    allow(RunLoop::Environment).to receive(:debug?).and_return true
  end

  after do
    RunLoop::CoreSimulator.terminate_core_simulator_processes
    sleep(2)
  end

  describe ".erase" do
    it "can quit, shutdown, and erase a simulator" do
      core_sim.launch_simulator

      expect(RunLoop::CoreSimulator.erase(simulator)).to be_truthy
    end

    it "can shutdown and erase a simulator" do
      expect(RunLoop::CoreSimulator.erase(simulator)).to be_truthy
    end

  end

  describe '#launch_simulator' do
    it 'can launch the simulator' do
      expect(core_sim.launch_simulator).to be_truthy

      pid = RunLoop::CoreSimulator.simulator_pid
      running = core_sim.send(:running_simulator_pid)

      expect(pid).to be == running
    end

    it 'does not relaunch if the simulator is already running' do
      core_sim.launch_simulator

      expect(Process).not_to receive(:spawn)

      core_sim.launch_simulator

      pid = RunLoop::CoreSimulator.simulator_pid
      running = core_sim.send(:running_simulator_pid)

      expect(pid).to be == running
    end

    it 'quits the simulator if it is not the same' do
      core_sim.launch_simulator

      running = core_sim.send(:running_simulator_pid)
      RunLoop::CoreSimulator.class_variable_set(:@@simulator_pid, running - 1)

      expect(Process).to receive(:spawn).and_call_original

      core_sim.launch_simulator

      pid = RunLoop::CoreSimulator.simulator_pid
      running = core_sim.send(:running_simulator_pid)
      expect(pid).to be == running
    end
  end

  describe "#launch" do
    before do
      Resources.shared.simctl.erase(simulator)
    end

    it "launches the app" do
      expect(core_sim.launch).to be_truthy
    end

    it "launches the app even if it is already installed" do
      expect(core_sim.launch).to be_truthy

      RunLoop::CoreSimulator.quit_simulator

      expect(core_sim.launch).to be_truthy

      pid = RunLoop::CoreSimulator.simulator_pid
      running = core_sim.send(:running_simulator_pid)
      expect(pid).to be == running
    end
  end

  it "retries app launching" do
    tries = RunLoop::CoreSimulator::DEFAULT_OPTIONS[:app_launch_retries] - 1
    error = RunLoop::Xcrun::TimeoutError.new("Xcrun timed out")
    expect(core_sim).to receive(:launch_app_with_simctl).exactly(tries).times.and_raise(error)
    expect(core_sim).to receive(:launch_app_with_simctl).and_call_original

    expect(core_sim.launch).to be == true
  end

  it 'install with simctl' do
    RunLoop::CoreSimulator.erase(simulator)
    expect(core_sim.install).to be_truthy
    expect(core_sim.launch).to be_truthy
  end

  it 'uninstall app and sandbox with simctl' do
    expect(core_sim.uninstall_app_and_sandbox)
    expect(core_sim.app_is_installed?).to be_falsey
  end

  it ".set_locale" do
    actual = RunLoop::CoreSimulator.set_locale(simulator, "en")
    expect(actual.name).to be == "English"
    expect(actual.code).to be == "en"
  end

  it ".set_language" do
    actual = RunLoop::CoreSimulator.set_language(simulator, "en")
    expect(actual.first).to be == "en"
  end
end

