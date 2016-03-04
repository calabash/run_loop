require 'thor'
require 'run_loop'
require 'run_loop/cli/errors'
require 'run_loop/cli/instruments'
require 'run_loop/cli/simctl'
require "run_loop/cli/locale"
require "run_loop/cli/codesign"
require "run_loop/cli/tcc"

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

      desc "simctl", "Interact with Xcode's command-line simctl"
      subcommand "simctl", RunLoop::CLI::Simctl

      desc "locale", "Tools for interacting with locales"
      subcommand "locale", RunLoop::CLI::Locale

      desc "codesign", "Tools for interacting with codesign"
      subcommand "codesign", RunLoop::CLI::Codesign

      desc "tcc", "Tools for interacting with simulator privacy settings"
      subcommand "tcc", RunLoop::CLI::TCC

    end
  end
end
