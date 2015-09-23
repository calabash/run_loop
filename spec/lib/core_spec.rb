require 'tmpdir'

describe RunLoop::Core do

  let(:sim_control) { RunLoop::SimControl.new }
  let(:xcode) { sim_control.xcode }
  let(:instruments) { RunLoop::Instruments.new }

  describe '.automation_template' do

    it 'respects the TRACE_TEMPLATE env var if the tracetemplate exists' do
      dir = Dir.mktmpdir('tracetemplate')
      tracetemplate = File.expand_path(File.join(dir, 'some.tracetemplate'))
      FileUtils.touch tracetemplate
      expect(RunLoop::Environment).to receive(:trace_template).and_return(tracetemplate)
      expect(RunLoop::Core.automation_template(instruments)).to be == tracetemplate
    end
  end

  describe '.default_tracetemplate' do
    it 'raises an error when template cannot be found' do
      templates =
            [
                  "/Xcode/6.2/Xcode.app/Contents/Applications/Instruments.app/Contents/Resources/templates/Leaks.tracetemplate",
                  "/Xcode/6.2/Xcode.app/Contents/Applications/Instruments.app/Contents/Resources/templates/Network.tracetemplate",
                  "/Xcode/6.2/Xcode.app/Contents/Applications/Instruments.app/Contents/Resources/templates/System Trace.tracetemplate",
                  "/Xcode/6.2/Xcode.app/Contents/Applications/Instruments.app/Contents/Resources/templates/Time Profiler.tracetemplate",
            ]
      expect(instruments).to receive(:templates).and_return(templates)

      expect do
        RunLoop::Core.default_tracetemplate(instruments)
      end.to raise_error(RuntimeError)
    end
  end

  describe '.default_simulator' do
    it 'Xcode < 6.0' do
      expected = 'iPhone Retina (4-inch) - Simulator - iOS 7.1'
      expect(xcode).to receive(:version).at_least(:once).and_return xcode.v51
      expect(RunLoop::Core.default_simulator(xcode)).to be == expected
    end

    it 'Xcode 6.0*' do
      expected = 'iPhone 5s (8.0 Simulator)'
      expect(xcode).to receive(:version).at_least(:once).and_return xcode.v60
      expect(RunLoop::Core.default_simulator(xcode)).to be == expected
    end

    it 'Xcode 6.1*' do
      expected = 'iPhone 5s (8.1 Simulator)'
      expect(xcode).to receive(:version).at_least(:once).and_return xcode.v61
      expect(RunLoop::Core.default_simulator(xcode)).to be == expected
    end

    it 'Xcode 6.2*' do
      expected = 'iPhone 5s (8.2 Simulator)'
      expect(xcode).to receive(:version).at_least(:once).and_return xcode.v62
      expect(RunLoop::Core.default_simulator(xcode)).to be == expected
    end

    it 'Xcode 6.3*' do
      expected = 'iPhone 5s (8.3 Simulator)'
      expect(xcode).to receive(:version).at_least(:once).and_return xcode.v63
      expect(RunLoop::Core.default_simulator(xcode)).to be == expected
    end

    it 'Xcode 6.4*' do
      expected = 'iPhone 5s (8.4 Simulator)'
      expect(xcode).to receive(:version).at_least(:once).and_return xcode.v64
      expect(RunLoop::Core.default_simulator(xcode)).to be == expected
    end

    it 'Xcode >= 7.0' do
      expected = 'iPhone 5s (9.0)'
      expect(xcode).to receive(:version).at_least(:once).and_return xcode.v70
      expect(RunLoop::Core.default_simulator(xcode)).to be == expected
    end

    it 'Xcode > 7.1' do
      expected = 'iPhone 6s (9.1)'
      expect(xcode).to receive(:version).at_least(:once).and_return xcode.v71
      expect(RunLoop::Core.default_simulator(xcode)).to be == expected
    end
  end

  describe '.udid_and_bundle_for_launcher' do
    let(:options) { {:app => Resources.shared.cal_app_bundle_path} }
    let(:app) { options[:app] }

    before do
      expect(xcode).to receive(:version).and_return xcode.v51
      expect(RunLoop::Core).to receive(:default_simulator).with(xcode).and_return 'Simulator'
    end


    it 'target is nil' do
      udid, app_bundle = RunLoop::Core.udid_and_bundle_for_launcher(nil, options, sim_control)
      expect(udid).to be == 'Simulator'
      expect(app_bundle).to be == app
    end

    it "target is ''" do
      udid, app_bundle = RunLoop::Core.udid_and_bundle_for_launcher('', options, sim_control)
      expect(udid).to be == 'Simulator'
      expect(app_bundle).to be == app
    end

    it "target is 'simulator'" do
      udid, app_bundle = RunLoop::Core.udid_and_bundle_for_launcher('simulator', options, sim_control)
      expect(udid).to be == 'Simulator'
      expect(app_bundle).to be == app
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

    let(:xcode) { RunLoop::Xcode.new }

    it "when DEBUG != '1' it logs nothing" do
      stub_env('DEBUG', '0')
      out = capture_stdout do
        RunLoop::Core.log_run_loop_options(options, xcode)
      end
      expect(out.string).to be == ''
    end

    describe "when DEBUG == '1'" do
      before(:each) { stub_env('DEBUG', '1') }
      it 'does some logging' do
        out = capture_stdout do
          RunLoop::Core.log_run_loop_options(options, xcode)
        end
        expect(out.string).not_to be == ''
      end

      it 'does not print :sim_control key' do
        out = capture_stdout do
          RunLoop::Core.log_run_loop_options(options, xcode)
        end
        expect(out.string[/:sim_control/]).to be == nil
      end

      it 'does print xcode details' do
        out = capture_stdout do
          RunLoop::Core.log_run_loop_options(options, xcode)
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

      describe 'CoreSimulator' do
        let(:xcode) { RunLoop::Xcode.new }

        let(:options) { { :device_target => '0BF52B67-F8BB-4246-A668-1880237DD17B' } }

        let(:device) { RunLoop::Device.new('HATS', '8.4', options[:device_target]) }

        before do
          expect(xcode).to receive(:version).at_least(:once).and_return xcode.v70
          allow_any_instance_of(RunLoop::SimControl).to receive(:xcode).and_return xcode
          allow_any_instance_of(RunLoop::SimControl).to receive(:simulators).and_return [device]
        end

        it ':device_target => CoreSimulator UDID' do
          expect(RunLoop::Core.simulator_target?(options)).to be == true
        end

        it ':device_target => Named simulator' do
          options[:device_target] = device.name
          device.instance_variable_set(:@uuid, 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA')

          expect(RunLoop::Core.simulator_target?(options)).to be == true
        end

        it ':device_target => Instruments identifier' do
          options[:device_target] = device.instruments_identifier(xcode)
          device.instance_variable_set(:@uuid, 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA')

          expect(RunLoop::Core.simulator_target?(options)).to be == true
        end
      end

      it 'returns false when target is a physical device' do
        options = { :device_target => '49b59706a3ac25e997770a91577ef4e6ad0ab7bb' }
        expect(RunLoop::Core.simulator_target?(options)).to be == false
      end
    end
  end

  describe '.expect_simulator_compatible_arch' do
    let(:xcode) { RunLoop::Xcode.new }

    let(:device) { RunLoop::Device.new('Sim', '8.0', 'UDID') }

    it 'is not implemented for Xcode < 6.0' do
      expect(xcode).to receive(:version_gte_6?).and_return false

      actual = RunLoop::Core.expect_simulator_compatible_arch(nil, nil, xcode)
      expect(actual).to be_falsey
    end

    describe 'CoreSimulator' do

      let(:fat_arm_app) { RunLoop::App.new(Resources.shared.app_bundle_path_arm_FAT) }
      let(:i386_app) { RunLoop::App.new(Resources.shared.app_bundle_path_i386) }

      before do
        expect(xcode).to receive(:version_gte_6?).and_return true
      end

      it 'raises an error' do
        expect(device).to receive(:instruction_set).and_return 'nonsense'

        expect do
          RunLoop::Core.expect_simulator_compatible_arch(device, fat_arm_app, xcode)
        end.to raise_error RunLoop::IncompatibleArchitecture,
                           /does not contain a compatible architecture for target device/
      end

      it 'compatible' do
        expect(device).to receive(:instruction_set).and_return 'i386'

        expect do
          RunLoop::Core.expect_simulator_compatible_arch(device, i386_app, xcode)
        end.not_to raise_error
      end
    end
  end
end
