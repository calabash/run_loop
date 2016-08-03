
describe RunLoop::Simctl do
  let(:device) { Resources.shared.default_simulator }
  let(:xcrun) { RunLoop::Xcrun.new }
  let(:xcode) { Resources.shared.xcode }
  let(:sim_control) { Resources.shared.sim_control }
  let(:defaults) { RunLoop::Simctl::DEFAULTS }

  before do
    allow(RunLoop::Environment).to receive(:debug?).and_return(true)
  end

  it "has a constant that points to plist dir" do
    dir = RunLoop::Simctl::SIMCTL_PLIST_DIR
    expect(Dir.exist?(dir)).to be_truthy
  end

  it "returns uia plist path" do
    expect(File.exist?(RunLoop::Simctl.uia_automation_plist)).to be_truthy
  end

  it "returns uia plugin plist path" do
    expect(File.exist?(RunLoop::Simctl.uia_automation_plugin_plist)).to be_truthy
  end

  context ".ensure_valid_core_simulator_service" do
    let(:args) { ["xcrun", "simctl", "help"] }
    let(:hash) { { } }
    it "returns true if simctl help exits with 0" do
      hash[:exit_status] = 0
      expect(RunLoop::Shell).to receive(:run_shell_command).with(args).and_return(hash)

      actual = RunLoop::Simctl.ensure_valid_core_simulator_service
      expect(actual).to be == true
    end

    it "returns false if simctl help fails more than 3 times" do
      hash[:exit_status] = 1
      expect(RunLoop::Shell).to receive(:run_shell_command).with(args).exactly(3).times.and_return(hash)

      actual = RunLoop::Simctl.ensure_valid_core_simulator_service
      expect(actual).to be == false
    end

    it "returns true after rescuing Shell::Error 2 times" do
      hash[:exit_status] = 0
      expect(RunLoop::Shell).to receive(:run_shell_command).with(args).exactly(2).times.and_raise RunLoop::Shell::Error
      expect(RunLoop::Shell).to receive(:run_shell_command).with(args).and_return(hash)

      actual = RunLoop::Simctl.ensure_valid_core_simulator_service
      expect(actual).to be == true
    end

    it "returns true after handling non-zero exit 2 times" do
      fail_hash = {:exit_status => 1}
      hash[:exit_status] = 0
      expect(RunLoop::Shell).to receive(:run_shell_command).with(args).exactly(2).times.and_return(fail_hash)
      expect(RunLoop::Shell).to receive(:run_shell_command).with(args).and_return(hash)

      actual = RunLoop::Simctl.ensure_valid_core_simulator_service
      expect(actual).to be == true
    end

    it "returns true after handling one Shell::Error and one non-zero exit" do
      fail_hash = {:exit_status => 1}
      hash[:exit_status] = 0
      expect(RunLoop::Shell).to receive(:run_shell_command).with(args).and_raise RunLoop::Shell::Error
      expect(RunLoop::Shell).to receive(:run_shell_command).with(args).times.and_return(fail_hash)
      expect(RunLoop::Shell).to receive(:run_shell_command).with(args).and_return(hash)

      actual = RunLoop::Simctl.ensure_valid_core_simulator_service
      expect(actual).to be == true
    end
  end

  it ".new" do
    expect(RunLoop::Simctl).to receive(:ensure_valid_core_simulator_service).and_return(true)

    simctl = RunLoop::Simctl.new

    expect(simctl.instance_variable_get(:@ios_devices)).to be == []
    expect(simctl.instance_variable_get(:@tvos_devices)).to be == []
    expect(simctl.instance_variable_get(:@watchos_devices)).to be == []
  end

  describe "instance methods" do

    let(:simctl) { RunLoop::Simctl.new }

    before do
      allow(RunLoop::Simctl).to receive(:ensure_valid_core_simulator_service).and_return(true)
    end

    describe "Compatibility with SimControl" do

      before do
        allow(simctl).to receive(:sim_control).and_return(sim_control)
      end

      it "#ensure_accessibility" do
        expect(sim_control).to receive(:ensure_accessibility).with(device).and_return(:true)

        expect(simctl.ensure_accessibility(device)).to be == :true
      end

      it "#ensure_software_keyboard" do
        expect(sim_control).to receive(:ensure_software_keyboard).with(device).and_return(:true)

        expect(simctl.ensure_software_keyboard(device)).to be == :true
      end

      it "#xcode is a public method" do
        actual = simctl.xcode
        expect(actual).to be_a_kind_of(RunLoop::Xcode)
        expect(simctl.instance_variable_get(:@xcode)).to be == actual
      end
    end

    describe "#simulators" do
      it "ios_devices are empty" do
        devices = {
          :ios => ["a", "b", "c"],
          :tvos => [],
          :watchos => []
        }
        expect(simctl).to receive(:fetch_devices!).and_return(devices)
        expect(simctl.simulators).to be == devices[:ios]
      end

      it "ios_devices are non-empty" do
        simulators = ["a", "b", "c"]
        expect(simctl).to receive(:ios_devices).and_return(simulators)

        expect(simctl.simulators).to be == simulators
      end
    end

    describe "#app_container" do

      let(:bundle_id) { "sh.calaba.LPTestTarget" }
      let(:cmd) { ["simctl", "get_app_container", device.udid, bundle_id]  }
      let(:hash) do
        {
          :pid => 1,
          :out => "path/to/My.app#{$-0}",
          :exit_status => 0
        }
      end

      before do
        expect(simctl).to receive(:xcode).and_return(xcode)
      end

      describe "Xcode >= 7" do
        before do
          expect(xcode).to receive(:version_gte_7?).and_return(true)
        end

        it "app is installed" do
          expect(simctl).to receive(:execute).with(cmd, defaults).and_return(hash)

          expect(simctl.app_container(device, bundle_id)).to be == hash[:out].strip
        end

        it "app is not installed" do
          hash[:exit_status] = 1
          expect(simctl).to receive(:execute).with(cmd, defaults).and_return(hash)
          expect(simctl.app_container(device, bundle_id)).to be == nil
        end
      end

      it "Xcode < 7" do
        expect(xcode).to receive(:version_gte_7?).and_return(false)

        expect(simctl.app_container(device, bundle_id)).to be == nil
      end
    end

    it "#pbuddy" do
      pbuddy = simctl.send(:pbuddy)
      expect(simctl.instance_variable_get(:@pbuddy)).to be == pbuddy
    end

    context "#string_for_sim_state" do
      it "returns a string for valid states" do
        expect(simctl.send(:string_for_sim_state, 1)).to be == "Shutdown"
        expect(simctl.send(:string_for_sim_state, 2)).to be == "Shutting Down"
        expect(simctl.send(:string_for_sim_state, 3)).to be == "Booted"
      end

      it "raises an error for invalid states" do
        expect do
          simctl.send(:string_for_sim_state, 0)
        end.to raise_error ArgumentError, /Could not find state for/
      end
    end

    context "#simulator_state" do
      it "returns the numeric state of the simulator" do
        pbuddy = RunLoop::PlistBuddy.new
        expect(simctl).to receive(:pbuddy).and_return(pbuddy)
        expect(pbuddy).to receive(:plist_read).and_return("10")

        expect(simctl.simulator_state(device)).to be == 10
      end
    end

    context "#shutdown" do
      let(:hash) { { :exit_status => 0, :out => "Some output" } }

      it "returns true if the simulator is already shutdown" do
        expect(simctl).to receive(:simulator_state).and_return(1)
        expect(simctl).not_to receive(:execute)

        expect(simctl.shutdown(device)).to be_truthy
      end
      it "returns true if simctl shutdown completes with 0 exit status" do
        expect(simctl).to receive(:simulator_state).and_return(2)
        expect(simctl).to receive(:execute).and_return(hash)

        expect(simctl.shutdown(device)).to be_truthy
      end

      it "raises an error if simctl shutdown completes with non-zero exit status" do
        expect(simctl).to receive(:simulator_state).and_return(2)
        hash[:exit_status] = 1
        expect(simctl).to receive(:execute).and_return(hash)

        expect do
          simctl.shutdown(device)
        end.to raise_error RuntimeError, /Could not shutdown the simulator/
      end
    end

    context "#wait_for_shutdown" do
      it "returns true if state is 'Shutdown' before timeout" do
        expect(simctl).to receive(:simulator_state).and_return(1)

        expect(simctl.wait_for_shutdown(device, 1, 0)).to be_truthy
      end

      it "returns true after waiting for state to be 'Shutdown'" do
        expect(simctl).to receive(:simulator_state).and_return(3, 3, 1)

        expect(simctl.wait_for_shutdown(device, 1, 0)).to be_truthy
      end

      it "raises an error if state is not 'Shutdown' before timeout" do
        expect(simctl).to receive(:simulator_state).at_least(:once).and_return(3)

        expect do
          simctl.wait_for_shutdown(device, 0.05, 0)
        end.to raise_error RuntimeError, /Expected 'Shutdown' state but found/
      end
    end

    context "#erase" do
      let(:hash) { { :exit_status => 0, :out => "Some output" } }
      let(:cmd) { ["simctl", "erase", device.udid] }
      let(:options) { RunLoop::Simctl::DEFAULTS.dup }

      before do
        expect(RunLoop::CoreSimulator).to receive(:quit_simulator).and_return(true)
        expect(simctl).to receive(:shutdown).with(device).and_return(true)
        expect(simctl).to receive(:wait_for_shutdown).and_return(true)
        expect(simctl).to receive(:execute).with(cmd, options).and_return(hash)
      end

      it "returns true if simctl erase completes with 0 exit status" do
        expect(simctl.erase(device, 10, 0.1)).to be_truthy
      end

      it "raises an error if simctl erase completes with non-zero exit status" do
        hash[:exit_status] = 1
        expect do
          simctl.erase(device, 10, 0.1)
        end.to raise_error RuntimeError, /Could not erase the simulator/
      end
    end

    context "#launch" do
      let(:hash) { { :exit_status => 0, :out => "Some output" } }
      let(:app) { RunLoop::App.new(Resources.shared.app_bundle_path) }
      let(:cmd) { ["simctl", "launch", device.udid, app.bundle_identifier] }
      let(:options) do
        options = RunLoop::Simctl::DEFAULTS.dup
        options[:timeout] = 10
        options
      end

      it "returns true if calling simctl launch completes with exit status 0" do
        expect(simctl).to receive(:execute).with(cmd, options).and_return(hash)

        expect(simctl.launch(device, app, 10))
      end

      it "raises error if simctl launch completes with non-zero exit status" do
        hash[:exit_status] = 1
        expect(simctl).to receive(:execute).with(cmd, options).and_return(hash)
        expect do
          expect(simctl.launch(device, app, 10))
        end.to raise_error RuntimeError, /Could not launch app on simulator/
      end
    end

    context "#uninstall" do
      let(:hash) { { :exit_status => 0, :out => "Some output" } }
      let(:app) { RunLoop::App.new(Resources.shared.app_bundle_path) }
      let(:cmd) { ["simctl", "uninstall", device.udid, app.bundle_identifier] }
      let(:options) do
        options = RunLoop::Simctl::DEFAULTS.dup
        options[:timeout] = 10
        options
      end
      it "returns true if simctl uninstall completes with exit status 0" do
        expect(simctl).to receive(:execute).with(cmd, options).and_return(hash)

        expect(simctl.uninstall(device, app, 10))
      end
      it "raises error if simctl uninstall completes with non-zero exit status" do
        hash[:exit_status] = 1
        expect(simctl).to receive(:execute).with(cmd, options).and_return(hash)
        expect do
          expect(simctl.uninstall(device, app, 10))
        end.to raise_error RuntimeError, /Could not uninstall app from simulator/
      end
    end

    describe "#fetch_devices!" do
      let(:cmd) { ["simctl", "list", "devices", "--json"]  }
      let(:hash) do
        {
          :pid => 1,
          :out => %Q[{ "key" : "value" }],
          :exit_status => 0
        }
      end
      let(:options) { RunLoop::Simctl::DEFAULTS }

      before do
        allow(simctl).to receive(:xcode).and_return(xcode)
      end

      describe "Xcode >= 7" do
        before do
          expect(xcode).to receive(:version_gte_7?).and_return(true)
        end

        it "non-zero exit status" do
          hash[:exit_status] = 1
          hash[:out] = "An error message"
          expect(simctl).to receive(:execute).with(cmd, options).and_return(hash)

          expect do
            simctl.send(:fetch_devices!)
          end.to raise_error RuntimeError, /simctl exited 1/
        end

        it "returns a hash of iOS, tvOS, and watchOS devices" do
          # Clears existing values
          simctl.instance_variable_set(:@ios_devices, [:ios])
          simctl.instance_variable_set(:@tvos_devices, [:tvos])
          simctl.instance_variable_set(:@watchos_devices, [:watchos])

          hash[:out] = RunLoop::RSpec::Simctl::SIMCTL_DEVICE_JSON_XCODE7
          expect(simctl).to receive(:execute).with(cmd, options).and_return(hash)

          actual = simctl.send(:fetch_devices!)
          expect(actual[:ios].include?(:ios)).to be_falsey
          expect(actual[:tvos].include?(:tvos)).to be_falsey
          expect(actual[:watchos].include?(:watchos)).to be_falsey

          expect(actual[:ios].count).to be == 79
          expect(actual[:tvos].count).to be == 3
          expect(actual[:watchos].count).to be == 8
        end
      end

      it "Xcode < 7" do
        expect(xcode).to receive(:version_gte_7?).and_return(false)
        expect(simctl).to receive(:sim_control).and_return(sim_control)
        expect(sim_control).to receive(:simulators).and_return(["a", "b", "c"])

        actual = simctl.send(:fetch_devices!)
        expect(actual[:ios]).to be == ["a", "b", "c"]
        expect(actual[:tvos]).to be == []
        expect(actual[:watchos]).to be == []
      end
    end

    it "#execute" do
      options = {:a => :b}
      merged = RunLoop::Simctl::DEFAULTS.merge(options)
      cmd = ["simctl", "subcommand"]
      expect(simctl).to receive(:xcrun).and_return(xcrun)
      expect(xcrun).to receive(:run_command_in_context).with(cmd, merged).and_return({})

      expect(simctl.send(:execute, cmd, options)).to be == {}
    end

    it "#xcrun" do
      actual = simctl.send(:xcrun)
      expect(actual).to be_a_kind_of(RunLoop::Xcrun)
      expect(simctl.instance_variable_get(:@xcrun)).to be == actual
    end

    it "#sim_control" do
      actual = simctl.send(:sim_control)
      expect(actual).to be_a_kind_of(RunLoop::SimControl)
      expect(simctl.instance_variable_get(:@sim_control)).to be == actual
    end

    describe "#json_to_hash" do
      before do
        expect(simctl).to receive(:filter_stderr).and_call_original
      end
      it "symbolizes keys" do
        json = %Q[{ "key" : "value" }]
        expected = { "key" => "value" }
        expect(simctl.send(:json_to_hash, json)).to be == expected
      end

      it "raises error" do
        expect do
          expect(simctl.send(:json_to_hash, ""))
        end.to raise_error RuntimeError, /Could not parse simctl JSON response/
      end
    end

    describe "categorizing and parsing device keys" do
      let(:ios) { "iOS 9.1" }
      let(:tvos) { "tvOS 9.0" }
      let(:watchos) { "watchOS 2.1" }

      it "#device_key_is_ios?" do
        expect(simctl.send(:device_key_is_ios?, ios)).to be_truthy
        expect(simctl.send(:device_key_is_ios?, tvos)).to be_falsey
        expect(simctl.send(:device_key_is_ios?, watchos)).to be_falsey
      end

      it "#device_key_is_tvos?" do
        expect(simctl.send(:device_key_is_tvos?, ios)).to be_falsey
        expect(simctl.send(:device_key_is_tvos?, tvos)).to be_truthy
        expect(simctl.send(:device_key_is_tvos?, watchos)).to be_falsey
      end

      it "#device_key_is_watchos?" do
        expect(simctl.send(:device_key_is_watchos?, ios)).to be_falsey
        expect(simctl.send(:device_key_is_watchos?, tvos)).to be_falsey
        expect(simctl.send(:device_key_is_watchos?, watchos)).to be_truthy
      end

      it "#device_key_to_version" do
        expect(simctl.send(:device_key_to_version, ios)).to be == RunLoop::Version.new("9.1")
        expect(simctl.send(:device_key_to_version, tvos)).to be == RunLoop::Version.new("9.0")
        expect(simctl.send(:device_key_to_version, watchos)).to be == RunLoop::Version.new("2.1")
      end
    end

    describe "parsing device record" do
      let(:record) do
        {
          "state" => "Shutdown",
          "availability" => "(available)",
          "name" => "iPhone 5s",
          "udid" => "33E644E8-096B-4766-A957-4B34FB18DC48"
        }
      end
      let(:version) { "9.1" }

      it "#device_available?" do
        expect(simctl.send(:device_available?, record)).to be_truthy

        record["availability"] = "  (unavailable, device type profile not found)"
        expect(simctl.send(:device_available?, record)).to be_falsey

        record["availability"] =  " (unavailable, Mac OS X 10.11.4 is not supported)"
        expect(simctl.send(:device_available?, record)).to be_falsey
      end

      it "#device_from_record" do
        actual = simctl.send(:device_from_record, record, version)
        expect(actual).to be_a_kind_of(RunLoop::Device)

        expect(actual.version).to be == RunLoop::Version.new("9.1")
        expect(actual.name).to be == record["name"]
        expect(actual.udid).to be == record["udid"]
        expect(actual.state).to be == record["state"]
      end
    end

    describe "#bucket_for_key" do
      let(:ios) { "iOS 9.1" }
      let(:tvos) { "tvOS 9.0" }
      let(:watchos) { "watchOS 2.1" }

      before do
        simctl.instance_variable_set(:@ios_devices, [:ios])
        simctl.instance_variable_set(:@tvos_devices, [:tvos])
        simctl.instance_variable_set(:@watchos_devices, [:watchos])
      end

      it "ios" do
        expect(simctl.send(:bucket_for_key, ios)).to be == [:ios]
      end

      it "tvos" do
        expect(simctl.send(:bucket_for_key, tvos)).to be == [:tvos]
      end

      it "watchos" do
        expect(simctl.send(:bucket_for_key, watchos)).to be == [:watchos]
      end

      it "unknown" do
        expect do
          simctl.send(:bucket_for_key, "unknown key")
        end.to raise_error RuntimeError, /Unexpected key while processing simctl output/
      end
    end

    describe "filtering stderr output from JSON" do
      describe "#stderr_line?" do
        it "CoreSimulatorService" do
          line = "attempting to unload a stale CoreSimulatorService job"
          expect(simctl.send(:stderr_line?, line)).to be_truthy
        end

        it "simctl[< pid info >]" do
          line = "simctl[98400:32684208] blah blah"
          expect(simctl.send(:stderr_line?, line)).to be_truthy
        end
      end

      it "#filter_stderr" do
        lines =
%q[good line
attempting to unload a stale CoreSimulatorService job
simctl[98400:32684208] blah blah
another good line]

        expected = %q[good line
another good line]

        expect(simctl.send(:filter_stderr, lines)).to be == expected
      end
    end
  end
end
