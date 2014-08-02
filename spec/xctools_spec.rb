describe RunLoop::XCTools do

  before(:each) { ENV.delete('DEVELOPER_DIR') }

  subject(:xctools) { RunLoop::XCTools.new }

  describe '#xcode_developer_dir' do
    it 'respects the DEVELOPER_DIR env var' do
      ENV['DEVELOPER_DIR'] = '/foo/bar'
      expect(xctools.xcode_developer_dir).to be == ENV['DEVELOPER_DIR']
    end

    it 'or it returns the value of xcode-select' do
      actual = `xcode-select --print-path`.chomp
      expect(xctools.xcode_developer_dir).to be == actual
    end
  end

  describe '#instruments' do
    it 'checks its arguments' do
      expect { xctools.instruments(:foo) }.to raise_error(ArgumentError)
    end

    it "no argument returns 'xcrun instruments'" do
      expect(xctools.instruments).to be == 'xcrun instruments'
    end

    it ':version returns cli version' do
      version = xctools.instruments(:version)
      expect(version >= RunLoop::Version.new('5.0')).to be true
    end

    it ':sims returns list of installed simulators' do
      expect(xctools.instruments :sims).to be_a Array
    end

    describe 'when argument is :templates ' do
      it 'returns a list of templates for current Xcode version' do
        templates = xctools.instruments :templates
        expect(templates).to be_a Array
        expect(templates.empty?).to be false
      end

      it 'returns a list of templates for Xcode >= 5.0' do
        xcode_installs = Resources.shared.alt_xcode_install_paths
        if xcode_installs.empty?
          puts 'INFO: no alternative versions of Xcode >= 5.0 found in /Xcode directory'
        else
          xcode_installs.each do |developer_dir|
            ENV['DEVELOPER_DIR'] = developer_dir
            templates = xctools.instruments :templates
            expect(templates).to be_a Array
            expect(templates.empty?).to be false
          end
        end
      end
    end
  end

  describe '#instruments_supports_hypen_s?' do
    it { expect(xctools.instruments_supports_hyphen_s? '6.0' ).to be == true }
    it { expect(xctools.instruments_supports_hyphen_s? '5.1.1').to be == true }
    it { expect(xctools.instruments_supports_hyphen_s? '5.1' ).to be == true }
    it { expect(xctools.instruments_supports_hyphen_s? '5.0.2').to be == false }
    it { expect(xctools.instruments_supports_hyphen_s? '4.6.3').to be == false }
  end

  describe '#xc60' do
    it { expect(xctools.xc60).to be == RunLoop::Version.new('6.0') }
  end

  describe '#xc50' do
    it { expect(xctools.xc50).to be == RunLoop::Version.new('5.0') }
  end

  describe '#xc51' do
    it { expect(xctools.xc51).to be == RunLoop::Version.new('5.1') }
  end

  describe '#xcode_version' do
    it 'returns the current Xcode version as a RunLoop::Version' do
      expect(xctools.xcode_version).to be_a RunLoop::Version
    end

    it 'works for any Xcode version >= 5.0' do
      xcode_installs = Resources.shared.alt_xcode_install_paths
      if xcode_installs.empty?
        puts 'INFO: no alternative versions of Xcode >= 5.0 found in /Xcode directory'
      else
        xcode_installs.each do |developer_dir|
          ENV['DEVELOPER_DIR'] = developer_dir
          expect(RunLoop::XCTools.new.xcode_version).to be_a RunLoop::Version
        end
      end
    end
  end
end
