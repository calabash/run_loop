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

    it 'Xcode > 7.0' do
      expected = 'iPhone 5s (9.0)'
      expect(xcode).to receive(:version).at_least(:once).and_return xcode.v70
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

      it ":device_target => CoreSimulator UDID" do
        options = { :device_target => '0BF52B67-F8BB-4246-A668-1880237DD17B' }
        expect(RunLoop::Core.simulator_target?(options)).to be == true
      end

      it 'returns false when target is a physical device' do
        options = { :device_target => '49b59706a3ac25e997770a91577ef4e6ad0ab7bb' }
        expect(RunLoop::Core.simulator_target?(options)).to be == false
      end
    end
  end

  describe '.expect_compatible_simulator_architecture' do
    it 'is not implemented for Xcode < 6.0' do
      sim_control = RunLoop::SimControl.new
      expect(sim_control).to receive(:xcode_version_gte_6?).and_return(false)
      expect(
            RunLoop::Core.expect_compatible_simulator_architecture({},
                                                                   sim_control)
      ).to be == false
    end

    context 'raises error' do
      it 'when launch_options[:udid] cannot be used to find simulator' do
       launch_options = {:udid => 'invalid simulator id' }
       sim_control = RunLoop::SimControl.new

       if Resources.shared.core_simulator_env?
         expect {
           RunLoop::Core.expect_compatible_simulator_architecture(launch_options,
                                                                  sim_control)
         }.to raise_error RuntimeError
       else
         expect do
           RunLoop::Core.expect_compatible_simulator_architecture(launch_options,
                                                                  sim_control)
         end.not_to raise_error
       end
      end

      it 'when architecture is incompatible with instruction set of target device' do
        launch_options = {:udid =>  RunLoop::Core.default_simulator,
                          :bundle_dir_or_bundle_id => Resources.shared.app_bundle_path_arm_FAT }
        sim_control = RunLoop::SimControl.new

        if Resources.shared.core_simulator_env?
          expect_any_instance_of(RunLoop::Device).to receive(:instruction_set).and_return('nonsense')

          expect do
            RunLoop::Core.expect_compatible_simulator_architecture(launch_options,
                                                                   sim_control)
          end.to raise_error RunLoop::IncompatibleArchitecture
        else
          expect do
            RunLoop::Core.expect_compatible_simulator_architecture(launch_options,
                                                                   sim_control)
          end.not_to raise_error
        end
      end
    end

    subject {
      RunLoop::Core.expect_compatible_simulator_architecture(launch_options,
                                                             sim_control)
    }


    context 'simulator an binary are compatible' do
      let(:sim_control) { RunLoop::SimControl.new }
      let(:launch_options) { { :udid =>  RunLoop::Core.default_simulator,
                               :bundle_dir_or_bundle_id =>
                                     Resources.shared.app_bundle_path_i386
      }}
      it do
        if Resources.shared.core_simulator_env?
          is_expected.to be == true
        else
          Luffa.log_warn('Skipping test - Xcode < 6 detected')
        end
      end
    end
  end
end
