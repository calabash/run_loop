
describe RunLoop::Simctl do
  let(:device) { Resources.shared.default_simulator }
  let(:simctl) { RunLoop::Simctl.new }
  let(:xcrun) { RunLoop::Xcrun.new }
  let(:xcode) { Resources.shared.xcode }
  let(:sim_control) { Resources.shared.sim_control }
  let(:defaults) { RunLoop::Simctl::DEFAULTS }

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

  it ".new" do
    expect(simctl.instance_variable_get(:@ios_devices)).to be == []
    expect(simctl.instance_variable_get(:@tvos_devices)).to be == []
    expect(simctl.instance_variable_get(:@watchos_devices)).to be == []
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
    expect(xcrun).to receive(:exec).with(cmd, merged).and_return({})

    expect(simctl.send(:execute, cmd, options)).to be == {}
  end

  it "#xcrun" do
    actual = simctl.send(:xcrun)
    expect(actual).to be_a_kind_of(RunLoop::Xcrun)
    expect(simctl.instance_variable_get(:@xcrun)).to be == actual
  end

  it "#xcode" do
    actual = simctl.send(:xcode)
    expect(actual).to be_a_kind_of(RunLoop::Xcode)
    expect(simctl.instance_variable_get(:@xcode)).to be == actual
  end

  it "#sim_control" do
    actual = simctl.send(:sim_control)
    expect(actual).to be_a_kind_of(RunLoop::SimControl)
    expect(simctl.instance_variable_get(:@sim_control)).to be == actual
  end

  describe "#json_to_hash" do
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
end