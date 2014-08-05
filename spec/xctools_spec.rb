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

    describe 'when argument is' do
      it ':version it returns cli version' do
        version = xctools.instruments(:version)
        expect(version >= RunLoop::Version.new('5.0')).to be true
      end

      it ':sims it returns list of installed simulators' do
        expect(xctools.instruments :sims).to be_a Array
      end

      describe ':templates it returns a list of templates for' do
        it 'the current Xcode version' do
          templates = xctools.instruments :templates
          expect(templates).to be_a Array
          expect(templates.empty?).to be false
        end

        xcode_installs = Resources.shared.alt_xcode_install_paths
        if xcode_installs.empty?
          rspec_info_log 'no alternative versions of Xcode >= 5.0 found in /Xcode directory'
        else
          xcode_installs.each do |developer_dir|
            it "#{developer_dir}" do
              ENV['DEVELOPER_DIR'] = developer_dir
              templates = xctools.instruments :templates
              expect(templates).to be_a Array
              expect(templates.empty?).to be false
            end
          end
        end
      end

      it ':devices it returns a list of iOS devices' do
        devices = xctools.instruments :devices
        expect(devices).to be_a Array
        unless devices.empty?
          expect(devices.all? { |device| device.is_a? RunLoop::Device }).to be == true
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

    it 'works for any Xcode version >= 5.0' do
      xcode_installs = Resources.shared.alt_xcode_install_paths
      if xcode_installs.empty?
        rspec_info_log 'no alternative versions of Xcode >= 5.0 found in /Xcode directory'
      else
        xcode_installs.each do |developer_dir|
          ENV['DEVELOPER_DIR'] = developer_dir
          expect(RunLoop::XCTools.new.xcode_version).to be_a RunLoop::Version
        end
      end
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

end
