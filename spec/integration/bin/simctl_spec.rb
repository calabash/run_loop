if Resources.shared.core_simulator_env?
  require 'run_loop/cli/simctl'

  describe RunLoop::CLI::Simctl do
    let(:sim_control) { Resources.shared.sim_control }

    let(:xcode) { Resources.shared.xcode }

    let(:app) { RunLoop::App.new(Resources.shared.app_bundle_path) }

    let(:device) do
      default = RunLoop::Core.default_simulator
      device = sim_control.simulators.find do |sim|
        sim.instruments_identifier(xcode) == default
      end
    end

    let(:options) {  { :xcode => xcode } }
    let(:core_sim) { RunLoop::CoreSimulator.new(device, app, options) }

    before do
      allow(RunLoop::Environment).to receive(:debug?).and_return true
      RunLoop::CoreSimulator.quit_simulator
      Resources.shutdown_all_booted
    end

    describe 'run-loop simctl booted' do

      let(:cmd) { 'run-loop simctl booted' }
      let(:args) { cmd.split(' ') }

      before do
        RunLoop.log_unix_cmd(cmd)
      end

      it 'puts message about no booted devices' do
        allow_any_instance_of(RunLoop::SimControl).to receive(:simulators).and_return([])

        hash = CommandRunner.run(args, {:timeout => 10})

        out = hash[:out].chomp
        status = hash[:status]
        expect(status.exitstatus).to be == 0

        expected = "No simulator for active Xcode (version #{xcode.version.to_s}) is booted."
        expect(out).to be == expected

      end

      it 'puts message about the first booted device' do
        core_sim.launch_simulator

        hash = CommandRunner.run(args, {:timeout => 10})

        out = hash[:out].chomp
        status = hash[:status]
        expect(status.exitstatus).to be == 0

        expect(out[/iPhone 5s/, 0]).to be_truthy
        expect(out[/x86_64/, 0]).to be_truthy
      end
    end
  end
end
