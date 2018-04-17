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

  context ".run_shell_command" do
    it "creates an anonymous Shell instance and returns run_shell_command" do
      args = ["echo", "Hello"]
      actual = RunLoop::Shell.run_shell_command(args)
      expect(actual[:exit_status]).to be == 0
      expect(actual[:out]).to be == "Hello"
      expect(actual[:seconds_elapsed]).to be_truthy
    end
  end

  describe "#run_shell_command" do
    it "raises an error if arg is not an Array" do
      expect do
        object.run_shell_command("simctl list devices")
      end.to raise_error ArgumentError, /Expected args/
    end

    it "raises an error if any arg is not a string" do
      expect do
        object.run_shell_command(["sleep", 5])
      end.to raise_error ArgumentError,
      /Expected arg '5' to be a String, but found 'Fixnum'/
    end

    it "re-raises error if UTF8 encoding fails" do
      error = RunLoop::Encoding::UTF8Error.new("complex message")
      expect(object).to receive(:ensure_command_output_utf8).and_raise(error)

      expect do
        object.run_shell_command(["sleep", "0.5"])
      end.to raise_error RunLoop::Encoding::UTF8Error, /complex message/
    end

    it "re-raises error thrown by CommandRunner" do
      expect(CommandRunner).to receive(:run).and_raise RuntimeError, "Some error"

      expect do
        object.run_shell_command(["sleep", "0.5"])
      end.to raise_error RunLoop::Shell::Error, /Some error/
    end

    describe "raises TimeoutError error if CommandRunner timed out" do
      it "does so for mocked calls" do
        expect(process_status).to receive(:exitstatus).and_return(nil)
        expect(CommandRunner).to receive(:run).and_return(command_output)
        expect(object).to receive(:timeout_exceeded?).and_return(true)

        expect do
          object.run_shell_command(["sleep", "0.5"])
        end.to raise_error RunLoop::Shell::TimeoutError, /Timed out after/
      end

      it "does so for actual calls" do
        expect do
          object.run_shell_command(["sleep", "0.5"], timeout: 0.05)
        end.to raise_error RunLoop::Shell::TimeoutError, /Timed out after/
      end
    end

    it "raises error if :exit_status is nil" do
      expect(process_status).to receive(:exitstatus).and_return(nil)
      expect(CommandRunner).to receive(:run).and_return(command_output)
      expect(object).to receive(:timeout_exceeded?).and_return(false)

      expect do
        object.run_shell_command(["sleep", "0.5"])
      end.to raise_error RunLoop::Shell::Error, /There was an error executing/
    end

    describe "contents of returned hash" do
      it "mocked" do
        expect(process_status).to receive(:exitstatus).and_return(256)
        expect(process_status).to receive(:pid).and_return(3030)
        command_output[:out] = "mocked"
        expect(CommandRunner).to receive(:run).and_return(command_output)

        hash = object.run_shell_command(["sleep", "0.1"])

        expect(hash[:out]).to be == "mocked"
        expect(hash[:pid]).to be == 3030
        expect(hash[:exit_status]).to be == 256
        expect(hash[:seconds_elapsed]).to be_truthy
      end
    end

    it "responds to :environment option" do
      hash = object.run_shell_command(["grep", "responds to :environment",
                                       __FILE__])
      expect(hash[:out][/responds to :environment/]).to be_truthy

      environment = {"GREP_OPTIONS" => "-v"}
      hash = object.run_shell_command(["grep", "responds to :environment",
                                       __FILE__],
                                      {environment: environment})
      expect(hash[:out][/responds to :environment/]).to be_falsey
    end
  end

  context "#timeout_exceeded?" do
    it "returns true when start_time + timeout exceeds Time.now" do
      timeout = 5
      start_time = Time.now - 10

      expect(object.send(:timeout_exceeded?, start_time, timeout)).to be_truthy
    end

    it "returns false when start_time + timeout equals Time.now" do
      expect(Time).to receive(:now).and_return(10)
      timeout = 10
      start_time = 10 + 10
      expect(object.send(:timeout_exceeded?, start_time, timeout)).to be_falsey
    end

    it "returns false when start_time + timeout is less than Time.now" do
      timeout = 5
      start_time = Time.now - 2

      expect(object.send(:timeout_exceeded?, start_time, timeout)).to be_falsey
    end
  end
end

