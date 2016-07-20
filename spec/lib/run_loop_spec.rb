
describe RunLoop do

  before do
    allow_any_instance_of(RunLoop::Instruments).to receive(:instruments_app_running?).and_return(false)
  end

  let(:xcode) { RunLoop::Xcode.new }
  let(:instruments) { RunLoop::Instruments.new }
  let(:simctl) { RunLoop::Simctl.new }
  let(:device) { Resources.shared.device }

  describe ".run" do

    it "does not mangle options" do
      options = {
        :xcode => xcode,
        :simctl => simctl,
        :uia_strategy => :preferences,
        :instruments => instruments,
        :device => device
      }

      after = {
        :xcode => xcode,
        :simctl => simctl,
        :uia_strategy => :preferences,
        :instruments => instruments,
        :device => device,
      }

      expect(RunLoop::Core).to receive(:run_with_options).with(after).and_return({})
      RunLoop.run(options)

      expect(options.count).to be == 5
    end
  end

    end
  end
end
