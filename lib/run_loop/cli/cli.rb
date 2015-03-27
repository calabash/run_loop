require 'thor'
require 'run_loop'

trap 'SIGINT' do
  puts 'Trapped SIGINT - exiting'
  exit 10
end

module RunLoop

  class ValidationError < Thor::InvocationError
  end

  class CLI < Thor
    include Thor::Actions

    def self.exit_on_failure?
      true
    end

    desc 'version', 'Prints version of the run_loop gem'
    def version
      puts RunLoop::VERSION
    end
  end
end
