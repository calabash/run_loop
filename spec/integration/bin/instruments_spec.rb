require 'run_loop/cli/instruments'

describe RunLoop::CLI::Instruments do

  context 'quit' do
    it 'has help' do
      expect(Luffa.unix_command('bundle exec run-loop instruments help quit',
                                {:exit_on_nonzero_status => false})).to be == 0
    end

    it 'can quit instruments' do
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

      instruments = RunLoop::Instruments.new
      expect(instruments.instruments_pids.count).to be == 1
      expect(Luffa.unix_command('bundle exec run-loop instruments quit',
                                {:exit_on_nonzero_status => false})).to be == 0
    end
  end

  context 'launch' do
    it 'launching an app on default simulator' do
      cmd =
            [
                  'bundle exec run-loop instruments launch',
                  "--app #{Resources.shared.cal_app_bundle_path}"
            ].join(' ')


      expect(Luffa.unix_command(cmd,  {:exit_on_nonzero_status => false})).to be == 0
    end

    it 'launching an app on a different simulator' do
      xcode_version = RunLoop::XCTools.new.xcode_version
      shared = Luffa::Simulator.instance
      simulator = shared.core_simulator_for_xcode_version('iPad',
                                                          'Air',
                                                          xcode_version)
      cmd =
            [
                  'bundle exec run-loop instruments launch',
                  "--app #{Resources.shared.cal_app_bundle_path}",
                  "--device \"#{simulator}\""
            ].join(' ')

      expect(Luffa.unix_command(cmd,  {:exit_on_nonzero_status => false})).to be == 0
    end
  end
end
