describe RunLoop::CoreSimulator do
  let(:simulator) { Resources.shared.default_simulator }

  let(:app) { RunLoop::App.new(Resources.shared.cal_app_bundle_path) }
  let(:xcrun) { RunLoop::Xcrun.new }

  let(:core_sim) do
    RunLoop::CoreSimulator.new(simulator, app)
  end

  before do
    RunLoop::CoreSimulator.quit_simulator
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
      plist = simulator.simulator_device_plist
      expect(File.exist?(plist)).to be_truthy
    end

    it "can shutdown and erase a simulator" do
      expect(RunLoop::CoreSimulator.erase(simulator)).to be_truthy
      plist = simulator.simulator_device_plist
      expect(File.exist?(plist)).to be_truthy
    end
  end

  describe '#launch_simulator' do
    it 'can launch the simulator' do
      expect(core_sim.launch_simulator).to be_truthy

      pid = core_sim.send(:running_simulator_details)[:pid]

      expect(pid).to be_truthy
    end

    it 'does not relaunch if the simulator is already running' do
      core_sim.launch_simulator

      pid = core_sim.send(:running_simulator_details)[:pid]
      expect(Process).not_to receive(:spawn)

      core_sim.launch_simulator

      expect(core_sim.send(:running_simulator_details)[:pid]).to be == pid
    end

    it 'quits the simulator if it is not the same' do
      core_sim.launch_simulator

      expect(core_sim).to receive(:running_simulator_details).and_return({:pid => 1})
      expect(Process).to receive(:spawn).and_call_original

      core_sim.launch_simulator
    end
  end

  describe "#launch" do
    before do
      opts = RunLoop::CoreSimulator::DEFAULT_OPTIONS
      Resources.shared.simctl.erase(simulator,
                                    opts[:launch_app_timeout],
                                    opts[:wait_for_state_timeout])
    end

    it "launches the app" do
      expect(core_sim.launch).to be_truthy
    end

    it "launches the app even if it is already installed" do
      expect(core_sim.launch).to be_truthy

      RunLoop::CoreSimulator.quit_simulator

      expect(core_sim.launch).to be_truthy
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
    RunLoop::CoreSimulator.erase(simulator)
    actual = RunLoop::CoreSimulator.set_language(simulator, "en")
    expect(actual.first).to be == "en"

    actual = RunLoop::CoreSimulator.set_language(simulator, "de")
    expect(actual.first).to be == "de"
  end

  context ".app_installed?" do
    it "returns true if app is installed" do
      actual = RunLoop::CoreSimulator.app_installed?(simulator, "com.apple.Preferences")
      expect(actual).to be_truthy
    end

    it "returns false if app is not installed" do
      actual = RunLoop::CoreSimulator.app_installed?(simulator, "com.example.Preferences")
      expect(actual).to be_falsey
    end
  end

  context "#simulator_state_requires_relaunch?" do
    let (:sim_details) { {} }

    before do
      RunLoop::CoreSimulator.quit_simulator
    end

    it "returns true if the simulator is not running" do
      RunLoop::CoreSimulator.quit_simulator
      expect(core_sim.send(:simulator_state_requires_relaunch?)).to be_truthy
    end

    it "returns true if the simulator was not launched by run_loop" do
      args = ['open', '-g', '-a', core_sim.send(:sim_app_path)]
      pid = Process.spawn('xcrun', *args)
      Process.detach(pid)

      options = { :timeout => 5, :raise_on_timeout => true }
      RunLoop::ProcessWaiter.new(core_sim.send(:sim_name), options).wait_for_any

      core_sim.device.simulator_wait_for_stable_state

      expect(core_sim.send(:simulator_state_requires_relaunch?)).to be_truthy
    end
  end
end
