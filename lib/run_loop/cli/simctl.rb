require 'thor'
require 'run_loop'
require 'run_loop/cli/errors'

module RunLoop
  module CLI
    class Simctl < Thor

      attr_reader :sim_control

      desc 'tail', 'Tail the log file of the booted simulator'
      def tail
        tail_booted
      end

      desc 'booted', 'Prints details about the booted simulator'
      def booted
        puts booted_device
      end

      no_commands do

        def sim_control
          @sim_control ||= RunLoop::SimControl.new
        end

        def booted_device
          ifnone = lambda {
            puts 'No simulators are booted'
          }
          sim_control.simulators.detect(ifnone) do |device|
            device.state == 'Booted'
          end
        end

        def tail_booted
          device = booted_device
          log_file = device.simulator_log_file_path
          exec('tail', *['-F', log_file])
        end
      end
    end
  end
end
