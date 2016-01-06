
describe RunLoop do

  before do
    allow_any_instance_of(RunLoop::Instruments).to receive(:instruments_app_running?).and_return(false)
  end

  describe ".run" do

    it "does not mangle options" do
        xcode = RunLoop::Xcode.new
        sim_control = RunLoop::SimControl.new
      options = {
        :xcode => xcode,
        :sim_control => sim_control,
        :uia_strategy => :preferences
      }

      after = {
        :xcode => xcode,
        :sim_control => sim_control,
        :uia_strategy => :preferences,
        :script => "run_loop_fast_uia.js"
      }

      expect(RunLoop::Core).to receive(:run_with_options).with(after).and_return({})
      RunLoop.run(options)

      expect(options.count).to be == 3
    end
  end
end
