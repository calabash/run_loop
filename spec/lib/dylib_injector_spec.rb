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

  end
end
