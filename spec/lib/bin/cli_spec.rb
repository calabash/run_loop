require 'run_loop/cli/cli'

describe RunLoop::CLI do
  context 'version' do
    subject { capture_stdout { RunLoop::CLI.new.version }.string.strip }
    it { is_expected.to be == RunLoop::VERSION }
  end
end
