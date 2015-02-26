describe RunLoop::ProcessWaiter do

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

  context '#wait_for_n' do
    describe 'raises an error when' do
      it 'n is not an Integer' do
        expect { RunLoop::ProcessWaiter.new('ruby').wait_for_n 2.0 }.to raise_error ArgumentError
      end

      it 'n is < 0' do
        expect { RunLoop::ProcessWaiter.new('ruby').wait_for_n 0 }.to raise_error ArgumentError
        expect { RunLoop::ProcessWaiter.new('ruby').wait_for_n -1 }.to raise_error ArgumentError
      end

      it 'cannot find n processes and options say :raise' do
        options = {:timeout => 1, :raise_on_timeout => true }
        waiter = RunLoop::ProcessWaiter.new('ruby', options)
        expect { waiter.wait_for_n(1000) }.to raise_error
      end
    end

    it 'return true when there are N processes' do
      waiter = RunLoop::ProcessWaiter.new('ruby', {:timeout => 1})
      vals = [[], [0], [0, 1], [0, 1, 2], [0, 1, 2, 3]]
      expect(waiter).to receive(:pids).exactly(4).times.and_return(*vals)
      expect(waiter.wait_for_n(4)).to be == true
    end

    it 'returns false' do
      waiter = RunLoop::ProcessWaiter.new('ruby', {:timeout => 1})
      expect(waiter.wait_for_none).to be == false
    end

    it 'can log how long it waited' do
      expect(RunLoop::Environment).to receive(:debug?).at_least(:once).and_return(true)
      waiter = RunLoop::ProcessWaiter.new('ruby', {:timeout => 1.0, :interval => 0.5})
      vals = [[], [0], [0, 1]]
      expect(waiter).to receive(:pids).exactly(3).times.and_return(*vals)
      expect(waiter.wait_for_n(3)).to be == false
    end
  end
end
