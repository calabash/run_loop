describe RunLoop::DylibInjector do

  let(:executable) { "app name" }
  let(:dylib) { "/some/path with spaces/lib.dylib" }
  let(:escaped) { Shellwords.shellescape(dylib) }
  let(:lldb) { RunLoop::DylibInjector.new(executable, dylib) }

  it '.new' do
    expect(lldb.process_name).to be == executable
    expect(lldb.instance_variable_get(:@process_name)).to be == executable

    expect(lldb.dylib_path).to be == escaped
    expect(lldb.instance_variable_get(:@dylib_path)).to be == escaped
  end

  it "#xcrun" do
    xcrun = lldb.xcrun

    expect(lldb.xcrun).to be == xcrun
    expect(lldb.instance_variable_get(:@xcrun)).to be == xcrun
  end

  it "#write_script" do
    script = File.join(RunLoop::DotDir.directory, "inject-dylib.lldb")

    line0 = "process attach -n \"#{executable}\""
    line1 = "expr (void*)dlopen(\"#{escaped}\", 0x2)"
    line2 = "detach"
    line3 = "exit"

    path = lldb.send(:write_script)
    contents = File.read(script).force_encoding("utf-8").strip.split("\n")

    expect(contents[0]).to be == line0
    expect(contents[1]).to be == line1
    expect(contents[2]).to be == line2
    expect(contents[3]).to be == line3

    expect(path).to be == script
  end

  describe "#inject_dylib" do
    let(:timeout) { 1 }
    let(:options) do
      {
        :timeout => 1,
        :log_cmd => true
      }
    end

    let(:script) { "/path/to/script.lldb" }
    let(:xcrun) { RunLoop::Xcrun.new }

    let(:hash) do
      {

        :pid => 1,
        :exit_status => 0,
        :out => ""
      }
    end

    before do
      allow(lldb).to receive(:xcrun).and_return(xcrun)
    end

    it "returns true" do
      expect(lldb).to receive(:write_script).and_return script
      cmd = ["lldb", "--no-lldbinit", "--source", script]

      expect(xcrun).to receive(:run_command_in_context).with(cmd, options).and_return(hash)

      expect(lldb.inject_dylib(timeout)).to be_truthy
    end

    describe "returns false" do
      it "when xcrun times out" do
        expect(xcrun).to receive(:run_command_in_context).and_raise RunLoop::Xcrun::TimeoutError

        expect(lldb.inject_dylib(timeout)).to be_falsey
      end

      it "when xcrun exits non-zero" do
        hash[:exit_status] = 1
        hash[:out] = "Line 0\nLine 1\nLine 2"

        expect(xcrun).to receive(:run_command_in_context).and_return(hash)

        expect(lldb.inject_dylib(timeout)).to be_falsey
      end
    end
  end

  describe "#retriable_inject_dylib" do
    describe "options" do
      it "respects the options args and raises an error" do

        options = {
          :tries => 5,
          :interval => 2,
          :timeout => 3
        }

        expect(lldb).to receive(:inject_dylib).with(3).exactly(5).times.and_return false
        # First sleep is the arbitrary delay.
        expect(lldb).to receive(:sleep).exactly(6).times.and_return true

        expect do
          lldb.retriable_inject_dylib(options)
        end.to raise_error RuntimeError, /Could not inject dylib/
      end

      it "has default options" do
        tries = RunLoop::DylibInjector::RETRY_OPTIONS[:tries]
        interval = RunLoop::DylibInjector::RETRY_OPTIONS[:interval]
        timeout = RunLoop::DylibInjector::RETRY_OPTIONS[:timeout]

        expect(lldb).to receive(:inject_dylib).with(timeout).exactly(tries).times.and_return false
        # First sleep is the arbitrary delay.
        expect(lldb).to receive(:sleep).exactly(tries + 1).times.and_return true

        expect do
          lldb.retriable_inject_dylib
        end.to raise_error RuntimeError, /Could not inject dylib/
      end
    end

    it "returns true if dylib was injected" do
      expect(lldb).to receive(:inject_dylib).and_return true
      expect(lldb.retriable_inject_dylib).to be_truthy
    end
  end
end

