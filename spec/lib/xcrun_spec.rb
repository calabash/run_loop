# encoding: utf-8

describe RunLoop::Xcrun do

  let(:xcrun) { RunLoop::Xcrun.new }

  let(:process_status) do
    # It is not possible call Process::Status.new
    `echo`
    $?
  end

  let(:command_output) do
    {
          :out => '',
          :status => process_status
    }
  end

  describe '#run_command_in_context' do

    it "is aliased to #exec" do
      expect(xcrun.respond_to?(:exec)).to be_truthy
    end

    it 'raises an error if arg is not an Array' do
      expect do
        xcrun.run_command_in_context('simctl list devices')
      end.to raise_error ArgumentError, /Expected args/
    end

    it 'raises an error if any arg is not a string' do
      expect do
        xcrun.run_command_in_context(['sleep', 5])
      end.to raise_error ArgumentError,
      /Expected arg '5' to be a String, but found 'Fixnum'/
    end

    it "re-raises error if UTF8 encoding fails" do
      error = RunLoop::Encoding::UTF8Error.new("complex message")
      expect(xcrun).to receive(:ensure_command_output_utf8).and_raise(error)

      expect do
        xcrun.run_command_in_context(["sleep", "0.5"])
      end.to raise_error RunLoop::Encoding::UTF8Error, /complex message/
    end

    it 're-raises error thrown by CommandRunner' do
      expect(CommandRunner).to receive(:run).and_raise RuntimeError, 'Some error'

      expect do
        xcrun.run_command_in_context(['sleep', '0.5'])
      end.to raise_error RunLoop::Xcrun::Error, /Some error/
    end

    describe 'raises timeout error if CommandRunner timed out' do
      it 'mocked' do
        expect(process_status).to receive(:exitstatus).and_return(nil)
        expect(CommandRunner).to receive(:run).and_return(command_output)

        expect do
          xcrun.run_command_in_context(['sleep', '0.5'])
        end.to raise_error RunLoop::Xcrun::TimeoutError, /Xcrun timed out after/
      end

      it 'actual' do
        expect do
          xcrun.run_command_in_context(['sleep', '0.5'], timeout: 0.05)
        end.to raise_error RunLoop::Xcrun::TimeoutError, /Xcrun timed out after/
      end
    end


    describe 'contents of returned hash' do
      it 'mocked' do
        expect(process_status).to receive(:exitstatus).and_return(256)
        expect(process_status).to receive(:pid).and_return(3030)
        command_output[:out] = 'mocked'
        expect(CommandRunner).to receive(:run).and_return(command_output)

        xcrun_hash = xcrun.run_command_in_context(['sleep', '0.1'])

        expect(xcrun_hash[:out]).to be == 'mocked'
        expect(xcrun_hash[:pid]).to be == 3030
        expect(xcrun_hash[:exit_status]).to be == 256
      end
    end
  end
end

