describe 'RunLoop' do

  describe '.run' do
    before(:each) { Resources.shared.kill_instruments_app }
    after(:each) { Resources.shared.kill_instruments_app }

    it 'raises error if Instruments.app is running' do
      Resources.shared.launch_instruments_app
      expect { RunLoop.run }.to raise_error RuntimeError
    end

    it "can be retried with raising an error" do
      options = {
        :app => Resources.shared.cal_app_bundle_path,
        :uia_strategy => :preferences
      }

      run_options = {
        :app => Resources.shared.cal_app_bundle_path,
        :uia_strategy => :preferences,
        :script => "run_loop_fast_uia.js"
      }
      expect(RunLoop::Core).to receive(:run_with_options).with(run_options).and_raise(ArgumentError)
      expect(RunLoop::Core).to receive(:run_with_options).with(run_options).and_call_original

      begin
         RunLoop.run(options)
      rescue ArgumentError => _
        actual = RunLoop.run(options)
        expect(actual[:uia_strategy]).to be == options[:uia_strategy]
      end
    end
  end
end
