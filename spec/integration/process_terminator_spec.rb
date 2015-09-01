describe RunLoop::ProcessTerminator do

  before(:each) { Resources.shared.kill_fake_instruments_process }
  after(:each) { Resources.shared.kill_fake_instruments_process }

  let(:process_name) { 'fake instruments process' }

  describe '#wait_for_process_to_terminate' do
    describe 'raises an error if' do
      it 'the process is still alive and :raise_on_no_terminate => true' do
        pid = Resources.shared.fork_fake_instruments_process
        options = {:raise_on_no_terminate => true}
        terminator = RunLoop::ProcessTerminator.new(pid, 'TERM', process_name, options)
        expect {
          terminator.send(:wait_for_process_to_terminate)
        }.to raise_error RuntimeError
      end
    end

    describe 'does not raise an error' do
      it 'if process is terminated' do
        pid = Resources.shared.fork_fake_instruments_process
        sleep 0.5
        Resources.shared.kill_fake_instruments_process
        options = { :raise_on_no_terminate => true}
        terminator = RunLoop::ProcessTerminator.new(pid, 'TERM', process_name, options)
        expect {
          terminator.send(:wait_for_process_to_terminate)
        }.not_to raise_error
      end

      it 'by default if the process is still alive' do
        pid = Resources.shared.fork_fake_instruments_process
        terminator = RunLoop::ProcessTerminator.new(pid, 'TERM', process_name)
        expect {
          terminator.send(:wait_for_process_to_terminate)
        }.not_to raise_error
      end
    end

    it 'returns true if process exited' do
      pid = Resources.shared.fork_fake_instruments_process
      sleep 0.5
      Resources.shared.kill_fake_instruments_process
      terminator = RunLoop::ProcessTerminator.new(pid, 'TERM', process_name)
      expect(terminator.send(:wait_for_process_to_terminate)).to be == true
    end

    it 'returns false if the process has not exited' do
      pid = Resources.shared.fork_fake_instruments_process
      options = {:timeout => 0.2}
      terminator = RunLoop::ProcessTerminator.new(pid, 'TERM', process_name, options)
      expect(terminator.send(:wait_for_process_to_terminate)).to be == false
    end

    it 'can generate debug output' do
      stub_env('DEBUG', '1')
      pid = Resources.shared.fork_fake_instruments_process
      options = {:timeout => 0.2}
      terminator = RunLoop::ProcessTerminator.new(pid, 'TERM', process_name, options)
      expect(terminator.send(:wait_for_process_to_terminate)).to be == false
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
