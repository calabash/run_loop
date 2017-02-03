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
    SIM_STATES = {
      "Shutdown" => 1,
      "Shutting Down" => 2,
      "Booted" => 3,
      "Plist Missing" => -1
    }.freeze

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
      max_tries = 3
      valid = false
      3.times do |try|
        valid = self.valid_core_simulator_service?
        break if valid
        RunLoop.log_debug("Invalid CoreSimulator service for active Xcode: try #{try + 1} of #{max_tries}")
      end
      valid
    end

    # @!visibility private
    def self.valid_core_simulator_service?
      require "run_loop/shell"
      args = ["xcrun", "simctl", "help"]

      begin
        hash = Shell.run_shell_command(args)
        hash[:exit_status] == 0 &&
          !hash[:out][/Failed to locate a valid instance of CoreSimulatorService/]
      rescue RunLoop::Shell::Error => _
        false
      end
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
      hash = shell_out_with_xcrun(cmd, DEFAULTS)

      exit_status = hash[:exit_status]
      if exit_status != 0
        nil
      else
        hash[:out].strip
      end
    end

    # @!visibility private
    def simulator_state_as_int(device)
      plist = device.simulator_device_plist
      if File.exist?(plist)
        pbuddy.plist_read("state", plist).to_i
      else
        SIM_STATES["Plist Missing"]
      end
    end

    # @!visibility private
    def simulator_state_as_string(device)
      string_for_sim_state(simulator_state_as_int(device))
    end

    # @!visibility private
    def shutdown(device)
      if simulator_state_as_int(device) == SIM_STATES["Shutdown"]
        RunLoop.log_debug("Simulator is already shutdown")
        true
      else
        cmd = ["simctl", "shutdown", device.udid]
        hash = shell_out_with_xcrun(cmd, DEFAULTS)

        exit_status = hash[:exit_status]
        if exit_status != 0

          if simulator_state_as_int(device) == SIM_STATES["Shutdown"]
            RunLoop.log_debug("simctl shutdown called when state is 'Shutdown'; ignoring error")
          else
            raise RuntimeError,
                  %Q[Could not shutdown the simulator:

  command: xcrun #{cmd.join(" ")}
simulator: #{device}

                  #{hash[:out]}

This usually means your CoreSimulator processes need to be restarted.

You can restart the CoreSimulator processes with this command:

$ bundle exec run-loop simctl manage-processes

]
          end
        end
        true
      end
    end

    # @!visibility private
    #
    # Waiting for anything but 'Shutdown' is not advised.  The simulator reports
    # that it is "Booted" long before it is ready to receive commands.
    #
    # Waiting for 'Shutdown' is required for erasing the simulator and launching
    # launching the simulator with iOSDeviceManager.
    def wait_for_shutdown(device, timeout, delay)
      now = Time.now
      poll_until = now + timeout
      in_state = false

      state = nil

      while Time.now < poll_until
        state = simulator_state_as_int(device)
        in_state = state == SIM_STATES["Shutdown"]
        break if in_state
        sleep delay if delay != 0
      end

      elapsed = Time.now - now
      RunLoop.log_debug("Waited for #{elapsed} seconds for device to have state: 'Shutdown'.")

      unless in_state
        string = string_for_sim_state(state)
        raise "Expected 'Shutdown' state but found '#{string}' after waiting for #{elapsed} seconds."
      end
      in_state
    end

    # @!visibility private
    # Erases the simulator.
    #
    # @param [RunLoop::Device] device The simulator to erase.
    # @param [Numeric] wait_timeout How long to wait for the simulator to have
    #  state "Shutdown"; passed to #wait_for_shutdown.
    # @param [Numeric] wait_delay How long to wait between calls to
    #  #simulator_state_as_int while waiting for the simulator have to state "Shutdown";
    #  passed to #wait_for_shutdown
    def erase(device, wait_timeout, wait_delay)
      require "run_loop/core_simulator"
      CoreSimulator.quit_simulator

      shutdown(device)
      wait_for_shutdown(device, wait_timeout, wait_delay)

      cmd = ["simctl", "erase", device.udid]
      hash = shell_out_with_xcrun(cmd, DEFAULTS)

      exit_status = hash[:exit_status]
      if exit_status != 0
        raise RuntimeError,
