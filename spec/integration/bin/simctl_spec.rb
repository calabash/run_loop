unless Luffa::Environment.travis_ci?
  require 'run_loop/cli/simctl'

  describe RunLoop::CLI::Simctl do

    describe 'bundle exec run-loop simctl booted' do
      let(:bridge) {
        default = RunLoop::Core.default_simulator
        device = RunLoop::SimControl.new.simulators.detect do |sim|
          sim.instruments_identifier == default
        end
        RunLoop::Simctl::Bridge.new(device, Resources.shared.app_bundle_path)
      }

      let(:cmd) { 'bundle exec run-loop simctl booted' }

      before {
        bridge.shutdown
      }

      it 'puts message about no booted devices' do
        allow_any_instance_of(RunLoop::SimControl).to receive(:simulators).and_return([])
        args = cmd.split(' ')
        Open3.popen3(args.shift, *args) do |_, stdout, _, process_status|
          out = stdout.read.strip
          expect(out).to be == 'No simulator is booted.'
          expect(process_status.value.exitstatus).to be == 0
        end
      end

      it 'puts message about the first booted device' do
        bridge.boot
        args = cmd.split(' ')
        Open3.popen3(args.shift, *args) do |_, stdout, _, process_status|
          out = stdout.read.strip
          expect(out[/iPhone 5s/, 0]).to be_truthy
          expect(out[/x86_64/, 0]).to be_truthy
          expect(process_status.value.exitstatus).to be == 0
        end
      end
    end
  end
end
