if Resources.shared.core_simulator_env?
  require 'run_loop/cli/simctl'

  describe RunLoop::CLI::Simctl do

    let(:sim_control) { RunLoop::SimControl.new }
    let(:xcode) { sim_control.xcode }

    let(:bridge) {
      default = RunLoop::Core.default_simulator
      device = sim_control.simulators.detect do |sim|
        sim.instruments_identifier(xcode) == default
      end
      RunLoop::Simctl::Bridge.new(device, Resources.shared.app_bundle_path)
    }

    describe 'run-loop simctl booted' do

      let(:cmd) { 'run-loop simctl booted' }

      before {
        bridge.shutdown
      }

      it 'puts message about no booted devices' do
        allow_any_instance_of(RunLoop::SimControl).to receive(:simulators).and_return([])
        args = cmd.split(' ')
        Open3.popen3(args.shift, *args) do |_, stdout, _, process_status|
          out = stdout.read.strip
          ap out.split("\n")
          xcode_version = Resources.shared.current_xcode_version.to_s
          expected = "No simulator for active Xcode (version #{xcode_version}) is booted."
          expect(out).to be == expected
          expect(process_status.value.exitstatus).to be == 0
        end
      end

      it 'puts message about the first booted device' do
        bridge.boot
        args = cmd.split(' ')
        Open3.popen3(args.shift, *args) do |_, stdout, _, process_status|
          out = stdout.read.strip
          ap out.split("\n")
          expect(out[/iPhone 5s/, 0]).to be_truthy
          expect(out[/x86_64/, 0]).to be_truthy
          expect(process_status.value.exitstatus).to be == 0
        end
      end
    end

    describe 'run-loop simctl install' do

      let(:cmd) {
        'run-loop simctl install --debug --app spec/resources/CalSmoke.app'.split(' ')
      }

      let(:bundle_id_regex) { /Installed 'sh.calaba.CalSmoke'/ }
      let(:will_not_reinstall_regex) { /Will not re-install 'sh.calaba.CalSmoke' because the SHAs match/ }
      let(:will_reinstall_regex) { /Will re-install 'sh.calaba.CalSmoke' because the SHAs don't match./}

      describe 'app is not installed' do

        before {
          bridge.uninstall
        }

        let(:device) { bridge.device }

        it 'can install an app on default simulator' do
          Open3.popen3(cmd.shift, *cmd) do |_, stdout, stderr, process_status|
            out = stdout.read.strip
            ap out.split("\n")
            expect(out[/iPhone 5s/, 0]).to be_truthy
            expect(out[bundle_id_regex, 0]).to be_truthy
            expect(stderr.read).to be == ''
            expect(process_status.value.exitstatus).to be == 0
          end
        end

        it 'can install an app on simulator using UDID' do
          cmd << '--device'
          cmd << device.udid
          Open3.popen3(cmd.shift, *cmd) do |_, stdout, stderr, process_status|
            out = stdout.read.strip
            ap out.split("\n")
            expect(out[/iPhone 5s/, 0]).to be_truthy
            expect(out[bundle_id_regex, 0]).to be_truthy
            expect(stderr.read).to be == ''
            expect(process_status.value.exitstatus).to be == 0
          end
        end

        it 'can install an app on simulator using name' do
          cmd << '--device'
          cmd << device.instruments_identifier(xcode)
          Open3.popen3(cmd.shift, *cmd) do |_, stdout, stderr, process_status|
            out = stdout.read.strip
            ap out.split("\n")
            expect(out[/iPhone 5s/, 0]).to be_truthy
            expect(out[bundle_id_regex, 0]).to be_truthy
            expect(stderr.read).to be == ''
            expect(process_status.value.exitstatus).to be == 0
          end
        end
      end

      describe 'app is installed, but not different' do

        before {
          bridge.install
        }

        it 'skips the install' do
          Open3.popen3(cmd.shift, *cmd) do |_, stdout, stderr, process_status|
            out = stdout.read.strip
            ap out.split("\n")
            expect(out[/iPhone 5s/, 0]).to be_truthy
            expect(out[bundle_id_regex, 0]).to be_truthy
            expect(out[will_not_reinstall_regex, 0]).to be_truthy
            expect(stderr.read).to be == ''
            expect(process_status.value.exitstatus).to be == 0
          end
        end
      end

      describe 'app is installed, but different' do
        it 're-installs the app' do
          app_bundle_dir = bridge.fetch_app_dir
          path = FileUtils.touch(File.join(app_bundle_dir, 'tmp.txt')).first

          File.open(path, 'w') do |file|
            file.write('some text')
          end

          Open3.popen3(cmd.shift, *cmd) do |_, stdout, stderr, process_status|
            out = stdout.read.strip
            ap out.split("\n")

            expect(out[/iPhone 5s/, 0]).to be_truthy
            expect(out[bundle_id_regex, 0]).to be_truthy
            expect(out[will_reinstall_regex, 0]).to be_truthy
            expect(stderr.read).to be == ''
            expect(process_status.value.exitstatus).to be == 0
          end
        end
      end

      describe '--force' do
        it 'forces a re-install of the app' do
          cmd << '--force'
          Open3.popen3(cmd.shift, *cmd) do |_, stdout, stderr, process_status|
            out = stdout.read.strip
            ap out.split("\n")
            expect(out[/iPhone 5s/, 0]).to be_truthy
            expect(out[bundle_id_regex, 0]).to be_truthy
            expect(out[/Will force a re-install/, 0]).to be_truthy
            expect(stderr.read).to be == ''
            expect(process_status.value.exitstatus).to be == 0
          end
        end
      end
    end
  end
end
