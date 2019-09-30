describe RunLoop::L10N do

  subject(:l10n) { RunLoop::L10N.new }
  let(:xcode) { RunLoop::Xcode.new }

  before do
    allow(l10n).to receive(:xcode).and_return(xcode)
  end
  describe '#uikit_bundle_l10n_path' do
    it 'returns a valid path for Xcode >= 11' do
      expect(xcode).to receive(:version).twice.and_return(RunLoop::Version.new('11.0'))
      expect(xcode).to receive(:developer_dir).and_return('/Xcode')

      expected = '/Xcode/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot/System/Library/AccessibilityBundles/UIKit.axbundle'

      expect(l10n.send(:uikit_bundle_l10n_path)).to be == expected
    end

    it 'returns a valid path for 9 <= Xcode < 11' do
      expect(xcode).to receive(:version).twice.and_return(RunLoop::Version.new('10.2.1'))
      expect(xcode).to receive(:developer_dir).and_return('/Xcode')

      expected = '/Xcode/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot/System/Library/AccessibilityBundles/UIKit.axbundle'

      expect(l10n.send(:uikit_bundle_l10n_path)).to be == expected
    end

    it 'returns a valid path for Xcode < 9' do
      expect(xcode).to receive(:version).and_return(RunLoop::Version.new('8.3.3'))
      expect(xcode).to receive(:developer_dir).and_return('/Xcode')

      expected = '/Xcode/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/AccessibilityBundles/UIKit.axbundle'

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
      it { expect(["Dutch.lproj", "nl.lproj"]).to include(subject) }
    end

    context 'non-existing sub localization with specially named super-localization' do
      let(:localization) { 'en-XX' }
      it { expect(["English.lproj", "en.lproj"]).to include(subject) }
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
