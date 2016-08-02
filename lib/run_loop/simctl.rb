module RunLoop

  # @!visibility private
  # An interface to the `simctl` command line tool for CoreSimulator.
  #
  # Replacement for SimControl.
  class Simctl

    # @!visibility private
    DEFAULTS = {
      :timeout => RunLoop::Environment.ci? ? 90 : 30,
      :log_cmd => true
    }

    # @!visibility private
    SIMCTL_PLIST_DIR = lambda {
      dirname  = File.dirname(__FILE__)
      joined = File.join(dirname, "..", "..", "plists", "simctl")
      File.expand_path(joined)
    }.call

    # @!visibility private
    def self.uia_automation_plist
      File.join(SIMCTL_PLIST_DIR, 'com.apple.UIAutomation.plist')
    end

    # @!visibility private
    def self.uia_automation_plugin_plist
      File.join(SIMCTL_PLIST_DIR, 'com.apple.UIAutomationPlugIn.plist')
    end

    # @!visibility private
    def self.ensure_valid_core_simulator_service
      require "run_loop/shell"
      args = ["xcrun", "simctl", "help"]

      max_tries = 3
      3.times do |try|
        hash = {}
        begin
          hash = Shell.run_shell_command(args)
          if hash[:exit_status] != 0
            RunLoop.log_debug("Invalid CoreSimulator service for active Xcode: try #{try + 1} of #{max_tries}")
          else
            return true
          end
        rescue RunLoop::Shell::Error => _
          RunLoop.log_debug("Invalid CoreSimulator service for active Xcode, retrying #{try + 1} of #{max_tries}")
        end
      end
      false
    end

    # @!visibility private
    attr_reader :device

    # @!visibility private
    def initialize
      @ios_devices = []
      @tvos_devices = []
      @watchos_devices = []
      Simctl.ensure_valid_core_simulator_service
    end

    # @!visibility private
    def to_s
      "#<Simctl: #{xcode.version}>"
    end

    # @!visibility private
    def inspect
      to_s
    end

    # @!visibility private
    def simulators
      simulators = ios_devices
      if simulators.empty?
       simulators = fetch_devices![:ios]
      end
      simulators
    end

    # @!visibility private
    #
    # This method is not supported on Xcode < 7 - returns nil.
    #
    # Simulator must be booted in El Cap, which makes this method useless for us
    # because we have to do a bunch of pre-launch checks for sandbox resetting.
    #
    # Testing has shown that moving the device in and out of the booted state
    # takes a long time (seconds) and is unpredictable.
    #
    # TODO ensure a booted state.
    #
    # @param [String] bundle_id The CFBundleIdentifier of the app.
    # @param [RunLoop::Device] device The device under test.
    # @return [String] The path to the .app bundle if it exists; nil otherwise.
    def app_container(device, bundle_id)
      return nil if !xcode.version_gte_7?
      cmd = ["simctl", "get_app_container", device.udid, bundle_id]
      hash = execute(cmd, DEFAULTS)

      exit_status = hash[:exit_status]
      if exit_status != 0
        nil
      else
        hash[:out].strip
      end
    end

    # @!visibility private
    #
    # SimControl compatibility
    def ensure_accessibility(device)
      sim_control.ensure_accessibility(device)
    end

    # @!visibility private
    #
    # SimControl compatibility
    def ensure_software_keyboard(device)
      sim_control.ensure_software_keyboard(device)
    end

    # @!visibility private
    #
    # TODO Make this private again; exposed for SimControl compatibility.
    def xcode
      @xcode ||= RunLoop::Xcode.new
    end

    private

    # @!visibility private
    attr_reader :ios_devices, :tvos_devices, :watchos_devices

    # @!visibility private
    def execute(array, options)
      merged = DEFAULTS.merge(options)
      xcrun.run_command_in_context(array, merged)
    end

    # @!visibility private
    #
    # Starting in Xcode 7, simctl allows a --json option for listing devices.
    #
    # On Xcode 6, we will fall back to SimControl which does a line-by-line
    # processing of `simctl list devices`. tvOS and watchOS devices are not
    # available on Xcode < 7.
    #
    # This is a destructive operation on `@ios_devices`, `@tvos_devices`, and
    # `@watchos_devices`.  Callers should check for existing devices to avoid
    # the overhead of calling `simctl list devices --json`.
    def fetch_devices!
      if !xcode.version_gte_7?
        return {
          :ios => sim_control.simulators,
          :tvos => [],
          :watchos => []
        }
      end

      @ios_devices = []
      @tvos_devices = []
      @watchos_devices = []

      cmd = ["simctl", "list", "devices", "--json"]
      hash = execute(cmd, DEFAULTS)

      out = hash[:out]
      exit_status = hash[:exit_status]
      if exit_status != 0
        raise RuntimeError, %Q[simctl exited #{exit_status}:

#{out}

while trying to list devices.
]
      end

      devices = json_to_hash(out)["devices"]

      devices.each do |key, device_list|
        version = device_key_to_version(key)
        bucket = bucket_for_key(key)

        device_list.each do |record|
          if device_available?(record)
            bucket << device_from_record(record, version)
          end
        end
      end
      {
        :ios => ios_devices,
        :tvos => tvos_devices,
        :watchos => watchos_devices
      }
    end

    # @!visibility private
    #
    # command_runner_ng combines stderr and stdout and starting in Xcode 7.3,
    # simctl has started generating stderr output.  This must be filtered out
    # so that we can parse the JSON response.
    def filter_stderr(out)
      out.split($-0).map do |line|
        if stderr_line?(line)
          nil
        else
          line
        end
      end.compact.join($-0)
    end

    # @!visibility private
    def stderr_line?(line)
      line[/CoreSimulatorService/, 0] || line[/simctl\[.+\]/, 0]
    end

    # @!visibility private
    def json_to_hash(json)
      filtered = filter_stderr(json)
      begin
        JSON.parse(filtered)
      rescue TypeError, JSON::ParserError => e
        raise RuntimeError, %Q[Could not parse simctl JSON response:

#{e}
]
      end
    end

    # @!visibility private
    def device_key_is_ios?(key)
      key[/iOS/, 0]
    end

    # @!visibility private
    def device_key_is_tvos?(key)
      key[/tvOS/, 0]
    end

    # @!visibility private
    def device_key_is_watchos?(key)
      key[/watchOS/, 0]
    end

    # @!visibility private
    def device_key_to_version(key)
      str = key.split(" ").last
      RunLoop::Version.new(str)
    end

    # @!visibility private
    def device_available?(record)
      record["availability"] == "(available)"
    end

    # @!visibility private
    def device_from_record(record, version)
      RunLoop::Device.new(record["name"],
                          version,
                          record["udid"],
                          record["state"])
    end

    # @!visibility private
    def bucket_for_key(key)
      if device_key_is_ios?(key)
        bin = @ios_devices
      elsif device_key_is_tvos?(key)
        bin = @tvos_devices
      elsif device_key_is_watchos?(key)
        bin = @watchos_devices
      else
        raise RuntimeError, "Unexpected key while processing simctl output:

key = #{key}

is not an iOS, tvOS, or watchOS device"
      end
      bin
    end

    # @!visibility private
    def xcrun
      @xcrun ||= RunLoop::Xcrun.new
    end

    # @!visibility private
    # Support for Xcode < 7 when trying to collect simulators.  Xcode 7 allows
    # a --json option which is much easier to parse.
    def sim_control
      @sim_control ||= RunLoop::SimControl.new
    end
  end
end
