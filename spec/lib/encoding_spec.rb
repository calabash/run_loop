describe RunLoop::Encoding do

  let(:object) do
    Class.new do
      include RunLoop::Encoding
    end.new
  end

  describe "#transliterate" do
    it "returns a string with no diactric markers" do
      string = "Max Münstermann"
      expected = "Max Munstermann"
      expect(object.transliterate(string)).to be == expected
    end

    it "replaces unknown characters and does not raise an error" do
      expect do
        object.transliterate("ITZVÓÃ ●℆❡♡")
      end.not_to raise_error
    end
  end

  describe "#ensure_command_output_utf8" do
    let(:string) { "string" }
    let(:encoded) { "encoded" }
    let(:forced) { "forced" }
    let(:command) { "command" }

    it "returns '' if string arg is falsey" do
      expect(object.ensure_command_output_utf8(nil, command)).to be == ''
    end

    it "returns utf8 encoding" do
      expect(string).to receive(:force_encoding).with("UTF-8").and_return(encoded)
      expect(encoded).to receive(:chomp).and_return(encoded)
      expect(encoded).to receive(:valid_encoding?).and_return(true)

      expect(object.ensure_command_output_utf8(string, command)).to be == encoded
    end

    it "forces utf8 encoding" do
      expect(string).to receive(:force_encoding).with("UTF-8").and_return(encoded)
      expect(encoded).to receive(:chomp).and_return(encoded)
      expect(encoded).to receive(:valid_encoding?).and_return(false)
      expect(encoded).to receive(:encode).and_return(forced)
      expect(forced).to receive(:valid_encoding?).and_return(true)

      expect(object.ensure_command_output_utf8(string, command)).to be == forced
    end

    it "raises an error if string cannot be coerced to UTF8" do
      expect(string).to receive(:force_encoding).with("UTF-8").and_return(encoded)
      expect(encoded).to receive(:chomp).and_return(encoded)
      expect(encoded).to receive(:valid_encoding?).and_return(false)
      expect(encoded).to receive(:encode).and_return(forced)
      expect(forced).to receive(:valid_encoding?).and_return(false)

      expect do
        object.ensure_command_output_utf8(string, command)
      end.to raise_error RunLoop::Encoding::UTF8Error,
      /Could not force UTF-8 encoding on this string:/
    end

    it "handles string with non-UTF8 characters" do
      file = "spec/resources/ps-with-non-utf8.log"
      string = File.read(file)

      version = RunLoop::Version.new(RUBY_VERSION)
      if version < RunLoop::Version.new("2.1.0")
        expect do
          object.ensure_command_output_utf8(string, command)
        end.to raise_error RunLoop::Encoding::UTF8Error
      else
        actual = object.ensure_command_output_utf8(string, command)
        split = actual.split($-0)

        expect(split[0]).to be == "  PID COMMAND"
        expect(split[1]).to be == "  324 /usr/libexec/UserEventAgent (Aqua)"
        expect(split[2]).to be == "  403 /Applications/M^\\M^IM^AM^SM^MM^E.app/Contents/MacOS/M^\\M^IM^AM^SM^MM^E"
        expect(split[3]).to be == " 1497 irb"
      end
    end

    it "handles UTF-8 strings" do
      # Force C (non UTF-8 encoding)
      stub_env({'LC_ALL' => 'C'})
      args = ['cat', 'spec/resources/encoding.txt']

      # Confirm that the string is read as ASCII-US8BIT
      command_runner_hash = CommandRunner.run(args, timeout: 0.2)
      command_runner_out = command_runner_hash[:out]
      expect(command_runner_out.length).to be == 22

      actual = object.ensure_command_output_utf8(command_runner_out, command)
      expect(actual).to be == 'ITZVÓÃ ●℆❡♡'
    end
  end
end

