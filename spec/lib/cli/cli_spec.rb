require 'run_loop/cli/cli'

describe RunLoop::CLI do
  context 'version' do
    subject { capture_stdout { RunLoop::CLI::Tool.new.version }.string.strip }
    it { is_expected.to be == RunLoop::VERSION }
  end

  context 'instruments' do
    subject { capture_stdout { RunLoop::CLI::Tool.new.instruments }.string }
    it 'has help for the launch command' do
      expect(subject[/launch/,0]).to be_truthy
    end

    it 'has help for the quit command' do
      expect(subject[/quit/,0]).to be_truthy
    end
  end
end