%Q[Could not erase the simulator:

  command: xcrun #{cmd.join(" ")}
simulator: #{device}

              #{hash[:out]}

This usually means your CoreSimulator processes need to be restarted.

You can restart the CoreSimulator processes with this command:

$ bundle exec run-loop simctl manage-processes

]
      end
      true
    end

    # @!visibility private
    #
    # Launches the app on on the device.
    #
    # Caller is responsible for the following:
    #
    # 1. Launching the simulator.
    # 2. Installing the application.
    #
    # No checks are made.
    #
    # @param [RunLoop::Device] device The simulator to launch on.
    # @param [RunLoop::App] app The app to launch.
    # @param [Numeric] timeout How long to wait for simctl to complete.
    def launch(device, app, timeout)
      cmd = ["simctl", "launch", device.udid, app.bundle_identifier]
      options = DEFAULTS.dup
      options[:timeout] = timeout

      hash = shell_out_with_xcrun(cmd, options)

      exit_status = hash[:exit_status]
      if exit_status != 0
        raise RuntimeError,
%Q[Could not launch app on simulator:

  command: xcrun #{cmd.join(" ")}
simulator: #{device}
      app: #{app}

#{hash[:out]}

This usually means your CoreSimulator processes need to be restarted.

You can restart the CoreSimulator processes with this command:

$ bundle exec run-loop simctl manage-processes

]
      end
      true
    end

    # @!visibility private
    #
    # Removes the application from the device.
    #
    # Caller is responsible for the following:
    #
    # 1. Launching the simulator.
    # 2. Verifying that the application is installed; simctl uninstall will fail if app
    #    is installed.
    #
    # No checks are made.
    #
    # @param [RunLoop::Device] device The simulator to launch on.
    # @param [RunLoop::App] app The app to launch.
    # @param [Numeric] timeout How long to wait for simctl to complete.
    def uninstall(device, app, timeout)
      cmd = ["simctl", "uninstall", device.udid, app.bundle_identifier]
      options = DEFAULTS.dup
      options[:timeout] = timeout

      hash = shell_out_with_xcrun(cmd, options)

      exit_status = hash[:exit_status]
      if exit_status != 0
        raise RuntimeError,
%Q[Could not uninstall app from simulator:

  command: xcrun #{cmd.join(" ")}
simulator: #{device}
      app: #{app}

#{hash[:out]}

This usually means your CoreSimulator processes need to be restarted.

You can restart the CoreSimulator processes with this command:

$ bundle exec run-loop simctl manage-processes

]
      end
      true
    end

    # @!visibility private
    #
    # Launches the app on on the device.
    #
    # Caller is responsible for the following:
    #
    # 1. Launching the simulator.
    #
    # No checks are made.
    #
    # @param [RunLoop::Device] device The simulator to launch on.
    # @param [RunLoop::App] app The app to launch.
    # @param [Numeric] timeout How long to wait for simctl to complete.
    def install(device, app, timeout)
      cmd = ["simctl", "install", device.udid, app.path]
      options = DEFAULTS.dup
      options[:timeout] = timeout

      hash = shell_out_with_xcrun(cmd, options)

      exit_status = hash[:exit_status]
      if exit_status != 0
        raise RuntimeError,
%Q[Could not install app on simulator:

  command: xcrun #{cmd.join(" ")}
simulator: #{device}
      app: #{app}

#{hash[:out]}

This usually means your CoreSimulator processes need to be restarted.

You can restart the CoreSimulator processes with this command:

$ bundle exec run-loop simctl manage-processes

]
      end
      true
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
    attr_reader :ios_devices, :tvos_devices, :watchos_devices, :pbuddy

    # @!visibility private
    def pbuddy
      @pbuddy ||= RunLoop::PlistBuddy.new
    end

    # @!visibility private
    def string_for_sim_state(integer)
      SIM_STATES.each do |key, value|
        if value == integer
          return key
        end
      end

      raise ArgumentError, "Could not find state for #{integer}"
    end

    # @!visibility private
    def shell_out_with_xcrun(array, options)
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
      hash = shell_out_with_xcrun(cmd, DEFAULTS)

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
