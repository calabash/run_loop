describe RunLoop::ProcessTerminator do

  describe '.new' do
    it 'creates a new terminator' do
      pid = 1
      kill_signal = 9
      display_name = 'foo'
      terminator = RunLoop::ProcessTerminator.new(pid, kill_signal, display_name)
      expect(terminator).not_to be nil
      expect(terminator.pid).to be == pid
      expect(terminator.kill_signal).to be == kill_signal
      expect(terminator.display_name).to be == display_name
      expect(terminator.options.count).to_not be == 0
    end

    it 'converts String pid to Integer' do
      pid = '1'
      terminator = RunLoop::ProcessTerminator.new(pid, 'TERM', 'foo')
      expect(terminator.pid).to be == pid.to_i
    end
  end
end

