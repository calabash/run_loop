describe RunLoop do
  describe '.colorize' do
    it 'does nothing in win32 environments' do
      expect(RunLoop::Environment).to receive(:windows_env?).and_return true

      actual = RunLoop.send(:colorize, 'string', 32)
      expect(actual).to be == 'string'
    end

    it 'does nothing on the XTC' do
      expect(RunLoop::Environment).to receive(:windows_env?).and_return false
      expect(RunLoop::Environment).to receive(:xtc?).and_return true

      actual = RunLoop.send(:colorize, 'string', 32)
      expect(actual).to be == 'string'
    end

    it 'applies the color' do
      expect(RunLoop::Environment).to receive(:windows_env?).and_return false
      expect(RunLoop::Environment).to receive(:xtc?).and_return false

      actual = RunLoop.send(:colorize, 'string', 32)
      expect(actual[/32/, 0]).not_to be == nil
    end
  end

  describe 'logging' do
    before do
      allow(RunLoop::Environment).to receive(:debug?).and_return true
    end

    it '.log_unix_cmd' do
      RunLoop.log_unix_cmd('command')
    end

    it '.log_warn' do
      RunLoop.log_warn('warn')
    end

    it '.log_debug' do
      RunLoop.log_debug('debug')
    end

    it '.log_error' do
      RunLoop.log_error('error')
    end

    # .log_info is already taken by the XTC logger. (>_O)
    it '.log_info2' do
      RunLoop.log_info2("info")
    end
  end
end
