describe RunLoop::L10N do

  subject(:l10n) { RunLoop::L10N.new }
  let(:xcode) { RunLoop::Xcode.new }

  before do
    allow(l10n).to receive(:xcode).and_return(xcode)
  end
  describe '#uikit_bundle_l10n_path' do
    it "returns a valid path for Xcode >= 9" do
      expect(xcode).to receive(:developer_dir).and_return("/some/xcode/path")
      stub_env("DEVELOPER_DIR", "/some/xcode/path")

      expect(xcode).to receive(:version_gte_90?).and_return(true)

      axbundle_path = RunLoop::L10N.const_get("UIKIT_AXBUNDLE_PATH_CORE_SIM_XCODE_9")
      expected = File.join("/some/xcode/path", axbundle_path)

      expect(l10n.send(:uikit_bundle_l10n_path)).to be == expected
    end

    it "returns a valid path for Xcode < 9" do
      expect(xcode).to receive(:developer_dir).and_return("/some/xcode/path")
      stub_env("DEVELOPER_DIR", "/some/xcode/path")

      expect(xcode).to receive(:version_gte_90?).and_return(false)

      axbundle_path = RunLoop::L10N.const_get("UIKIT_AXBUNDLE_PATH_CORE_SIM")
      expected = File.join("/some/xcode/path", axbundle_path)

      expect(l10n.send(:uikit_bundle_l10n_path)).to be == expected
    end
  end

  describe '#lookup_localization_name' do

    subject { l10n.lookup_localization_name('delete.key', localization) }

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
    subject { l10n.send(:lang_dir, localization) }

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
end
