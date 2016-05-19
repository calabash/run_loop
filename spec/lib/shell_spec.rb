describe RunLoop::Shell do

  let(:object) do
    Class.new do
      include RunLoop::Shell
    end.new
  end


  let(:process_status) do
    # It is not possible call Process::Status.new
    `echo`
    $?
  end

  let(:command_output) do
    {
          :out => "",
          :status => process_status
    }
  end

  describe "#exec" do
    it "raises an error if arg is not an Array" do
      expect do
        object.exec("simctl list devices")
      end.to raise_error ArgumentError, /Expected args/
    end

    it "raises an error if any arg is not a string" do
      expect do
        object.exec(["sleep", 5])
      end.to raise_error ArgumentError,
      /Expected arg '5' to be a String, but found 'Fixnum'/
    end

    it "re-raises error if UTF8 encoding fails" do
      error = RunLoop::Encoding::UTF8Error.new("complex message")
      expect(object).to receive(:ensure_command_output_utf8).and_raise(error)

      expect do
        object.exec(["sleep", "0.5"])
      end.to raise_error RunLoop::Encoding::UTF8Error, /complex message/
    end

    it "re-raises error thrown by CommandRunner" do
      expect(CommandRunner).to receive(:run).and_raise RuntimeError, "Some error"

      expect do
        object.exec(["sleep", "0.5"])
      end.to raise_error RunLoop::Shell::Error, /Some error/
    end

    describe "raises timeout error if CommandRunner timed out" do
      it "mocked" do
        expect(process_status).to receive(:exitstatus).and_return(nil)
        expect(CommandRunner).to receive(:run).and_return(command_output)

        expect do
          object.exec(["sleep", "0.5"])
        end.to raise_error RunLoop::Shell::TimeoutError, /Timed out after/
      end

      it "actual" do
        expect do
          object.exec(["sleep", "0.5"], timeout: 0.05)
        end.to raise_error RunLoop::Shell::TimeoutError, /Timed out after/
      end
    end

    describe "contents of returned hash" do
      it "mocked" do
        expect(process_status).to receive(:exitstatus).and_return(256)
        expect(process_status).to receive(:pid).and_return(3030)
        command_output[:out] = "mocked"
        expect(CommandRunner).to receive(:run).and_return(command_output)

        hash = object.exec(["sleep", "0.1"])

        expect(hash[:out]).to be == "mocked"
        expect(hash[:pid]).to be == 3030
        expect(hash[:exit_status]).to be == 256
      end
    end
  end
end

