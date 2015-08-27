describe RunLoop::XCTools do

  subject(:xctools) { RunLoop::XCTools.new }

  describe '#xcode_developer_dir' do
    it 'respects the DEVELOPER_DIR env var' do
      Resources.shared.with_developer_dir('/foo/bar') do
        expect(xctools.xcode_developer_dir).to be == ENV['DEVELOPER_DIR']
      end
    end

    it 'or it returns the value of xcode-select' do
      actual = `xcode-select --print-path`.chomp
      expect(xctools.xcode_developer_dir).to be == actual
    end
  end

  describe '#uikit_bundle_l10n_path' do
    it 'return value' do
      stub_env('DEVELOPER_DIR', '/some/xcode/path')
      axbundle_path = RunLoop::XCTools.const_get('UIKIT_AXBUNDLE_PATH')
      expected = File.join('/some/xcode/path', axbundle_path)
      expect(xctools.send(:uikit_bundle_l10n_path)).to be == expected
    end
  end

  describe '#lookup_localization_name' do

    subject { xctools.lookup_localization_name("delete.key", localization) }

    context 'when using the danish localization' do
      let('localization') { "da" }
      it { is_expected.to be == "Slet" }
    end

    context 'when using an unknown localization' do
      let('localization') { "not-real" }
      it { is_expected.to be == nil }
    end
  end

  describe "#lang_dir" do
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

    context 'non-exisiting sub localization with iso super-localization' do
      let(:localization) { 'vi-VN' }
      it { is_expected.to be == 'vi.lproj' }
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

  describe '#instruments_supports_hypen_s?' do
    it { expect(xctools.instruments_supports_hyphen_s? '6.0' ).to be == true }
    it { expect(xctools.instruments_supports_hyphen_s? '5.1.1').to be == true }
    it { expect(xctools.instruments_supports_hyphen_s? '5.1' ).to be == true }
    it { expect(xctools.instruments_supports_hyphen_s? '5.0.2').to be == false }
    it { expect(xctools.instruments_supports_hyphen_s? '4.6.3').to be == false }
  end

  it '#xc70' do
    expect(xctools.v70).to be == RunLoop::Version.new('7.0')
    expect(xctools.instance_variable_get(:@xc70)).to be == RunLoop::Version.new('7.0')
  end

  describe '#xc62' do
    it { expect(xctools.v62).to be == RunLoop::Version.new('6.2') }
  end

  describe '#xc61' do
    it { expect(xctools.v61).to be == RunLoop::Version.new('6.1') }
  end

  describe '#xc60' do
    it { expect(xctools.v60).to be == RunLoop::Version.new('6.0') }
  end

  describe '#xc50' do
    it { expect(xctools.v50).to be == RunLoop::Version.new('5.0') }
  end

  describe '#xc51' do
    it { expect(xctools.v51).to be == RunLoop::Version.new('5.1') }
  end

  describe '#xcode_version' do
    it 'returns the current Xcode version as a RunLoop::Version' do
      expect(xctools.xcode_version).to be_a RunLoop::Version
    end

    describe 'regression' do
      xcode_installs = Resources.shared.alt_xcode_install_paths
      if xcode_installs.empty?
        it 'no alternative versions of Xcode found' do
          expect(true).to be == true
        end
      else
        xcode_installs.each do |developer_dir|
          it "#{developer_dir}" do
            Resources.shared.with_developer_dir(developer_dir) do
              expect(RunLoop::XCTools.new.xcode_version).to be_a RunLoop::Version
            end
          end
        end
      end
    end
  end

  describe '#xcode_version_gte_70?' do
    it 'returns true for Xcode >= 7.0' do
      expect(xctools).to receive(:xcode_version).and_return(RunLoop::Version.new('7.0'))
      expect(xctools.xcode_version_gte_7?).to be == true
    end

    it 'returns false for Xcode < 7.0' do
      expect(xctools).to receive(:xcode_version).and_return(RunLoop::Version.new('6.4'))
      expect(xctools.xcode_version_gte_7?).to be == false
    end
  end

  describe '#xcode_version_gte_64?' do
    it 'returns true for Xcode >= 6.4' do
      expect(xctools).to receive(:xcode_version).and_return(RunLoop::Version.new('6.4'))
      expect(xctools.xcode_version_gte_64?).to be == true
    end

    it 'returns false for Xcode < 6.4' do
      expect(xctools).to receive(:xcode_version).and_return(RunLoop::Version.new('6.3'))
      expect(xctools.xcode_version_gte_64?).to be == false
    end
  end

  describe '#xcode_version_gte_63?' do
    it 'returns true for Xcode >= 6.3' do
      expect(xctools).to receive(:xcode_version).and_return(RunLoop::Version.new('6.3'))
      expect(xctools.xcode_version_gte_63?).to be == true
    end

    it 'returns false for Xcode < 6.3' do
      expect(xctools).to receive(:xcode_version).and_return(RunLoop::Version.new('6.2'))
      expect(xctools.xcode_version_gte_63?).to be == false
    end
  end

  describe '#xcode_version_gte_62?' do
    it 'returns true for Xcode >= 6.2' do
      expect(xctools).to receive(:xcode_version).and_return(RunLoop::Version.new('6.2'))
      expect(xctools.xcode_version_gte_62?).to be == true
    end

    it 'returns false for Xcode < 6.2' do
      expect(xctools).to receive(:xcode_version).and_return(RunLoop::Version.new('6.1'))
      expect(xctools.xcode_version_gte_62?).to be == false
    end
  end

  describe '#xcode_version_gte_61?' do
    it 'returns true for Xcode >= 6.1' do
      expect(xctools).to receive(:xcode_version).and_return(RunLoop::Version.new('6.1'))
      expect(xctools.xcode_version_gte_61?).to be == true
    end

    it 'returns false for Xcode < 6.1' do
      expect(xctools).to receive(:xcode_version).and_return(RunLoop::Version.new('6.0'))
      expect(xctools.xcode_version_gte_61?).to be == false
    end
  end

  describe '#xcode_version_gte_6?' do
    it 'returns true for Xcode >= 6.0' do
      expect(xctools).to receive(:xcode_version).and_return(RunLoop::Version.new('6.0'))
      expect(xctools.xcode_version_gte_6?).to be == true
    end

    it 'returns false for Xcode < 6.0' do
      expect(xctools).to receive(:xcode_version).and_return(RunLoop::Version.new('5.1.1'))
      expect(xctools.xcode_version_gte_6?).to be == false
    end
  end

  describe '#xcode_version_gte_51?' do
    it 'returns true for Xcode >= 5.1' do
      expect(xctools).to receive(:xcode_version).and_return(RunLoop::Version.new('5.1'))
      expect(xctools.xcode_version_gte_51?).to be == true
    end

    it 'returns false for Xcode < 5.1' do
      expect(xctools).to receive(:xcode_version).and_return(RunLoop::Version.new('5.0'))
      expect(xctools.xcode_version_gte_51?).to be == false
    end
  end

  describe '#xcode_is_beta?' do
    it 'returns true if the bundle name is Xcode-Beta.app' do
      stub_env('DEVELOPER_DIR', '/Xcode/6.2/Xcode-Beta.app/Contents/Developer')
      expect(RunLoop::XCTools.new.xcode_is_beta?).to be == true
    end

    it 'returns true if the bundle name is Xcode-Beta.app' do
      stub_env('DEVELOPER_DIR', '/Xcode/6.2/Xcode-beta.app/Contents/Developer')
      expect(RunLoop::XCTools.new.xcode_is_beta?).to be == true
    end

    it 'returns false if the bundle name is not Xcode-Beta.app' do
      stub_env('DEVELOPER_DIR', '/Xcode/6.2/Xcode.app/Contents/Developer')
      expect(RunLoop::XCTools.new.xcode_is_beta?).to be == false
    end
  end
end
