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

    it 'does not raise an error for vaklid keys' do
      expect do
        xcode.send(:ensure_valid_version_key, :v70)
      end.not_to raise_error
    end
  end

  context "#version" do
    let(:xcodebuild_out) do
      {
        :out => %Q[
Xcode 8.2.1
Build version 8W132p
],
        :exit_status => 0,
        :pid => 1
      }
    end

    it "returns 0.0.0 when running on Test Cloud" do
      expect(RunLoop::Environment).to receive(:xtc?).and_return(true)

      expect(xcode.version).to be == RunLoop::Version.new("0.0.0")
    end

    it "returns 0.0.0 when xcrun xcodebuild has exit status non-zero" do
      xcodebuild_out[:exit_status] = 1
      expect(xcode).to receive(:run_shell_command).and_return(xcodebuild_out)

      expect(xcode.version).to be == RunLoop::Version.new("0.0.0")
    end

    it "returns 0.0.0 when xcrun xcodebuild raises an error" do
      expect(xcode).to receive(:run_shell_command).and_raise(RuntimeError)

      expect(xcode.version).to be == RunLoop::Version.new("0.0.0")
    end

    it "returns Xcode version" do
      expect(xcode).to receive(:run_shell_command).and_return(xcodebuild_out)

      expect(xcode.version).to be == RunLoop::Version.new("8.2.1")
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

  it '#v10' do expect(xcode.v10).to be == RunLoop::Version.new('10.0') end
  it '#v94' do expect(xcode.v94).to be == RunLoop::Version.new('9.4') end
  it '#v93' do expect(xcode.v93).to be == RunLoop::Version.new('9.3') end
  it '#v92' do expect(xcode.v92).to be == RunLoop::Version.new('9.2') end
  it '#v91' do expect(xcode.v91).to be == RunLoop::Version.new('9.1') end
  it '#v90' do expect(xcode.v90).to be == RunLoop::Version.new('9.0') end
  it '#v83' do expect(xcode.v83).to be == RunLoop::Version.new('8.3') end
  it '#v82' do expect(xcode.v82).to be == RunLoop::Version.new('8.2') end
  it '#v81' do expect(xcode.v81).to be == RunLoop::Version.new('8.1') end
  it '#v80' do expect(xcode.v80).to be == RunLoop::Version.new('8.0') end
  it '#v73' do expect(xcode.v73).to be == RunLoop::Version.new('7.3') end
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

  describe "#version_gte_10?" do
    it "true" do
      expect(xcode).to receive(:version).and_return(RunLoop::Version.new("10.0"))

      expect(xcode.version_gte_10?).to be_truthy
    end

    it "false" do
      expect(xcode).to receive(:version).and_return xcode.v10

      expect(xcode.version_gte_10?).to be_falsey
    end
  end

  describe "#version_gte_94?" do
    it "true" do
      expect(xcode).to receive(:version).and_return(RunLoop::Version.new("9.4"))

      expect(xcode.version_gte_94?).to be_truthy
    end

    it "false" do
      expect(xcode).to receive(:version).and_return xcode.v93

      expect(xcode.version_gte_94?).to be_falsey
    end
  end

  describe "#version_gte_93?" do
    it "true" do
      expect(xcode).to receive(:version).and_return(RunLoop::Version.new("9.3"))

      expect(xcode.version_gte_93?).to be_truthy
    end

    it "false" do
      expect(xcode).to receive(:version).and_return xcode.v92

      expect(xcode.version_gte_93?).to be_falsey
    end
  end

  describe "#version_gte_92?" do
    it "true" do
      expect(xcode).to receive(:version).and_return(RunLoop::Version.new("9.2"))

      expect(xcode.version_gte_92?).to be_truthy
    end

    it "false" do
      expect(xcode).to receive(:version).and_return xcode.v91

      expect(xcode.version_gte_92?).to be_falsey
    end
  end

  describe "#version_gte_91?" do
    it "true" do
      expect(xcode).to receive(:version).and_return(RunLoop::Version.new("9.1"))

      expect(xcode.version_gte_91?).to be_truthy
    end

    it "false" do
      expect(xcode).to receive(:version).and_return xcode.v90

      expect(xcode.version_gte_91?).to be_falsey
    end
  end

  describe "#version_gte_90?" do
    it "true" do
      expect(xcode).to receive(:version).and_return(RunLoop::Version.new("9.0"))

      expect(xcode.version_gte_90?).to be_truthy
    end

    it "false" do
      expect(xcode).to receive(:version).and_return xcode.v83

      expect(xcode.version_gte_90?).to be_falsey
    end
  end

  describe "#version_gte_83?" do
    it "true" do
      expect(xcode).to receive(:version).and_return(RunLoop::Version.new("8.3"))

      expect(xcode.version_gte_83?).to be_truthy
    end

    it "false" do
      expect(xcode).to receive(:version).and_return xcode.v82

      expect(xcode.version_gte_83?).to be_falsey
    end
  end

  describe "#version_gte_82?" do
    it "true" do
      expect(xcode).to receive(:version).and_return(RunLoop::Version.new("8.2"))

      expect(xcode.version_gte_82?).to be_truthy
    end

    it "false" do
      expect(xcode).to receive(:version).and_return xcode.v80

      expect(xcode.version_gte_82?).to be_falsey
    end
  end

  describe "#version_gte_81?" do
    it "true" do
      expect(xcode).to receive(:version).and_return(xcode.v81,
                                                    RunLoop::Version.new("8.1"))

      expect(xcode.version_gte_81?).to be_truthy
      expect(xcode.version_gte_81?).to be_truthy
    end

    it "false" do
      expect(xcode).to receive(:version).and_return xcode.v80

      expect(xcode.version_gte_81?).to be_falsey
    end
  end

  describe "#version_gte_8?" do
    it "true" do
      expect(xcode).to receive(:version).and_return(xcode.v80,
                                                    RunLoop::Version.new("8.1"))

      expect(xcode.version_gte_8?).to be_truthy
      expect(xcode.version_gte_8?).to be_truthy
    end

    it "false" do
      expect(xcode).to receive(:version).and_return xcode.v73

      expect(xcode.version_gte_8?).to be_falsey
    end
  end

  describe "#version_gte_73?" do
    it "true" do
      expect(xcode).to receive(:version).and_return(xcode.v73,
                                                    RunLoop::Version.new("8.0"))

      expect(xcode.version_gte_73?).to be_truthy
      expect(xcode.version_gte_73?).to be_truthy
    end

    it "false" do
      expect(xcode).to receive(:version).and_return xcode.v71

      expect(xcode.version_gte_73?).to be_falsey
    end
  end

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
      expect(File).to receive(:directory?).with(expected).and_return(true)
      stub_env({'DEVELOPER_DIR' => expected})

      expect(xcode.developer_dir).to be == expected

      expect(RunLoop::Environment).not_to receive(:developer_dir)

      expect(xcode.instance_variable_get(:@xcode_developer_dir)).to be == expected
    end

    it 'or it returns the value of xcode-select' do
      expected = '/xcode-select/path'
      expect(File).to receive(:directory?).with(expected).and_return(true)
      expect(xcode).to receive(:xcode_select_path).and_return(expected)
      stub_env({'DEVELOPER_DIR' => nil})

      expect(xcode.developer_dir).to be == '/xcode-select/path'

      expect(RunLoop::Environment).not_to receive(:developer_dir)
      expect(xcode).not_to receive(:xcode_select_path)

      expect(xcode.instance_variable_get(:@xcode_developer_dir)).to be == expected
    end

    it "raises an error if active Xcode cannot be determined" do
      expected = '/developer/dir'
      expect(File).to receive(:directory?).with(expected).and_return(false)
      stub_env({'DEVELOPER_DIR' => expected})

      expect do
        xcode.developer_dir
      end.to raise_error RuntimeError, /Cannot determine the active Xcode/
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
