describe RunLoop::ProcessWaiter do

  context "#wait_for_any" do
    it "returns true if process is running" do
      res = RunLoop::ProcessWaiter.new("Finder").wait_for_any
      expect(res).to be == true
    end

    it "returns true after waiting for process to start" do
      waiter = RunLoop::ProcessWaiter.new("Finder", {:timeout => 2})
      vals = [false, false, false, true]
      expect(waiter).to receive(:running_process?).exactly(4).times.and_return(*vals)
      expect(waiter.wait_for_any).to be == true
    end

    it "returns false after waiting for process to start" do
      waiter = RunLoop::ProcessWaiter.new("Finder", {:timeout => 0.5})
      expect(waiter).to receive(:running_process?).at_least(:twice).and_return(false)
      expect(waiter.wait_for_any).to be == false
    end

    it "raises an error when :raise_on_timeout is true" do
      options = {:timeout => 0.5, :raise_on_timeout => true }
      waiter = RunLoop::ProcessWaiter.new("Finder", options)
      expect(waiter).to receive(:running_process?).at_least(:twice).and_return(false)
      expect { waiter.wait_for_any }.to raise_error RuntimeError
    end

    it "can log how long it waited" do
      expect(RunLoop::Environment).to receive(:debug?).at_least(:once).and_return(true)
      waiter = RunLoop::ProcessWaiter.new("Finder", {:timeout => 2})
      vals = [false, false, false, true]
      expect(waiter).to receive(:running_process?).exactly(4).times.and_return(*vals)
      expect(waiter.wait_for_any).to be == true
    end
  end

  context "#wait_for_none" do
    it "returns true if no process is running" do
      waiter = RunLoop::ProcessWaiter.new("no-such-process", {:timeout => 1})
      expect(waiter.wait_for_none).to be == true
    end

    it "returns true after waiting for process to expire" do
      waiter = RunLoop::ProcessWaiter.new("Finder", {:timeout => 1})
      vals = [true, true, true, false]
      expect(waiter).to receive(:running_process?).exactly(4).times.and_return(*vals)
      expect(waiter.wait_for_none).to be == true
    end

    it "returns false if process is still running after :timeout" do
      waiter = RunLoop::ProcessWaiter.new("Finder", {:timeout => 0.5})
      expect(waiter.wait_for_none).to be == false
    end

    it "raises an error if :raise_on_timeout is true" do
      options = {:timeout => 0.5, :raise_on_timeout => true }
      waiter = RunLoop::ProcessWaiter.new("Finder", options)
      expect { waiter.wait_for_none }.to raise_error RuntimeError
    end

    it "logs how long it waited" do
      expect(RunLoop::Environment).to receive(:debug?).at_least(:once).and_return(true)
      waiter = RunLoop::ProcessWaiter.new("Finder", {:timeout => 0.5})
      expect(waiter.wait_for_none).to be == false
    end
  end

  context "#wait_for_n" do
    it "raises ArgumentError when n is not an Integer" do
      expect do
        RunLoop::ProcessWaiter.new("ruby").wait_for_n 2.0
      end.to raise_error ArgumentError
    end

    it "raises ArgumentError when n is <= 0" do
      expect do
        RunLoop::ProcessWaiter.new('ruby').wait_for_n 0
      end.to raise_error ArgumentError
      expect do
        RunLoop::ProcessWaiter.new('ruby').wait_for_n -1
      end.to raise_error ArgumentError
    end

    it "raises RuntimeError when n processes are not running and :raise_on_timeout is true" do
      options = {:timeout => 0.5, :raise_on_timeout => true }
      waiter = RunLoop::ProcessWaiter.new("Finder", options)
      expect do
        waiter.wait_for_n(1000)
      end.to raise_error RuntimeError
    end

    it "returns true when there are N processes" do
      waiter = RunLoop::ProcessWaiter.new("Finder", {:timeout => 1})
      vals = [[], [0], [0, 1], [0, 1, 2], [0, 1, 2, 3]]
      expect(waiter).to receive(:pids).exactly(4).times.and_return(*vals)
      expect(waiter.wait_for_n(4)).to be == true
    end

    it "returns false when N processes do not appear" do
      waiter = RunLoop::ProcessWaiter.new("Finder", {:timeout => 0.5})
      expect(waiter.wait_for_n(2)).to be == false
    end

    it "can log how long it waited" do
      expect(RunLoop::Environment).to receive(:debug?).at_least(:once).and_return(true)
      waiter = RunLoop::ProcessWaiter.new("Finder", {:timeout => 1.0, :interval => 0.5})
      vals = [[], [0], [0, 1]]
      expect(waiter).to receive(:pids).exactly(3).times.and_return(*vals)
      expect(waiter.wait_for_n(3)).to be == false
    end
  end
end
