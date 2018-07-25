require 'run_loop/cli/instruments'

describe RunLoop::CLI::Instruments do

  before do
    allow(RunLoop::Environment).to receive(:debug?).and_return true
  end

  if Resources.shared.xcode.version_gte_8?
    context "Xcode >= 8.0" do
      it "instruments cli is not supported for Xcode 8" do

      end
    end
  else
    context "Xcode < 8.0" do

      context 'quit' do
        it 'has help' do
          expect(Luffa.unix_command('run-loop instruments help quit',
                                    {:exit_on_nonzero_status => false})).to be == 0
        end

        it "can quit instruments" do
          simctl = Resources.shared.simctl
          options =
            {
              :app => Resources.shared.cal_app_bundle_path,
              :device_target => 'simulator',
              :simctl => simctl
            }

          hash = Resources.shared.launch_with_options(options)

          expect(hash).not_to be nil

          instruments = RunLoop::Instruments.new
          expect(instruments.instruments_pids.count).to be == 1
          expect(Luffa.unix_command('run-loop instruments quit',
                                    {:exit_on_nonzero_status => false})).to be == 0
        end
      end
    end
  end
end
