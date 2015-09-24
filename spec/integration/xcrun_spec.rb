describe RunLoop::Xcrun do

  let(:xcrun) { RunLoop::Xcrun.new }

  if Resources.shared.core_simulator_env?
    it 'can call simctl' do
      args = ['simctl', 'list', 'devices']

      hash = xcrun.exec(args, log_cmd: true, timeout: 2)

      expect(hash[:out]).to be_truthy
      expect(hash[:exit_status]).to be_truthy
      expect(hash[:pid]).to be_truthy
    end
  end

  it 'can call xcodebuild -version' do

    args = ['xcodebuild', '-version']

    hash = xcrun.exec(args, log_cmd: true, timeout: 2)

    expect(hash[:out]).to be_truthy
    expect(hash[:exit_status]).to be_truthy
    expect(hash[:pid]).to be_truthy
  end

end
