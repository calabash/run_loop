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

  it '#v72' do expect(xcode.v72).to be == RunLoop::Version.new('7.2') end
  it '#v71' do expect(xcode.v71).to be == RunLoop::Version.new('7.1') end
  it '#v70' do expect(xcode.v70).to be == RunLoop::Version.new('7.0') end
  it '#v64' do expect(xcode.v64).to be == RunLoop::Version.new('6.4') end
  it '#v63' do expect(xcode.v63).to be == RunLoop::Version.new('6.3') end
  it '#v62' do expect(xcode.v62).to be == RunLoop::Version.new('6.2') end
  it '#v61' do expect(xcode.v61).to be == RunLoop::Version.new('6.1') end
  it '#v60' do expect(xcode.v60).to be == RunLoop::Version.new('6.0') end
  it '#v51' do expect(xcode.v51).to be == RunLoop::Version.new('5.1') end
  it '#v50' do expect(xcode.v50).to be == RunLoop::Version.new('5.0') end

  describe '#version_gte_72?' do
    it 'true' do
      expect(xcode).to receive(:version).and_return(xcode.v72,
                                                    RunLoop::Version.new('8.0'))

      expect(xcode.version_gte_72?).to be_truthy
      expect(xcode.version_gte_72?).to be_truthy
    end

    it 'false' do
      expect(xcode).to receive(:version).and_return xcode.v71

      expect(xcode.version_gte_72?).to be_falsey
    end
  end

  describe '#version_gte_7?' do
    it 'true' do
      expect(xcode).to receive(:version).and_return(xcode.v70,
                                                    RunLoop::Version.new('8.0'))

      expect(xcode.version_gte_7?).to be_truthy
      expect(xcode.version_gte_7?).to be_truthy
    end

    it 'false' do
      expect(xcode).to receive(:version).and_return xcode.v64

      expect(xcode.version_gte_7?).to be_falsey
    end
  end

  describe '#version_gte_64?' do
    it 'true' do
      expect(xcode).to receive(:version).and_return(xcode.v64, xcode.v70)

      expect(xcode.version_gte_64?).to be_truthy
      expect(xcode.version_gte_64?).to be_truthy
    end

    it 'false' do
      expect(xcode).to receive(:version).and_return xcode.v63

      expect(xcode.version_gte_64?).to be_falsey
    end
  end

  describe '#version_gte_63?' do
    it 'true' do
      expect(xcode).to receive(:version).and_return(xcode.v63, xcode.v64)

      expect(xcode.version_gte_63?).to be_truthy
      expect(xcode.version_gte_63?).to be_truthy
    end

    it 'false' do
      expect(xcode).to receive(:version).and_return xcode.v62

      expect(xcode.version_gte_63?).to be_falsey
    end
  end

  describe '#version_gte_62?' do
    it 'true' do
      expect(xcode).to receive(:version).and_return(xcode.v62, xcode.v63)

      expect(xcode.version_gte_62?).to be_truthy
      expect(xcode.version_gte_62?).to be_truthy
    end

    it 'false' do
      expect(xcode).to receive(:version).and_return xcode.v61

      expect(xcode.version_gte_62?).to be_falsey
    end
  end

  describe '#version_gte_61?' do
    it 'true' do
      expect(xcode).to receive(:version).and_return(xcode.v61, xcode.v62)

      expect(xcode.version_gte_61?).to be_truthy
      expect(xcode.version_gte_61?).to be_truthy
    end

    it 'false' do
      expect(xcode).to receive(:version).and_return xcode.v60

      expect(xcode.version_gte_61?).to be_falsey
    end
  end

  describe '#version_gte_6?' do
    it 'true' do
      expect(xcode).to receive(:version).and_return(xcode.v60, xcode.v70)

      expect(xcode.version_gte_6?).to be_truthy
      expect(xcode.version_gte_6?).to be_truthy
    end

    it 'false' do
      expect(xcode).to receive(:version).and_return xcode.v51

      expect(xcode.version_gte_6?).to be_falsey
    end
  end

  describe '#version_gte_51?' do
    it 'true' do
      expect(xcode).to receive(:version).and_return(xcode.v51, xcode.v60)

      expect(xcode.version_gte_51?).to be_truthy
      expect(xcode.version_gte_51?).to be_truthy
    end

    it 'false' do
      expect(xcode).to receive(:version).and_return xcode.v50

      expect(xcode.version_gte_51?).to be_falsey
    end
  end

  describe '#developer_dir' do
    it 'respects the DEVELOPER_DIR env var' do
      expected = '/developer/dir'
      stub_env({'DEVELOPER_DIR' => expected})

      expect(xcode.developer_dir).to be == expected

      expect(RunLoop::Environment).not_to receive(:developer_dir)

      expect(xcode.instance_variable_get(:@xcode_developer_dir)).to be == expected
    end

    it 'or it returns the value of xcode-select' do
      expected = '/xcode-select/path'
      expect(xcode).to receive(:xcode_select_path).and_return(expected)
      stub_env({'DEVELOPER_DIR' => nil})

      expect(xcode.developer_dir).to be == '/xcode-select/path'

      expect(RunLoop::Environment).not_to receive(:developer_dir)
      expect(xcode).not_to receive(:xcode_select_path)

      expect(xcode.instance_variable_get(:@xcode_developer_dir)).to be == expected
    end
  end

  describe '#beta?' do
    it 'true if this is a beta version' do
      beta = '/Xcode/7.0b6/Xcode-beta.app/Contents/Developer'
      expect(xcode).to receive(:developer_dir).and_return beta

      expect(xcode.beta?).to be_truthy

      big_beta = '/Xcode/7.0b6/Xcode-Beta.app/Contents/Developer'
      expect(xcode).to receive(:developer_dir).and_return big_beta

      expect(xcode.beta?).to be_truthy
    end

    it 'false if this is not a beta version' do
      app = '/Xcode/6.4/Xcode.app/Contents/Developer/'
      expect(xcode).to receive(:developer_dir).and_return app

      expect(xcode.beta?).to be_falsey
    end
  end
end
