describe RunLoop::LLDB do

  before (:each) { Resources.shared.kill_lldb_processes }

  it '.kill_lldb_processes' do
    ENV['DEBUG'] = '1'
    3.times {
      Resources.shared.spawn_lldb_process
    }
    sleep 0.4
    RunLoop::LLDB.kill_lldb_processes
    sleep 1.0
    expect(RunLoop::LLDB.lldb_pids.length).to be == 0
  end
end
