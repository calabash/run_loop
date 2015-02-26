unless Resources.shared.travis_ci?
  describe RunLoop::LLDB do

    before (:each) { Resources.shared.kill_lldb_processes }

    describe '.lldb_pids' do
      it 'returns empty list when there are no lldb processes' do
        expect(RunLoop::LLDB.lldb_pids).to be == []
      end

      it 'returns array of integers when there are lldb processes' do
        Resources.shared.spawn_lldb_process
        RunLoop::ProcessWaiter.new('lldb').wait_for_any
        expect(RunLoop::LLDB.lldb_pids.length).to be == 1
      end
    end

    it '.kill_lldb_processes' do
      2.times {
        Resources.shared.spawn_lldb_process
      }

      RunLoop::LLDB.kill_lldb_processes
      expect(RunLoop::LLDB.lldb_pids.length).to be == 0
    end
  end
end
