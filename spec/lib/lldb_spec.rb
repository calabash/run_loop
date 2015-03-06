describe RunLoop::LLDB do

  context '.is_lldb_process?' do
    it 'return true when passed an invocation of lldb' do
      ps_details = '/Xcode/6.1.1/Xcode.app/Contents/Developer/usr/bin/lldb'
      expect(RunLoop::LLDB.is_lldb_process?(ps_details)).to be_truthy
    end

    describe 'returns false when' do
      it 'arg is nil' do
        expect(RunLoop::LLDB.is_lldb_process?(nil)).to be_falsey
      end

      it 'arg is not an invocation of lldb' do
        ps_details = '/Users/moody/.rbenv/versions/2.2.0/bin/rspec spec/lib/lldb_spec.rb:19'
        expect(RunLoop::LLDB.is_lldb_process?(ps_details)).to be_falsey

        ps_details =  'man lldb'
        expect(RunLoop::LLDB.is_lldb_process?(ps_details)).to be_falsey
      end
    end
  end

  it '.kill_lldb_processes' do
    expect(RunLoop::LLDB).to receive(:lldb_pids).and_return([1, 2])
    expect(RunLoop::LLDB).to receive(:kill_with_signal).with(1, 'TERM').exactly(1).times.and_return(false)
    expect(RunLoop::LLDB).to receive(:kill_with_signal).with(1, 'KILL').exactly(1).times.and_return(true)
    expect(RunLoop::LLDB).to receive(:kill_with_signal).with(2, 'TERM').exactly(1).times.and_return(false)
    expect(RunLoop::LLDB).to receive(:kill_with_signal).with(2, 'KILL').exactly(1).times.and_return(true)
    expect(RunLoop::LLDB.kill_lldb_processes).to be_truthy
  end
end
