describe RunLoop::Xcode do

  let(:xcode) { RunLoop::Xcode.new }

  describe '#ensure_valid_version_key' do
    describe 'raises error when key format is not correct' do
      it 'key is too short' do
        expect do
          xcode.send(:ensure_valid_version_key, :v7)
        end.to raise_error RuntimeError
      end

      it 'key is too long' do
        expect do
          xcode.send(:ensure_valid_version_key, :v701)
        end.to raise_error RuntimeError
      end

      it 'key does not start with v' do
        expect do
          xcode.send(:ensure_valid_version_key, :a70)
        end.to raise_error RuntimeError
      end

      it 'key does have two integers' do
        expect do
          xcode.send(:ensure_valid_version_key, :v7a)
        end.to raise_error RuntimeError
      end
    end

    it 'does not raise an error for valid keys' do
      expect do
        xcode.send(:ensure_valid_version_key, :v70)
      end.not_to raise_error
    end
  end

  it '#xcode_versions' do
    expect(xcode.instance_variable_get(:@xcode_versions)).to be == nil
    expect(xcode.send(:xcode_versions)).to be == {}
    expect(xcode.instance_variable_get(:@xcode_versions)).to be == {}
  end

  it '#fetch_version' do
    key = :v70
    expect(xcode).to receive(:ensure_valid_version_key).with(key).twice

    version = RunLoop::Version.new('7.0')
    expect(xcode.send(:fetch_version, key)).to be == version
    variable = xcode.instance_variable_get(:@xcode_versions)
    expect(variable[key]).to be == version

    # Test memoization
    expect(xcode).to receive(:xcode_versions).once.and_call_original
    expect(xcode.send(:fetch_version, key)).to be == version
  end

  it '#v70' do expect(xcode.v70).to be == RunLoop::Version.new('7.0') end
  it '#v64' do expect(xcode.v64).to be == RunLoop::Version.new('6.4') end
  it '#v63' do expect(xcode.v63).to be == RunLoop::Version.new('6.3') end
  it '#v62' do expect(xcode.v62).to be == RunLoop::Version.new('6.2') end
  it '#v61' do expect(xcode.v61).to be == RunLoop::Version.new('6.1') end
  it '#v60' do expect(xcode.v60).to be == RunLoop::Version.new('6.0') end
  it '#v51' do expect(xcode.v51).to be == RunLoop::Version.new('5.1') end
  it '#v50' do expect(xcode.v50).to be == RunLoop::Version.new('5.0') end

end
