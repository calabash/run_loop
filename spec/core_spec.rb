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
      options = {:app => Resources.shared.app_bundle_path}
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
    options = {:app => Resources.shared.app_bundle_path}
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

end