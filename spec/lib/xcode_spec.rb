describe RunLoop::Xcode do

  let(:xcode) { RunLoop::Xcode.new }

  describe '#ensure_valid_version_key' do
    it "raises an error when key does not start with 'v'" do
      expect do
        xcode.send(:ensure_valid_version_key, :abc)
      end.to raise_error("Expected version key to start with 'v'")
    end

    it "raises an error if key is too short" do
      expect do
        xcode.send(:ensure_valid_version_key, :v9)
      end.to raise_error(/to be exactly 3 chars long/)

      expect do
        xcode.send(:ensure_valid_version_key, :v10)
      end.to raise_error(/to be exactly 4 chars long/)
    end

    it "raises an error if key does not match correct pattern" do
      expect do
        xcode.send(:ensure_valid_version_key, :v9a)
      end.to raise_error(/to match this pattern:/)

      expect do
        xcode.send(:ensure_valid_version_key, :v10a)
      end.to raise_error(/to match this pattern:/)
    end

    it 'does not raise an error for valid keys' do
      expect do
        xcode.send(:ensure_valid_version_key, :v70)
      end.not_to raise_error

      expect do
        xcode.send(:ensure_valid_version_key, :v103)
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

  it '#v10' do expect(xcode.v100).to be == RunLoop::Version.new('10.0') end
  it '#v94' do expect(xcode.v94).to be == RunLoop::Version.new('9.4') end
  it '#v93' do expect(xcode.v93).to be == RunLoop::Version.new('9.3') end
  it '#v92' do expect(xcode.v92).to be == RunLoop::Version.new('9.2') end
  it '#v91' do expect(xcode.v91).to be == RunLoop::Version.new('9.1') end
  it '#v90' do expect(xcode.v90).to be == RunLoop::Version.new('9.0') end
  it '#v83' do expect(xcode.v83).to be == RunLoop::Version.new('8.3') end
  it '#v82' do expect(xcode.v82).to be == RunLoop::Version.new('8.2') end
  it '#v81' do expect(xcode.v81).to be == RunLoop::Version.new('8.1') end
  it '#v80' do expect(xcode.v80).to be == RunLoop::Version.new('8.0') end

  describe "#version_gte_100?" do
    it "true" do
      expect(xcode).to receive(:version).and_return(RunLoop::Version.new("10.0"))

      expect(xcode.version_gte_100?).to be_truthy
    end

    it "false" do
      expect(xcode).to receive(:version).and_return xcode.v94

      expect(xcode.version_gte_100?).to be_falsey
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
