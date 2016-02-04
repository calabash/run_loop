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

  describe '#exec' do
    it 'raises an error if arg is not an Array' do
      expect do
        xcrun.exec('simctl list devices')
      end.to raise_error ArgumentError, /Expected args/
    end

    it 'raises an error if any arg is not a string' do
      expect do
        xcrun.exec(['sleep', 5])
      end.to raise_error ArgumentError,
      /Expected arg '5' to be a String, but found 'Fixnum'/
    end

    it 're-raises error thrown by CommandRunner' do
      expect(CommandRunner).to receive(:run).and_raise RuntimeError, 'Some error'

      expect do
        xcrun.exec(['sleep', '0.5'])
      end.to raise_error RunLoop::Xcrun::Error, /Some error/
    end

    describe 'raises timeout error if CommandRunner timed out' do
      it 'mocked' do
        expect(process_status).to receive(:exitstatus).and_return(nil)
        expect(CommandRunner).to receive(:run).and_return(command_output)

        expect do
          xcrun.exec(['sleep', '0.5'])
        end.to raise_error RunLoop::Xcrun::TimeoutError, /Xcrun timed out after/
      end

      it 'actual' do
        expect do
          xcrun.exec(['sleep', '0.5'], timeout: 0.05)
        end.to raise_error RunLoop::Xcrun::TimeoutError, /Xcrun timed out after/
      end
    end

    describe "#encode_utf8_or_raise" do
      let(:string) { "string" }
      let(:encoded) { "encoded" }
      let(:forced) { "forced" }
      let(:command) { "command" }

      it "returns '' if string arg is falsey" do
        expect(xcrun.send(:encode_utf8_or_raise, nil, command)).to be == ''
      end

      it "returns utf8 encoding" do
        expect(string).to receive(:force_encoding).with("UTF-8").and_return(encoded)
        expect(encoded).to receive(:chomp).and_return(encoded)
        expect(encoded).to receive(:valid_encoding?).and_return(true)

        expect(xcrun.send(:encode_utf8_or_raise, string, command)).to be == encoded
      end

      it "forces utf8 encoding" do
        expect(string).to receive(:force_encoding).with("UTF-8").and_return(encoded)
        expect(encoded).to receive(:chomp).and_return(encoded)
        expect(encoded).to receive(:valid_encoding?).and_return(false)
        expect(encoded).to receive(:encode).and_return(forced)
        expect(forced).to receive(:valid_encoding?).and_return(true)

        expect(xcrun.send(:encode_utf8_or_raise, string, command)).to be == forced
      end

      it "raises an error if string cannot be coerced to UTF8" do
        expect(string).to receive(:force_encoding).with("UTF-8").and_return(encoded)
        expect(encoded).to receive(:chomp).and_return(encoded)
        expect(encoded).to receive(:valid_encoding?).and_return(false)
        expect(encoded).to receive(:encode).and_return(forced)
        expect(forced).to receive(:valid_encoding?).and_return(false)

        expect do
          xcrun.send(:encode_utf8_or_raise, string, command)
        end.to raise_error RunLoop::Xcrun::UTF8Error,
        /Could not force UTF-8 encoding on this string:/
      end

      describe "integration" do
        it "handles string with non-UTF8 characters" do
          file = "spec/resources/ps-with-non-utf8.log"
          string = File.read(file)

          actual = xcrun.send(:encode_utf8_or_raise, string, command)
          split = actual.split($-0)

          expect(split[0]).to be == "  PID COMMAND"
          expect(split[1]).to be == "  324 /usr/libexec/UserEventAgent (Aqua)"
          expect(split[2]).to be == "  403 /Applications/M^\\M^IM^AM^SM^MM^E.app/Contents/MacOS/M^\\M^IM^AM^SM^MM^E"
          expect(split[3]).to be == " 1497 irb"
        end

        it "handles UTF-8 strings" do
          # Force C (non UTF-8 encoding)
          stub_env({'LC_ALL' => 'C'})
          args = ['cat', 'spec/resources/encoding.txt']

          # Confirm that the string is read as ASCII-US8BIT
          command_runner_hash = CommandRunner.run(args, timeout: 0.2)
          command_runner_out = command_runner_hash[:out]
          expect(command_runner_out.length).to be == 22

          actual = xcrun.send(:encode_utf8_or_raise, command_runner_out, command)
          expect(actual).to be == 'ITZVÓÃ ●℆❡♡'
        end
      end
    end

    describe 'contents of returned hash' do
      it 'mocked' do
        expect(process_status).to receive(:exitstatus).and_return(256)
        expect(process_status).to receive(:pid).and_return(3030)
        command_output[:out] = 'mocked'
        expect(CommandRunner).to receive(:run).and_return(command_output)

        xcrun_hash = xcrun.exec(['sleep', '0.1'])

        expect(xcrun_hash[:out]).to be == 'mocked'
        expect(xcrun_hash[:pid]).to be == 3030
        expect(xcrun_hash[:exit_status]).to be == 256
      end
    end
  end
end

