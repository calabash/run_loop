describe RunLoop::XCTools do

  subject(:xctools) { RunLoop::XCTools.new }

  let(:xcode) { xctools.send(:xcode) }

  describe '#instruments' do
    it 'checks its arguments' do
      expect do
        capture_stderr { xctools.instruments(:foo) }
      end.to raise_error(ArgumentError)
    end
  end

  it '#xcode_developer_dir' do
    expected = '/some/path'
    expect(xcode).to receive(:developer_dir).and_return expected

    capture_stderr {  expect(xctools.xcode_developer_dir).to be == expected }
  end

  it '#v70' do
    capture_stderr { expect(xctools.v70).to be == RunLoop::Version.new('7.0') }
  end

  it '#v64' do
    capture_stderr {  expect(xctools.v64).to be == RunLoop::Version.new('6.4') }
  end

  it '#v63' do
    capture_stderr { expect(xctools.v63).to be == RunLoop::Version.new('6.3') }
  end

  it '#v62' do
    capture_stderr { expect(xctools.v62).to be == RunLoop::Version.new('6.2') }
  end

  it '#v61' do
    capture_stderr { expect(xctools.v61).to be == RunLoop::Version.new('6.1') }
  end

  it '#v60' do
    capture_stderr { expect(xctools.v60).to be == RunLoop::Version.new('6.0') }
  end

  it '#v51' do
    capture_stderr { expect(xctools.v51).to be == RunLoop::Version.new('5.1') }
  end

  it '#v50' do
    capture_stderr { expect(xctools.v50).to be == RunLoop::Version.new('5.0') }
  end

  it '#xcode_version' do
    expected = RunLoop::Version.new('3.1')
    expect(xcode).to receive(:version).and_return expected

    capture_stderr { expect(xctools.xcode_version).to be == expected }
  end

  it '#xcode_version_gte_7?' do
    expect(xcode).to receive(:version_gte_7?).and_return true

    capture_stderr { expect(xctools.xcode_version_gte_7?).to be_truthy }
  end

  it '#xcode_version_gte_64?' do
    expect(xcode).to receive(:version_gte_64?).and_return true

    capture_stderr { expect(xctools.xcode_version_gte_64?).to be_truthy }
  end

  it '#xcode_version_gte_63?' do
    expect(xcode).to receive(:version_gte_63?).and_return true

    capture_stderr { expect(xctools.xcode_version_gte_63?).to be_truthy }
  end

  it '#xcode_version_gte_62?' do
    expect(xcode).to receive(:version_gte_62?).and_return true

    capture_stderr { expect(xctools.xcode_version_gte_62?).to be_truthy }
  end

  it '#xcode_version_gte_61?' do
    expect(xcode).to receive(:version_gte_61?).and_return true

    capture_stderr { expect(xctools.xcode_version_gte_61?).to be_truthy }
  end

  it '#xcode_version_gte_6?' do
    expect(xcode).to receive(:version_gte_6?).and_return true

    capture_stderr { expect(xctools.xcode_version_gte_6?).to be_truthy }
  end

  it '#xcode_version_gte_51?' do
    expect(xcode).to receive(:version_gte_51?).and_return true

    capture_stderr { expect(xctools.xcode_version_gte_51?).to be_truthy }
  end

  it '#xcode_is_beta?' do
    expect(xcode).to receive(:beta?).and_return true

    capture_stderr { expect(xctools.xcode_is_beta?).to be_truthy }
  end
end
