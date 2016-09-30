require 'tmpdir'

describe RunLoop::Core do

  let(:simctl) { RunLoop::Simctl.new }
  let(:xcode) { Resources.shared.xcode }
  let(:instruments) { RunLoop::Instruments.new }

  it '.prepare' do
    # Rotates results directories
    expect(RunLoop::DotDir).to receive(:rotate_result_directories).and_return true

    expect(RunLoop::Core.send(:prepare, {})).to be == true
  end

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

    it "raises an error when Xcode >= 8.0" do
      expect(xcode).to receive(:version_gte_8?).and_return(true)
      allow(instruments).to receive(:xcode).and_return(xcode)

      expect do
        RunLoop::Core.default_tracetemplate(instruments)
      end.to raise_error RuntimeError, /There is no Automation template for this/
    end

    it 'raises an error when template cannot be found' do
      templates =
            [
                  "/Xcode/6.2/Xcode.app/Contents/Applications/Instruments.app/Contents/Resources/templates/Leaks.tracetemplate",
                  "/Xcode/6.2/Xcode.app/Contents/Applications/Instruments.app/Contents/Resources/templates/Network.tracetemplate",
                  "/Xcode/6.2/Xcode.app/Contents/Applications/Instruments.app/Contents/Resources/templates/System Trace.tracetemplate",
                  "/Xcode/6.2/Xcode.app/Contents/Applications/Instruments.app/Contents/Resources/templates/Time Profiler.tracetemplate",
            ]
      allow(instruments).to receive(:xcode).and_return(xcode)
      expect(instruments).to receive(:templates).and_return(templates)
      expect(xcode).to receive(:version_gte_8?).and_return(false)

      expect do
        RunLoop::Core.default_tracetemplate(instruments)
      end.to raise_error RuntimeError,
                         /Expected instruments to report an Automation tracetemplate/
    end
  end

  describe "UIA strategy and instruments script" do
    let(:xcode) { Resources.shared.xcode }
    let(:device) { Resources.shared.device }
    let(:simulator) { Resources.shared.simulator }
    let(:ios8) { RunLoop::Version.new("8.0") }
    let(:ios9) { RunLoop::Version.new("9.0") }
    let(:ios7) { RunLoop::Version.new("7.0") }

    describe ".default_uia_strategy" do
      it ":host for Xcode >= 7.0" do
        expect(xcode).to receive(:version_gte_7?).and_return(true)

        expect(RunLoop::Core.default_uia_strategy(device, xcode)).to be == :host
      end

      describe "all other Xcode versions" do
        before do
          expect(xcode).to receive(:version_gte_7?).at_least(:once).and_return(false)
        end

        describe "physical devices" do
           it ":host for iOS >= 8.0" do
             expect(device).to receive(:version).and_return(ios8)
             expect(RunLoop::Core.default_uia_strategy(device, xcode)).to be == :host

             expect(device).to receive(:version).and_return(ios9)
             expect(RunLoop::Core.default_uia_strategy(device, xcode)).to be == :host
           end

          it ":preferences for iOS < 8.0" do
            expect(device).to receive(:version).and_return(ios7)
            expect(RunLoop::Core.default_uia_strategy(device, xcode)).to be == :preferences
          end
        end

        it "simulators in < Xcode 7 environments" do
          # implies < iOS 9
          expect(RunLoop::Core.default_uia_strategy(simulator, xcode)).to be == :preferences
        end
      end
    end

    describe ".detect_uia_strategy" do
      let(:options) { {:uia_strategy => :shared_element } }

      it "respects :uia_strategy option" do
        actual = RunLoop::Core.detect_uia_strategy(options, device, xcode)
        expect(actual).to be == options[:uia_strategy]
      end

      it "falls back on default strategy" do
        options[:uia_strategy] = nil
        expect(RunLoop::Core).to receive(:default_uia_strategy).and_return(:shared_element)

        actual = RunLoop::Core.detect_uia_strategy(options, device, xcode)
        expect(actual).to be == :shared_element
      end

      it "raises error if strategy is unknown" do
        options[:uia_strategy] = :unknown

        expect do
          RunLoop::Core.detect_uia_strategy(options, device, xcode)
        end.to raise_error ArgumentError, /Invalid strategy/
      end
    end

    describe ".detect_instrument_script_and_strategy" do
      let(:options) { { } }
      let(:path) { "path/to/some/instruments_script.js" }

      describe "user set :script" do

        before do
          options[:script] =path
          expect(RunLoop::Core).to receive(:expect_instruments_script).with(path).and_return(path)
        end

        it "user did not pass a :uia_strategy" do
          options[:uia_strategy] = nil

          actual = RunLoop::Core.detect_instruments_script_and_strategy(options,
                                                                        device,
                                                                        xcode)
          expect(actual[:script]).to be == path
          expect(actual[:strategy]).to be == :host
        end

        it "user passed a :uia_strategy" do
          options[:uia_strategy] = :preferences

          actual = RunLoop::Core.detect_instruments_script_and_strategy(options,
                                                                        device,
                                                                        xcode)
          expect(actual[:script]).to be == path
          expect(actual[:strategy]).to be == options[:uia_strategy]
        end
      end

      describe "user did not set :script" do

        before do
          options[:script] = nil
        end

        it "user set strategy" do
          options[:uia_strategy] = :strategy
          expect(RunLoop::Core).to receive(:instruments_script_for_uia_strategy).with(:strategy).and_return(path)

          actual = RunLoop::Core.detect_instruments_script_and_strategy(options,
                                                                        device,
                                                                        xcode)
          expect(actual[:script]).to be == path
          expect(actual[:strategy]).to be == :strategy
        end

        describe "user did not set strategy" do
          it "user set :calabash_lite" do
            options[:uia_strategy] = nil
            options[:calabash_lite] = true
            expect(RunLoop::Core).to receive(:instruments_script_for_uia_strategy).with(:host).and_return(path)

            actual = RunLoop::Core.detect_instruments_script_and_strategy(options, device, xcode)
            expect(actual[:script]).to be == path
            expect(actual[:strategy]).to be == :host
          end

          it "user did not set :calabash_lite" do
            expect(RunLoop::Core).to receive(:detect_uia_strategy).and_return(:strategy)
            expect(RunLoop::Core).to receive(:instruments_script_for_uia_strategy).with(:strategy).and_return(path)

            actual = RunLoop::Core.detect_instruments_script_and_strategy(options,
                                                                          device,
                                                                          xcode)
            expect(actual[:script]).to be == path
            expect(actual[:strategy]).to be == :strategy
          end
        end
      end
    end
  end

  describe '.default_simulator' do
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

    it 'Xcode 7.0*' do
      expected = 'iPhone 5s (9.0)'
      expect(xcode).to receive(:version).at_least(:once).and_return xcode.v70
      expect(RunLoop::Core.default_simulator(xcode)).to be == expected
    end

    it 'Xcode 7.1*' do
      expected = 'iPhone 6s (9.1)'
      expect(xcode).to receive(:version).at_least(:once).and_return xcode.v71
      expect(RunLoop::Core.default_simulator(xcode)).to be == expected
    end

    it 'Xcode 7.2*' do
      expected = 'iPhone 6s (9.2)'
      expect(xcode).to receive(:version).at_least(:once).and_return xcode.v72
      expect(RunLoop::Core.default_simulator(xcode)).to be == expected
    end

    it 'Xcode >= 7.3' do
      expected = 'iPhone 6s (9.3)'
      expect(xcode).to receive(:version).at_least(:once).and_return xcode.v73
      expect(RunLoop::Core.default_simulator(xcode)).to be == expected
    end

    it 'Xcode >= 8.0' do
      expected = 'iPhone 7 (10.0)'
      expect(xcode).to receive(:version).at_least(:once).and_return xcode.v80
      expect(RunLoop::Core.default_simulator(xcode)).to be == expected
    end

    it 'Xcode >= 8.1' do
      expected = 'iPhone 7 (10.1)'
      expect(xcode).to receive(:version).at_least(:once).and_return xcode.v81
      expect(RunLoop::Core.default_simulator(xcode)).to be == expected
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

  describe '.log_run_loop_options' do
    let(:options) {
      {
            :simctl => RunLoop::Simctl.new,
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
          allow_any_instance_of(RunLoop::Simctl).to receive(:simulators).and_return [device]
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

  describe ".detect_flush_uia_log_option" do
    let (:options) { {} }
    describe ":no_flush legacy key" do
      it ":no_flush => false" do
        options[:no_flush] = false
        expect(RunLoop::Core.send(:detect_flush_uia_log_option, options)).to be_truthy
      end

      it ":no_flush => true" do
        options[:no_flush] = true
        expect(RunLoop::Core.send(:detect_flush_uia_log_option, options)).to be_falsey
      end
    end

    describe ":flush_uia_logs" do
      it "key does not exist" do
        expect(RunLoop::Core.send(:detect_flush_uia_log_option, options)).to be_truthy
      end

      it ":flush_uia_logs => true" do
        options[:flush_uia_logs] = true
        expect(RunLoop::Core.send(:detect_flush_uia_log_option, options)).to be_truthy
      end

      it ":flush_uia_logs => false" do
        options[:flush_uia_logs] = false
        expect(RunLoop::Core.send(:detect_flush_uia_log_option, options)).to be_falsey
      end
    end
  end

  describe '.expect_simulator_compatible_arch' do
    let(:device) { RunLoop::Device.new('Sim', '8.0', 'UDID') }

    let(:fat_arm_app) { RunLoop::App.new(Resources.shared.app_bundle_path_arm_FAT) }
    let(:i386_app) { RunLoop::App.new(Resources.shared.app_bundle_path_i386) }

    it 'raises an error' do
      expect(device).to receive(:instruction_set).and_return 'nonsense'

      expect do
        RunLoop::Core.expect_simulator_compatible_arch(device, fat_arm_app)
      end.to raise_error RunLoop::IncompatibleArchitecture,
                         /does not contain a compatible architecture for target device/
    end

    it 'compatible' do
      expect(device).to receive(:instruction_set).and_return 'i386'

      expect do
        RunLoop::Core.expect_simulator_compatible_arch(device, i386_app)
      end.not_to raise_error
    end
  end

  describe ".detect_reset_options" do
    let(:options) { {reset: true, reset_app_sandbox: true} }

    describe ":reset" do
      it "true" do
        expect(RunLoop::Core.detect_reset_options(options)).to be_truthy
      end

      it "false" do
        options[:reset] = false
        expect(RunLoop::Core.detect_reset_options(options)).to be_falsey
      end
    end

    describe ":reset_app_sandbox" do
      before { options.delete(:reset) }
      it "true" do
        expect(RunLoop::Core.detect_reset_options(options)).to be_truthy
      end

      it "false" do
        options[:reset_app_sandbox] = false
        expect(RunLoop::Core.detect_reset_options(options)).to be_falsey
      end
    end

    describe "RESET_BETWEEN_SCENARIOS" do
      before do
        options.delete(:reset)
        options.delete(:reset_app_sandbox)
      end

      it "'1'" do
        expect(RunLoop::Environment).to receive(:reset_between_scenarios?).and_return(true)

        expect(RunLoop::Core.detect_reset_options(options)).to be_truthy
      end

      it "not '1'" do
        expect(RunLoop::Environment).to receive(:reset_between_scenarios?).and_return(false)

        expect(RunLoop::Core.detect_reset_options(options)).to be_falsey
      end
    end

    describe ".expect_instrument_script" do
      describe "script is a string" do
        let(:script) { "path/to/a/javascript.js" }

        it "is valid if string is a path to a file" do
          expect(File).to receive(:exist?).with(script).and_return(true)

          actual = RunLoop::Core.send(:expect_instruments_script, script)
          expect(actual).to be == script
        end

        it "raises an error if file does not exist" do
          expect(File).to receive(:exist?).with(script).and_return(false)

          expect do
            RunLoop::Core.send(:expect_instruments_script, script)
          end.to raise_error RuntimeError, /Expected instruments JavaScript file at path:/
        end
      end

      describe "script is symbol" do
        let(:script) { :some_key }
        let(:path) { "path/to/lib/script" }

        it "is valid if it indicates a known script" do
          expect(RunLoop::Core).to receive(:script_for_key).with(script).and_return(path)

          actual = RunLoop::Core.send(:expect_instruments_script, script)
          expect(actual).to be == path
        end

        it "raises an error if there is no known script for symbol" do
          expect(RunLoop::Core).to receive(:script_for_key).with(script).and_return(nil)

          expect do
            RunLoop::Core.send(:expect_instruments_script, script)
          end.to raise_error RuntimeError, /Expected :some_key to be one of:/
        end
      end

      it "raises an error if script is not a symbol or string" do
        script = [1, 2, 3]
        expect do
          RunLoop::Core.send(:expect_instruments_script, script)
        end.to raise_error RuntimeError, /Expected '\[1, 2, 3\]' to be a Symbol or a String/
      end
    end

    describe ".instruments_script_for_uia_strategy" do
      it ":preferences" do
        expect(RunLoop::Core).to receive(:script_for_key).with(:run_loop_fast_uia).and_call_original

        actual = RunLoop::Core.send(:instruments_script_for_uia_strategy, :preferences)
        expect(actual[/run_loop_fast_uia/, 0]).to be_truthy
      end

      it ":host" do
        expect(RunLoop::Core).to receive(:script_for_key).with(:run_loop_host).and_call_original

        actual = RunLoop::Core.send(:instruments_script_for_uia_strategy, :host)
        expect(actual[/run_loop_host/, 0]).to be_truthy
      end

      it ":shared_element" do
        expect(RunLoop::Core).to receive(:script_for_key).with(:run_loop_shared_element).and_call_original

        actual = RunLoop::Core.send(:instruments_script_for_uia_strategy, :shared_element)
        expect(actual[/run_loop_shared_element/, 0]).to be_truthy
      end

      it "no strategy" do
        expect(RunLoop::Core).to receive(:script_for_key).with(:run_loop_basic).and_call_original

        actual = RunLoop::Core.send(:instruments_script_for_uia_strategy, :unknown)
        expect(actual[/run_loop_basic/, 0]).to be_truthy
      end
    end
  end
end

