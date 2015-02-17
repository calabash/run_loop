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

  describe 'testing live processes' do
    before(:each) { Resources.shared.kill_fake_instruments_process }
    after(:each) { Resources.shared.kill_fake_instruments_process }
    describe '#process_alive?' do
      describe 'returns true when process' do
        it 'is alive and owned by us' do
          pid = Resources.shared.fork_fake_instruments_process
          sleep(0.5)
          terminator = RunLoop::ProcessTerminator.new(pid, 'TERM', 'process')
          expect(terminator.process_alive?).to be_truthy
        end

        it 'is alive and not owned by us' do
          terminator = RunLoop::ProcessTerminator.new(0, 'TERM', 'process')
          expect(terminator.process_alive?).to be_truthy
        end
      end
    end

    describe '#ps_details' do
      it 'returns the details of a process' do
        pid = Resources.shared.fork_fake_instruments_process
        sleep(0.5)
        terminator = RunLoop::ProcessTerminator.new(pid, 'TERM', 'process')
        expect(terminator.send(:ps_details)[/ruby/,0]).not_to be == nil
      end
    end
  end
end
