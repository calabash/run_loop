describe RunLoop::Core do

  before(:each) { ENV.delete('DEVELOPER_DIR') }

  describe '.default_tracetemplate' do

    it 'returns a template for current version of Xcode' do
      default_template = RunLoop::Core.default_tracetemplate
      expect(File.exist?(default_template)).to be true
    end

    xcode_installs = Resources.shared.alt_xcode_install_paths
    # if no /Xcode/*/*.app are found, there is no test - lucky you. :)
    if xcode_installs.empty?
      rspec_info_log 'no alternative versions of Xcode >= 5.0 found in /Xcode directory'
    else
      xcode_installs.each do |developer_dir|
        it "returns a template for Xcode '#{developer_dir}'" do
          ENV['DEVELOPER_DIR'] = developer_dir
          default_template = RunLoop::Core.default_tracetemplate
          expect(File.exist?(default_template)).to be true
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