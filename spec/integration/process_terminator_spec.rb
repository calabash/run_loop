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
        }.to raise_error
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
end
