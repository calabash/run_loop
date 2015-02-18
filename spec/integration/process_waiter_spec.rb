describe RunLoop::ProcessWaiter do

  before(:each) { Resources.shared.kill_fake_instruments_process }

  context '#wait_for_any' do
    describe 'returns true' do
      it 'fast if process is running' do
        res = RunLoop::ProcessWaiter.new('ruby').wait_for_any
        expect(res).to be == true
      end

      it 'after waiting for process' do
        waiter = RunLoop::ProcessWaiter.new('ruby', {:timeout => 2})
        vals = [false, false, false, true]
        expect(waiter).to receive(:running_process?).exactly(4).times.and_return(*vals)
        expect(waiter.wait_for_any).to be == true
      end
    end

    it 'returns false' do
      waiter = RunLoop::ProcessWaiter.new('ruby', {:timeout => 1})
      expect(waiter).to receive(:running_process?).at_least(:twice).and_return(false)
      expect(waiter.wait_for_any).to be == false
    end

    it 'raises an error' do
      options = {:timeout => 1, :raise_on_timeout => true }
      waiter = RunLoop::ProcessWaiter.new('ruby', options)
      expect(waiter).to receive(:running_process?).at_least(:twice).and_return(false)
      expect { waiter.wait_for_any }.to raise_error
    end

    it 'can log how long it waited' do
      expect(RunLoop::Environment).to receive(:debug?).at_least(:once).and_return(true)
      waiter = RunLoop::ProcessWaiter.new('ruby', {:timeout => 2})
      vals = [false, false, false, true]
      expect(waiter).to receive(:running_process?).exactly(4).times.and_return(*vals)
      expect(waiter.wait_for_any).to be == true
    end
  end


  context '#wait_for_none' do
    describe 'returns true' do
      it 'fast if no process is running' do
        res = RunLoop::ProcessWaiter.new('no-such-process').wait_for_none
        expect(res).to be == true
      end

      it 'after waiting for process to expire' do
        waiter = RunLoop::ProcessWaiter.new('ruby', {:timeout => 1})
        vals = [true, true, true, false]
        expect(waiter).to receive(:running_process?).exactly(4).times.and_return(*vals)
        expect(waiter.wait_for_none).to be == true
      end
    end

    it 'returns false' do
      waiter = RunLoop::ProcessWaiter.new('ruby', {:timeout => 1})
      expect(waiter.wait_for_none).to be == false
    end

    it 'raises an error' do
      options = {:timeout => 1, :raise_on_timeout => true }
      waiter = RunLoop::ProcessWaiter.new('ruby', options)
      expect { waiter.wait_for_none }.to raise_error
    end

    it 'can log how long it waited' do
      expect(RunLoop::Environment).to receive(:debug?).at_least(:once).and_return(true)
      waiter = RunLoop::ProcessWaiter.new('ruby', {:timeout => 2})
      expect(waiter.wait_for_none).to be == false
    end
  end

end
