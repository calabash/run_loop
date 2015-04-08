require 'thor'
require 'run_loop'
require 'run_loop/cli/errors'
require 'run_loop/cli/instruments'

trap 'SIGINT' do
  puts 'Trapped SIGINT - exiting'
  exit 10
end

module RunLoop

  module CLI

    class Tool < Thor
      include Thor::Actions

      def self.exit_on_failure?
        true
      end

      desc 'version', 'Prints version of the run_loop gem'
      def version
        puts RunLoop::VERSION
      end

      desc 'instruments', "Interact with Xcode's command-line instruments"
      subcommand 'instruments', RunLoop::CLI::Instruments

    end
  end
end
