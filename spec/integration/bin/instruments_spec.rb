require 'run_loop/cli/instruments'

describe RunLoop::CLI::Instruments do

  context 'quit' do
    it 'has help' do
      expect(Luffa.unix_command('run-loop instruments help quit',
                                {:exit_on_nonzero_status => false})).to be == 0
    end

    it 'can quit instruments' do
      sim_control = RunLoop::SimControl.new
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
      expect(Luffa.unix_command('run-loop instruments quit',
                                {:exit_on_nonzero_status => false})).to be == 0
    end
  end

  context 'launch' do
    it 'launching an app on default simulator' do
      cmd =
            [
                  'run-loop instruments launch',
                  "--app #{Resources.shared.cal_app_bundle_path}"
            ].join(' ')


      expect(Luffa.unix_command(cmd,  {:exit_on_nonzero_status => false})).to be == 0
    end

    describe 'launching different simulators' do
      let(:instruments) { RunLoop::Instruments.new }
      let(:xcode) { instruments.xcode }

      it 'iOS >= 9' do

        sampled = instruments.simulators.select do |device|
          device.version >= RunLoop::Version.new('9.0')
        end.sample

        if sampled.nil?
          Luffa.log_warn("Skipping test: no iOS Simulators >= 8.0 found")
        else
          simulator = sampled.instruments_identifier(xcode)
          cmd =
                [
                      'run-loop instruments launch',
                      "--app #{Resources.shared.cal_app_bundle_path}",
                      "--device \"#{simulator}\""
                ].join(' ')

          expect(Luffa.unix_command(cmd,  {:exit_on_nonzero_status => false})).to be == 0
        end
      end


      it '8.0 <= iOS < 9.0' do

        sampled = instruments.simulators.select do |device|
          device.version >= RunLoop::Version.new('8.0') &&
                device.version < RunLoop::Version.new('9.0') &&
                device.name[/Resizable/, 0].nil?
        end.sample

        if sampled.nil?
          Luffa.log_warn("Skipping test: no 8.0 <= iOS Simulators < 9.0 found")
        else
          simulator = sampled.instruments_identifier(xcode)
          cmd =
                [
                      'run-loop instruments launch',
                      "--app #{Resources.shared.cal_app_bundle_path}",
                      "--device \"#{simulator}\""
                ].join(' ')

          expect(Luffa.unix_command(cmd,  {:exit_on_nonzero_status => false})).to be == 0
        end
      end

      it '7.1 <= iOS < 8.0' do
        sampled = instruments.simulators.select do |device|
          device.version == RunLoop::Version.new('7.1')
        end.sample

        if sampled.nil?
          Luffa.log_warn("Skipping test: no 7.1 <= iOS Simulators < 8.0 found")
        else
          simulator = sampled.instruments_identifier(xcode)
          cmd =
                [
                      'run-loop instruments launch',
                      "--app #{Resources.shared.cal_app_bundle_path}",
                      "--device \"#{simulator}\""
                ].join(' ')

          expect(Luffa.unix_command(cmd,  {:exit_on_nonzero_status => false})).to be == 0
        end
      end

      it '7.0.3' do
        Luffa.log_warn("Skipping iOS 7.0.3 Simulators because they are not supported on Yosemite")
      end
    end
  end
end
