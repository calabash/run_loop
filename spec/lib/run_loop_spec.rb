describe 'RunLoop' do

  describe '.run' do
    before(:each) { Resources.shared.kill_instruments_app }
    after(:each) { Resources.shared.kill_instruments_app }

    it 'raises error if Instruments.app is running' do
      Resources.shared.launch_instruments_app
      expect { RunLoop.run }.to raise_error
    end
  end
end
