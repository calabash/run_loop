describe RunLoop::DylibInjector do

  let(:executable) { "app name" }
  let(:dylib) { "/some/path" }
  let(:lldb) { RunLoop::DylibInjector.new(executable, dylib) }

  it '.new' do
    expect(lldb.process_name).to be == executable
    expect(lldb.instance_variable_get(:@process_name)).to be == executable

    expect(lldb.dylib_path).to be == dylib
    expect(lldb.instance_variable_get(:@dylib_path)).to be == dylib
  end

  it "#xcrun" do
    xcrun = lldb.xcrun

    expect(lldb.xcrun).to be == xcrun
    expect(lldb.instance_variable_get(:@xcrun)).to be == xcrun
  end

  it "#write_script" do
    script = File.join(RunLoop::DotDir.directory, "inject-dylib.lldb")

    line0 = "process attach -n \"#{executable}\""
    line1 = "expr (void*)dlopen(\"#{dylib}\", 0x2)"
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
end
