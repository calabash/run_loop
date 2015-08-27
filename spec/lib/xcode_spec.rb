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
      end.not_to raise_error RuntimeError
    end
  end
end
