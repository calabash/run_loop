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
      joined = File.join(dirname, '..', '..', 'plists', 'simctl')
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
    attr_accessor :device

    # @!visibility private
    #
    # @param [RunLoop::Device] device Cannot be nil.
    def initialize(device)
      @device = device
    end

    # @!visibility private
    def to_s
      "#<Simctl: #{device.name} #{device.udid}>"
    end

    # @!visibility private
    def inspect
      to_s
    end

    # @!visibility private
    def simulators
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
    # @return [String] The path to the .app bundle if it exists; nil otherwise.
    def app_container(bundle_id)
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

    private

    # @!visibility private
    def execute(array, options)
      merged = DEFAULTS.merge(options)
      xcrun.exec(array, merged)
    end

    # @!visibility private
    def xcrun
      @xcrun ||= RunLoop::Xcrun.new
    end

    # @!visibility private
    def xcode
      @xcode ||= RunLoop::Xcode.new
    end

    # @!visibility private
    # Support for Xcode < 7 when trying to collect simulators.  Xcode 7 allows
    # a --json option which is much easier to parse.
    def sim_control
      @sim_control ||= RunLoop::SimControl.new
    end
  end
end