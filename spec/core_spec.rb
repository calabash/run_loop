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
      if xctools.xcode_version_gte_6?
        expect(actual).to be == 'Automation'
      else
        expect(File.exist?(actual)).to be == true
      end
    end
  end

  describe '.default_tracetemplate' do

    let (:xctools) { RunLoop::XCTools.new }

    describe 'returns a template for' do
      it "Xcode #{Resources.shared.current_xcode_version}" do
        default_template = RunLoop::Core.default_tracetemplate
        if xctools.xcode_version_gte_6?
          expect(default_template).to be == 'Automation'
        else
          expect(File.exist?(default_template)).to be true
        end
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
              if xctools.xcode_version_gte_6?
                expect(default_template).to be == 'Automation'
              else
                expect(File.exist?(default_template)).to be true
              end
            end
          end
        end
      end
    end
  end

  describe '.default_simulator' do
    it "when Xcode 5.1 it returns 'iPhone Retina (4-inch) - Simulator - iOS 7.1'" do
      version = RunLoop::Version.new('5.1')
      xctools = RunLoop::XCTools.new
      expect(xctools).to receive(:xcode_version).at_least(:once).and_return(version)
      expected = 'iPhone Retina (4-inch) - Simulator - iOS 7.1'
      actual = RunLoop::Core.default_simulator(xctools)
      expect(actual).to be == expected
    end

    it "when Xcode 5.1.1 it returns 'iPhone Retina (4-inch) - Simulator - iOS 7.1'" do
      version = RunLoop::Version.new('5.1.1')
      xctools = RunLoop::XCTools.new
      expect(xctools).to receive(:xcode_version).at_least(:once).and_return(version)
      expected = 'iPhone Retina (4-inch) - Simulator - iOS 7.1'
      actual = RunLoop::Core.default_simulator(xctools)
      expect(actual).to be == expected
    end

    it "when Xcode > 5 it returns 'iPhone 5 (8.0 Simulator)" do
      version = RunLoop::Version.new('6.0')
      xctools = RunLoop::XCTools.new
      expect(xctools).to receive(:xcode_version).at_least(:once).and_return(version)
      expected = 'iPhone 5 (8.0 Simulator)'
      actual = RunLoop::Core.default_simulator(xctools)
      expect(actual).to be == expected
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

  describe '.log_run_loop_options' do
    let(:options) {
      {
            :sim_control => RunLoop::SimControl.new,
            :app => "/Users/deltron0/git/run-loop/spec/resources/chou-cal.app",
            :args => [],
            :bundle_dir_or_bundle_id => "/Users/deltron0/git/run-loop/spec/resources/chou-cal.app",
            :device_target => "simulator",
            :log_file => "/var/folders/bx/5wplnzxx7492fynry0m_hw080000gp/T/run_loop20140902-3459-an9lx8/run_loop.out",
            :results_dir => "/var/folders/bx/5wplnzxx7492fynry0m_hw080000gp/T/run_loop20140902-3459-an9lx8",
            :results_dir_trace => "/var/folders/bx/5wplnzxx7492fynry0m_hw080000gp/T/run_loop20140902-3459-an9lx8/trace",
            :script => "/var/folders/bx/5wplnzxx7492fynry0m_hw080000gp/T/run_loop20140902-3459-an9lx8/_run_loop.js",
            :udid => "iPhone Retina (4-inch) - Simulator - iOS 7.1",
            :uia_strategy => :preferences,
      }
    }
    let(:xctools) { RunLoop::XCTools.new }

    before(:each) { ENV.delete('DEBUG') }
    after(:each) { ENV.delete('DEBUG') }

    it "when DEBUG != '1' it logs nothing" do
      ENV['DEBUG'] = '0'
      out = capture_stdout do
        RunLoop::Core.log_run_loop_options(options, xctools)
      end
      expect(out.string).to be == ''
    end

    describe "when DEBUG == '1'" do
      before(:each) { ENV['DEBUG'] = '1' }
      it 'does some logging' do
        out = capture_stdout do
          RunLoop::Core.log_run_loop_options(options, xctools)
        end
        expect(out.string).not_to be == ''
      end

      it 'does not print :sim_control key' do
        out = capture_stdout do
          RunLoop::Core.log_run_loop_options(options, xctools)
        end
        expect(out.string[/:sim_control/]).to be == nil
      end

      it 'does print xcode details' do
        out = capture_stdout do
          RunLoop::Core.log_run_loop_options(options, xctools)
        end
        expect(out.string[/:xcode/]).to be == ':xcode'
        expect(out.string[/:xcode_path/]).to be == ':xcode_path'
      end
    end
  end

  describe '.simulator_target?' do
    describe 'raises an error' do
      it 'when options argument is not a Hash' do
        expect { RunLoop::Core.simulator_target?([]) }.to raise_error TypeError
        expect { RunLoop::Core.simulator_target?(nil) }.to raise_error NoMethodError
      end

      describe 'returns true when' do
        it 'there is no :device_target key' do
          expect(RunLoop::Core.simulator_target?({})).to be == true
        end

        it ":device_target => 'simulator'" do
          options = { :device_target => 'simulator' }
          expect(RunLoop::Core.simulator_target?(options)).to be == true
        end

        it ":device_target => ''" do
          options = { :device_target => '' }
          expect(RunLoop::Core.simulator_target?(options)).to be == true
        end

        describe ":device_target => contains the word 'simulator'" do
          it 'Xcode >= 6.0' do
            options = { :device_target => 'iPhone 5 (8.0 Simulator)' }
            expect(RunLoop::Core.simulator_target?(options)).to be == true
          end

          it '5.1 <= Xcode <= 5.1.1' do
            options = { :device_target => 'iPhone Retina (4-inch) - Simulator - iOS 7.1' }
            expect(RunLoop::Core.simulator_target?(options)).to be == true
          end
        end

        if RunLoop::XCTools.new.xcode_version_gte_6?
          describe 'Xcode 6 behaviors' do
            it ":device_target => Xcode 6 simulator UDID" do
              options = { :device_target => '0BF52B67-F8BB-4246-A668-1880237DD17B' }
              expect(RunLoop::Core.simulator_target?(options)).to be == true
            end
          end

          describe "'named simulator'" do
            begin
              it ":device_target => 'rspec-test-device'" do
                device_type_id = 'iPhone 5s'
                runtime_id = 'com.apple.CoreSimulator.SimRuntime.iOS-8-0'
                cmd = "xcrun simctl create \"rspec-test-device\" \"#{device_type_id}\" \"#{runtime_id}\""
                udid = `#{cmd}`
                exit_code = $?.exitstatus
                expect(udid).to_not be == nil
                expect(exit_code).to be == 0
                options = { :device_target => 'rspec-test-device' }
                expect(RunLoop::Core.simulator_target?(options)).to be == true
              end
            ensure
              local_sim_control = RunLoop::SimControl.new
              simulators = local_sim_control.simulators
              simulators.each do |device|
                if device.name == 'rspec-test-device'
                  udid = device.udid
                  begin
                    puts "deleting device '#{device}'"
                    `xcrun simctl delete #{udid}`
                  rescue Exception => e
                    rspec_warn_log "Failed to remove named simulator: #{e}"
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
