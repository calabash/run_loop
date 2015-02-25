describe RunLoop::LLDB do

  before (:each) { Resources.shared.kill_lldb_processes }

  it '.kill_lldb_processes' do
    Resources.shared.with_debugging do
      3.times {
        Resources.shared.spawn_lldb_process
      }

      RunLoop::ProcessWaiter.new('lldb').wait_for_any
      RunLoop::LLDB.kill_lldb_processes
      RunLoop::ProcessWaiter.new('lldb').wait_for_none

      expect(RunLoop::LLDB.lldb_pids.length).to be == 0
    end
  end
end
