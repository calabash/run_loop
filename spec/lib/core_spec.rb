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

  describe '.default_simulator' do
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

    it 'Xcode >= 8.2' do
      expected = 'iPhone 7 (10.2)'
      expect(xcode).to receive(:version).at_least(:once).and_return xcode.v82
      expect(RunLoop::Core.default_simulator(xcode)).to be == expected
    end

    it 'Xcode >= 8.3' do
      expected = 'iPhone 7 (10.3)'
      expect(xcode).to receive(:version).at_least(:once).and_return xcode.v83
      expect(RunLoop::Core.default_simulator(xcode)).to be == expected
    end

    it 'Xcode >= 9.0' do
      expected = 'iPhone 8 (11.0)'
      expect(xcode).to receive(:version).at_least(:once).and_return xcode.v90
      expect(RunLoop::Core.default_simulator(xcode)).to be == expected
    end

    it 'Xcode >= 9.1' do
      expected = 'iPhone 8 (11.1)'
      expect(xcode).to receive(:version).at_least(:once).and_return xcode.v91
      expect(RunLoop::Core.default_simulator(xcode)).to be == expected
    end

    it 'Xcode >= 9.2' do
      expected = 'iPhone 8 (11.2)'
      expect(xcode).to receive(:version).at_least(:once).and_return xcode.v92
      expect(RunLoop::Core.default_simulator(xcode)).to be == expected
    end

    it 'Xcode >= 9.3' do
      expected = 'iPhone 8 (11.3)'
      expect(xcode).to receive(:version).at_least(:once).and_return xcode.v93
      expect(RunLoop::Core.default_simulator(xcode)).to be == expected
    end

    it 'Xcode >= 9.4' do
      expected = 'iPhone 8 (11.4)'
      expect(xcode).to receive(:version).at_least(:once).and_return xcode.v94
      expect(RunLoop::Core.default_simulator(xcode)).to be == expected
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

