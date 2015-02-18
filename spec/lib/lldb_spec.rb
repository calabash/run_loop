describe RunLoop::LLDB do

  before (:each) { Resources.shared.kill_lldb_processes }

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

  describe '.lldb_pids' do
    it 'returns empty list when there are no lldb processes' do
      expect(RunLoop::LLDB.lldb_pids).to be == []
    end

    it 'returns array of integers when there are lldb processes' do
      Resources.shared.spawn_lldb_process
      expect(RunLoop::LLDB.lldb_pids.length).to be == 1
    end
  end
end
