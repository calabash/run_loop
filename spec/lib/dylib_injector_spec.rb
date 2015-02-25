describe RunLoop::DylibInjector do

  describe '.new' do
    it 'creates a new object with attrs set' do
      executable_name = 'executable name'
      dylib_path = '/some/path'
      lldb = RunLoop::DylibInjector.new(executable_name, dylib_path)
      expect(lldb).to be_a_kind_of(RunLoop::DylibInjector)
      expect(lldb.process_name).to be == executable_name
      expect(lldb.dylib_path).to be == dylib_path
    end
  end
end
