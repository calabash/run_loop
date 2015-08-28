describe RunLoop::XCTools do

  subject(:xctools) { RunLoop::XCTools.new }

  let(:xcode) { xctools.send(:xcode) }

  describe '#uikit_bundle_l10n_path' do
    it 'return value' do
      stub_env('DEVELOPER_DIR', '/some/xcode/path')
      axbundle_path = RunLoop::XCTools.const_get('UIKIT_AXBUNDLE_PATH')
      expected = File.join('/some/xcode/path', axbundle_path)
      expect(xctools.send(:uikit_bundle_l10n_path)).to be == expected
    end
  end

  describe '#lookup_localization_name' do

    subject { xctools.lookup_localization_name('delete.key', localization) }

    context 'when using the danish localization' do
      let('localization') { 'da' }
      it { is_expected.to be == 'Slet' }
    end

    context 'when using an unknown localization' do
      let('localization') { 'not-real' }
      it { is_expected.to be == nil }
    end
  end

  describe '#lang_dir' do
    subject { xctools.send(:lang_dir, localization) }

    context 'existing sub localization' do
      let(:localization) { 'en-GB' }
      it { is_expected.to be == 'en_GB.lproj' }
    end

    context 'existing iso localization' do
      let(:localization) { 'vi' }
      it { is_expected.to be == 'vi.lproj' }
    end

    context 'specially named localization' do
      let(:localization) { 'nl' }
      it { is_expected.to be == 'Dutch.lproj' }
    end

    context 'non-existing sub localization with specially named super-localization' do
      let(:localization) { 'en-XX' }
      it { is_expected.to be == 'English.lproj' }
    end

    context 'non-existing sub localization with iso super-localization' do
      let(:localization) { 'vi-VN' }
      it { is_expected.to be == 'vi.lproj' }
    end

    context 'unknown localization' do
      let(:localization) { 'xx' }
      it { is_expected.to be == nil }
    end
  end

  describe '#instruments' do
    it 'checks its arguments' do
      expect { xctools.instruments(:foo) }.to raise_error(ArgumentError)
    end

    it "no argument returns 'xcrun instruments'" do
      expect(xctools.instruments).to be == 'xcrun instruments'
    end
  end

  it '#xcode_developer_dir' do
    expected = '/some/path'
    expect(xcode).to receive(:developer_dir).and_return expected
    expect(xctools.xcode_developer_dir).to be == expected
  end

  it '#v70' do expect(xctools.v70).to be == RunLoop::Version.new('7.0') end
  it '#v64' do expect(xctools.v64).to be == RunLoop::Version.new('6.4') end
  it '#v63' do expect(xctools.v63).to be == RunLoop::Version.new('6.3') end
  it '#v62' do expect(xctools.v62).to be == RunLoop::Version.new('6.2') end
  it '#v61' do expect(xctools.v61).to be == RunLoop::Version.new('6.1') end
  it '#v60' do expect(xctools.v60).to be == RunLoop::Version.new('6.0') end
  it '#v51' do expect(xctools.v51).to be == RunLoop::Version.new('5.1') end
  it '#v50' do expect(xctools.v50).to be == RunLoop::Version.new('5.0') end

  it '#xcode_version' do
    expected = RunLoop::Version.new('3.1')
    expect(xcode).to receive(:version).and_return expected
    expect(xctools.xcode_version).to be == expected
  end

  it '#xcode_version_gte_7?' do
    expect(xcode).to receive(:version_gte_7?).and_return true
    expect(xctools.xcode_version_gte_7?).to be_truthy
  end

  it '#xcode_version_gte_64?' do
    expect(xcode).to receive(:version_gte_64?).and_return true
    expect(xctools.xcode_version_gte_64?).to be_truthy
  end

  it '#xcode_version_gte_63?' do
    expect(xcode).to receive(:version_gte_63?).and_return true
    expect(xctools.xcode_version_gte_63?).to be_truthy
  end

  it '#xcode_version_gte_62?' do
    expect(xcode).to receive(:version_gte_62?).and_return true
    expect(xctools.xcode_version_gte_62?).to be_truthy
  end

  it '#xcode_version_gte_61?' do
    expect(xcode).to receive(:version_gte_61?).and_return true
    expect(xctools.xcode_version_gte_61?).to be_truthy
  end

  it '#xcode_version_gte_6?' do
    expect(xcode).to receive(:version_gte_6?).and_return true
    expect(xctools.xcode_version_gte_6?).to be_truthy
  end

  it '#xcode_version_gte_51?' do
    expect(xcode).to receive(:version_gte_51?).and_return true
    expect(xctools.xcode_version_gte_51?).to be_truthy
  end

  it '#xcode_is_beta?' do
    expect(xcode).to receive(:beta?).and_return true
    expect(xctools.xcode_is_beta?).to be_truthy
  end
end
