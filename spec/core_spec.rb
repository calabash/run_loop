require 'tmpdir'

describe RunLoop::Core do

  before(:each) {
    ENV.delete('DEVELOPER_DIR')
    ENV.delete('TRACE_TEMPLATE')
  }

  describe '.automation_template' do

    after(:each) { ENV.delete('TRACE_TEMPLATE') }

    it 'respects the TRACE_TEMPLATE env var if the tracetemplate exists' do
      dir = Dir.mktmpdir('tracetemplate')
      tracetemplate = File.expand_path(File.join(dir, 'some.tracetemplate'))
      FileUtils.touch tracetemplate
      ENV['TRACE_TEMPLATE']=tracetemplate
      xctools = RunLoop::XCTools.new
      expect(RunLoop::Core.automation_template xctools).to be == tracetemplate
    end

    it 'ignores the TRACE_TEMPLATE env var if the tracetemplate does not exist' do
      tracetemplate = '/tmp/some.tracetemplate'
      ENV['TRACE_TEMPLATE']=tracetemplate
      xctools = RunLoop::XCTools.new
      actual = RunLoop::Core.automation_template(xctools)
      expect(actual).not_to be == nil
      expect(actual).not_to be == tracetemplate
      expect(File.exist?(actual)).to be == true
    end

  end

  describe '.default_tracetemplate' do
    describe 'returns a template for' do
      it "Xcode #{Resources.shared.current_xcode_version}" do
        default_template = RunLoop::Core.default_tracetemplate
        expect(File.exist?(default_template)).to be true
      end

      describe 'regression' do
        xcode_installs = Resources.shared.alt_xcode_install_paths
        # if no /Xcode/*/*.app are found, there is no test - lucky you. :)
        if xcode_installs.empty?
          it 'no alternative versions of Xcode found' do
            expect(true).to be == true
          end
        else
          xcode_installs.each do |developer_dir|
            it "#{developer_dir}" do
              ENV['DEVELOPER_DIR'] = developer_dir
              default_template = RunLoop::Core.default_tracetemplate
              expect(File.exist?(default_template)).to be true
            end
          end
        end
      end
    end
  end

  describe '.udid_and_bundle_for_launcher' do
    describe 'when 5.1 <= xcode < 6.0' do
      options = {:app => Resources.shared.cal_app_bundle_path}
      valid_targets = [nil, '', 'simulator']
      valid_versions = ['5.1', '5.1.1'].map { |elm| RunLoop::Version.new(elm) }
      valid_targets.each do |target|
        valid_versions.each do |version|
          it "returns 'iPhone Retina (4-inch) - Simulator - iOS 7.1' for Xcode '#{version}' if simulator = '#{target.nil? ? 'nil' : target }'" do
            xctools = RunLoop::XCTools.new
            expect(xctools).to receive(:xcode_version).at_least(:once).and_return(version)
            udid, apb = RunLoop::Core.udid_and_bundle_for_launcher(target, options, xctools)
            expect(udid).to be == 'iPhone Retina (4-inch) - Simulator - iOS 7.1'
            expect(apb).to be == options[:app]
          end
        end
      end
    end
  end

  describe 'when xcode >= 6.0' do
    options = {:app => Resources.shared.cal_app_bundle_path}
    valid_targets = [nil, '', 'simulator']
    valid_versions = ['6.0'].map { |elm| RunLoop::Version.new(elm) }
    valid_targets.each do |target|
      valid_versions.each do |version|
        it "returns 'iPhone 5 (8.0 Simulator)' for Xcode '#{version}' if simulator = '#{target.nil? ? 'nil' : target }'" do
          xctools = RunLoop::XCTools.new
          expect(xctools).to receive(:xcode_version).at_least(:once).and_return(version)
          udid, apb = RunLoop::Core.udid_and_bundle_for_launcher(target, options, xctools)
          expect(udid).to be == 'iPhone 5 (8.0 Simulator)'
          expect(apb).to be == options[:app]
        end
      end
    end
  end

  describe '.above_or_eql_version?' do
    subject(:a) { RunLoop::Version.new('5.1.1') }
    subject(:b) { RunLoop::Version.new('6.0') }
    describe 'returns correct value when' do
      it 'both args are RunLoop::Version' do
        expect(RunLoop::Core.above_or_eql_version? a, b).to be == false
        expect(RunLoop::Core.above_or_eql_version? b, a).to be == true
      end

      it 'both args are Strings' do
        expect(RunLoop::Core.above_or_eql_version? a.to_s, b.to_s).to be == false
        expect(RunLoop::Core.above_or_eql_version? b.to_s, a.to_s).to be == true
      end
    end
  end

  describe '.dylib_path_from_options' do
    describe 'raises an error' do
      # @todo this test is probably unnecessary
      it 'when options argument is not a Hash' do
        expect { RunLoop::Core.dylib_path_from_options([]) }.to raise_error TypeError
        expect { RunLoop::Core.dylib_path_from_options(nil) }.to raise_error NoMethodError
      end

      it 'when :inject_dylib is not a String' do
        options = { :inject_dylib => true }
        expect { RunLoop::Core.dylib_path_from_options(options) }.to raise_error ArgumentError
      end

      it 'when dylib does not exist' do
        options = { :inject_dylib => 'foo/bar.dylib' }
        expect { RunLoop::Core.dylib_path_from_options(options) }.to raise_error RuntimeError
      end
    end

    describe 'returns' do
      it 'nil if options does not contain :inject_dylib key' do
        expect(RunLoop::Core.dylib_path_from_options({})).to be == nil
      end

      it 'value of :inject_dylib key if the path exists' do
        path = Resources.shared.sim_dylib_path
        options = { :inject_dylib => path }
        expect(RunLoop::Core.dylib_path_from_options(options)).to be == path
      end
    end
  end
end
