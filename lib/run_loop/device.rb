module RunLoop
  class Device

    require 'securerandom'
    include RunLoop::Regex

    require "run_loop/shell"
    include RunLoop::Shell

    # Starting in Xcode 7, iOS 9 simulators have a new "booting" state.
    #
    # The simulator must completely boot before run-loop tries to do things
    # like installing an app or clearing an app sandbox.  Run-loop tries to
    # wait for a the simulator stabilize by watching the checksum of the
    # simulator directory and the simulator log.
    #
    # On resource constrained devices or CI systems, the default settings may
    # not work.
    #
    # You can override these values if they do not work in your environment.
    #
    # For cucumber users, the best place to override would be in your
    # features/support/env.rb.
    #
    # For example:
    #
    # RunLoop::Device::SIM_STABLE_STATE_OPTIONS[:timeout] = 60
    SIM_STABLE_STATE_OPTIONS = {
      # The maximum amount of time to wait for the simulator
      # to stabilize.  No errors are raised if this timeout is
      # exceeded - if the default 30 seconds has passed, the
      # simulator is probably stable enough for subsequent
      # operations.
      :timeout => RunLoop::Environment.ci? ? 240 : 120
    }

    attr_reader :name
    attr_reader :version
    attr_reader :udid
    attr_reader :state
    attr_reader :simulator_root_dir
    attr_reader :simulator_accessibility_plist_path
    attr_reader :simulator_log_file_path

    # Create a new device.
    #
    # @param [String] name The name of the device.  For sims this should be
    #  'iPhone 5s' and for physical devices it will be the name the user gave
    #  to the device.
    # @param [String, RunLoop::Version] version The iOS version that is running
    #  on the device.  Can be a string or a Version instance.
    # @param [String] udid The device identifier.
    # @param [String] state (nil) This a simulator only value.  It refers to
    #  the Booted/Shutdown/Creating state of the simulator.  For pre-Xcode 6
    #  simulators, this value should be nil.
    def initialize(name, version, udid, state=nil)
      @name = name
      @udid = udid
      @state = state

      if version.is_a? String
        @version = RunLoop::Version.new version
      else
        @version = version
      end
    end

    # Returns a device given a udid or name.  In the case of a physical device,
    # the udid is the device identifier.  In the case of a simulator the name
    # is the _instruments identifier_ as reported by
    # `$ xcrun instruments -s devices` - this is the identifier that can be
    # passed to instruments.
    #
    # @example
    #  RunLoop::Device.device_with_identifier('iPhone 4s (8.3 Simulator'))
    #  RunLoop::Device.device_with_identifier('6E43E3CF-25F5-41CC-A833-588F043AE749')
    #  RunLoop::Device.device_with_identifier('denis') # Simulator or device named 'denis'
    #  RunLoop::Device.device_with_identifier('893688959205dc7eb48d603c558ede919ad8dd0c')
    #
    # Note that if you have a device and simulator with the same name, the
    # simulator will always be selected.
    #
    # @param [String] udid_or_name A name or udid that identifies the device you
    #  are looking for.
    # @param [Hash] options Allows callers to pass runtime models that might
    #  optimize performance (via memoization).
    # @option options [RunLoop::Simctl] :simctl An instance of
    #  Simctl.
    # @option options [RunLoop::Instruments] :instruments An instance of
    #  Instruments.
    # @option options [RunLoop::Xcode] :xcode An instance of Xcode
    #
    # @return [RunLoop::Device] A device that matches `udid_or_name`.
    # @raise [ArgumentError] If no matching device can be found.
    def self.device_with_identifier(udid_or_name, options={})
      if options[:xcode]
        RunLoop.log_warn("device_with_identifier no longer uses :xcode option")
      end

      default_options = {
        :simctl => RunLoop::Simctl.new,
        :instruments => RunLoop::Instruments.new,
      }

      merged_options = default_options.merge(options)

      instruments = merged_options[:instruments]
      simctl = merged_options[:simctl]

      simulator = simctl.simulators.detect do |sim|
        sim.udid == udid_or_name ||
          sim.simulator_instruments_identifier_same_as?(udid_or_name)
      end

      return simulator if !simulator.nil?

      physical_device = instruments.physical_devices.detect do |device|
        device.name == udid_or_name ||
              device.udid == udid_or_name
      end

      return physical_device if !physical_device.nil?

      raise ArgumentError, "Could not find a device with a UDID or name matching '#{udid_or_name}'"
    end

    # iPhone 8 10.3.1 is the same as iPhone 10.3 when comparing identifiers
    def simulator_instruments_identifier_same_as?(identifier)
      instruments_id = instruments_identifier
      return true if instruments_id == identifier

      model_part = identifier.split(" (").first
      return false if model_part != name

      version_part = RunLoop::Version.new(identifier[RunLoop::Regex::VERSION_REGEX])

      return false if version.major != version_part.major
      return false if version.minor != version_part.minor

      true
    end

    # @!visibility private
    #
    # Please don't call this method.  It is for internal use only.  The behavior
    # may change at any time!  You have been warned.
    #
    # @param [Hash] options The launch options passed to RunLoop::Core
    # @param [RunLoop::Xcode] xcode An Xcode instance
    # @param [RunLoop::Simctl] simctl A Simctl instance
    # @param [RunLoop::Instruments] instruments An Instruments instance
    #
    # @raise [ArgumentError] If "device" is detected as the device target and
    #  there is no matching device.
    # @raise [ArgumentError] If DEVICE_TARGET or options specify an identifier
    #  that does not match an iOS Simulator or physical device.
    def self.detect_device(options, xcode, simctl, instruments)
      device = self.device_from_opts_or_env(options)

      # Passed an instance of RunLoop::Device
      return device if device && device.is_a?(RunLoop::Device)

      # Need to infer what what the user wants from the environment and options.
      if device == "device"
        identifier = self.detect_physical_device_on_usb
        self.ensure_physical_device_connected(identifier, options)
      elsif device.nil? || device == "" || device == "simulator"
        identifier = RunLoop::Core.default_simulator(xcode)
      else
        identifier = device
      end

      # Raises ArgumentError if no matching device can be found.
      self.device_with_identifier(identifier,
                                  simctl: simctl,
                                  instruments: instruments)
    end

    # @!visibility private
    def to_s
      if simulator?
        "#<Simulator: #{name} (#{version.to_s}) #{udid} #{instruction_set}>"
      else
        "#<Device: #{name} (#{version.to_s}) #{udid}>"
      end
    end

    # @!visibility private
    def inspect
      to_s
    end

    # Returns and instruments-ready device identifier that is a suitable value
    # for DEVICE_TARGET environment variable.
    #
    # @param [RunLoop::Xcode] xcode The version of the active
    #  Xcode.
    # @return [String] An instruments-ready device identifier.
    # @raise [RuntimeError] If trying to obtain a instruments-ready identifier
    #  for a simulator when Xcode < 6.
    def instruments_identifier(xcode=nil)
      if xcode
        RunLoop.deprecated("3.0.0",
                           "instruments_identifier no longer takes an argument")
      end
      if physical_device?
        udid
      else
        if version.patch
          version_part = "#{version.major}.#{version.minor}.#{version.patch}"
        else
          version_part = "#{version.major}.#{version.minor}"
        end

        "#{name} (#{version_part})"
      end
    end

    # Is this a physical device?
    # @return [Boolean] Returns true if this is a device.
    def physical_device?
      if udid.nil?
        stack = Kernel.caller(0, 6)[0..-1].join("\n")
        raise RuntimeError,
          %Q[udid is nil

#{stack}

   name: #{name}
version: #{version}
]
      end
      !udid[DEVICE_UDID_REGEX, 0].nil?
    end

    # Is this a simulator?
    # @return [Boolean] Returns true if this is a simulator.
    def simulator?
      !physical_device?
    end

    # Is the iOS version installed on this device compatible with an Xcode
    # version?
    def compatible_with_xcode_version?(xcode_version)
      ios_version = version

      if ios_version.major < (xcode_version.major + 2)
        if physical_device?
          return true
        else
          # iOS 8 simulators are available in Xcode 9
          # iOS 7 simulators are not available in Xcode 9
          if ios_version.major <= (xcode_version.major - 2)
            return false
          else
            return true
          end
        end
      end

      if ios_version.major == (xcode_version.major + 2)
        return ios_version.minor <= xcode_version.minor
      end

      false
    end

    # Return the instruction set for this device.
    #
    # **Simulator**
    # The simulator instruction set will be i386 or x86_64 depending on the
    # the (marketing) name of the device.
    #
    # @note Finding the instruction set of a device requires a third-party tool
    #  like ideviceinfo.  Example:
    #  `$ ideviceinfo  -u 89b59 < snip > ab7ba --key 'CPUArchitecture' => arm64`
    #
    # @raise [RuntimeError] Raises an error if this device is a physical device.
    # @return [String] An instruction set.
    def instruction_set
      if simulator?
        if ['iPhone 4s', 'iPhone 5', 'iPad 2', 'iPad Retina'].include?(self.name)
          'i386'
        else
          'x86_64'
        end
      else
        raise 'Finding the instruction set of a device requires a third-party tool like ideviceinfo'
      end
    end

    # @!visibility private
    # The device `state` is reported by the simctl tool.
    #
    # The expected values from simctl are:
    #
    # * Booted
    # * Shutdown
    # * Shutting Down
    #
    # To handle exceptional cases, there are these two additional states:
    #
    # * Unavailable # Should never occur
    # * Unknown     # A stub for future changes
    def update_simulator_state
      if physical_device?
        raise RuntimeError, 'This method is available only for simulators'
      end

      @state = simctl.simulator_state_as_string(self)
    end

    # @!visibility private
    def simulator_root_dir
      return nil if physical_device?
      @simulator_root_dir ||= File.join(CORE_SIMULATOR_DEVICE_DIR, udid)
    end

    # @!visibility private
    def simulator_accessibility_plist_path
      return nil if physical_device?

      directory = File.join(simulator_root_dir, "data", "Library", "Preferences")
      pbuddy.ensure_plist(directory, "com.apple.Accessibility.plist")
    end

    # @!visibility private
    def simulator_log_file_path
      return nil if physical_device?
      @simulator_log_file_path ||= File.join(CORE_SIMULATOR_LOGS_DIR, udid,
                                             'system.log')
    end

    # @!visibility private
    def simulator_device_plist
      return nil if physical_device?
      pbuddy.ensure_plist(simulator_root_dir, "device.plist")
    end

    # @!visibility private
    def simulator_global_preferences_path
      return nil if physical_device?
      directory = File.join(simulator_root_dir, "data", "Library", "Preferences")
      pbuddy.ensure_plist(directory, ".GlobalPreferences.plist")
    end

    # @!visibility private
    # In megabytes
    def simulator_size_on_disk
      data_path = File.join(simulator_root_dir, 'data')
      RunLoop::Directory.size(data_path, :mb)
    end

    # @!visibility private
    def simulator_wait_for_stable_state
      required = simulator_required_child_processes

      timeout = SIM_STABLE_STATE_OPTIONS[:timeout]
      now = Time.now
      poll_until = now + timeout

      RunLoop.log_debug("Waiting for simulator to stabilize with timeout: #{timeout} seconds")
      footprint = simulator_size_on_disk

      if version.major >= 9 && footprint < 18
        first_launch = true
      elsif version.major == 8
        if version.minor >= 3 && footprint < 19
          first_launch = true
        else
          first_launch = footprint < 11
        end
      else
        first_launch = false
      end

      while !required.empty? && Time.now < poll_until do
        sleep(0.5)
        required = required.map do |process_name|
          if simulator_process_running?(process_name)
            nil
          else
            process_name
          end
        end.compact
      end

      if required.empty?
        elapsed = Time.now - now
        RunLoop.log_debug("All required simulator processes have started after #{elapsed}")
        if first_launch
          RunLoop.log_debug("Detected a first launch, waiting a little longer - footprint was #{footprint} MB")
          sleep(RunLoop::Environment.ci? ? 10 : 5)
        end
        RunLoop.log_debug("Waited for #{elapsed} seconds for simulator to stabilize")
      else
        RunLoop.log_debug("Timed out after #{timeout} seconds waiting for simulator to stabilize")
        RunLoop.log_debug("These simulator processes did not start: #{required.join(",")}")
      end
    end

    # @!visibility private
    #
    # Sets the AppleLocale key in the .GlobalPreferences.plist file
    #
    # @param [String] locale_code a locale code
    #
    # @return [RunLoop::Locale] a locale instance
    #
    # @raise [RuntimeError] if this is a physical device
    # @raise [ArgumentError] if the locale code is invalid
    def simulator_set_locale(locale_code)
      if physical_device?
        raise RuntimeError, "This method is for Simulators only"
      end

      locale = RunLoop::Locale.locale_for_code(locale_code, self)

      global_plist = simulator_global_preferences_path
      pbuddy.plist_set("AppleLocale", "string", locale.code, global_plist)

      locale
    end

    # @!visibility private
    #
    # Returns the AppleLanguages array in global plist as an array
    #
    # @return [Array<String>] list of language codes
    def simulator_languages
      global_plist = simulator_global_preferences_path
      out = pbuddy.plist_read("AppleLanguages", global_plist)

      # example: "Array {\n    en\n    en-US\n}"
      # I am intentionally punting on this because I don't want
      # to track down edge cases until the output of this method
      # is actually used.
      result = [out]
      begin
        result = out.strip.gsub(/[\{\}]/, "").split($-0).map do |elm|
          elm.strip
        end[1..-1]
      rescue => e
        RunLoop.log_debug("Caught error #{e.message} trying to parse '#{out}'")
      end

      result
    end

    # @!visibility private
    #
    # Sets the first element in the AppleLanguages array to lang_code.
    #
    # @param [String] lang_code a language code
    #
    # @return [Array<String>] list of language codes
    #
    # @raise [RuntimeError] if this is a physical device
    # @raise [ArgumentError] if the language code is invalid
    def simulator_set_language(lang_code)
      if physical_device?
        raise RuntimeError, "This method is for Simulators only"
      end

      if !RunLoop::Language.valid_code_for_device?(lang_code, self)
        raise ArgumentError,
          "The language code '#{lang_code}' is not valid for this device"
      end

      global_plist = simulator_global_preferences_path

      begin
        pbuddy.unshift_array("AppleLanguages", "string", lang_code,
                             global_plist)
      rescue RuntimeError => e
        raise RuntimeError, %Q[
Could not update the Simulator languages.

#{e.message}

]
      end

      simulator_languages
    end

    # @!visibility private
    def simulator_running_app_details
      pids = simulator_running_app_pids
      running_apps = {}

      pids.each do |pid|
        cmd = ["ps", "-o", "comm=", "-p", pid.to_s]

        hash = run_shell_command(cmd)
        out = hash[:out]

        if out.nil? || out == "" || out.strip.nil?
          nil
        else
          name = out.strip.split("/").last

          cmd = ["ps", "-o", "command=", "-p", pid.to_s]
          hash = run_shell_command(cmd)
          out = hash[:out]

          if out.nil? || out == "" || out.strip.nil?
            nil
          else
            tokens = out.split("#{name} ")

            # No arguments
            if tokens.count == 1
              args = ""
            else
              args = tokens.last.strip
            end

            running_apps[name] = {
              args: args,
              command: out.strip
            }
          end
        end
      end

      running_apps
    end

=begin
  PRIVATE METHODS
=end

    private

    attr_reader :pbuddy, :simctl, :xcrun, :xcode

    # @!visibility private
    def xcode
      @xcode ||= RunLoop::Xcode.new
    end

    # @!visibility private
    def xcrun
      RunLoop::Xcrun.new
    end

    # @!visibility private
    def pbuddy
      RunLoop::PlistBuddy.new
    end

    # @!visibility private
    def simctl
      @simctl ||= RunLoop::Simctl.new
    end

    # @!visibility private
    CORE_SIMULATOR_DEVICE_DIR = File.join(RunLoop::Environment.user_home_directory,
                                          "Library",
                                          "Developer",
                                          "CoreSimulator",
                                          "Devices")

    # @!visibility private
    CORE_SIMULATOR_LOGS_DIR = File.join(RunLoop::Environment.user_home_directory,
                                        "Library",
                                        "Logs",
                                        "CoreSimulator")

    # @!visibility private
    def self.device_from_options(options)
      options[:device] || options[:device_target] || options[:udid]
    end

    # @!visibility private
    def self.device_from_environment
      RunLoop::Environment.device_target
    end

    # @!visibility private
    def self.device_from_opts_or_env(options)
      self.device_from_options(options) || self.device_from_environment
    end

    # @!visibility private
    UDID_DETECT = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", 'scripts', "udidetect"))

    # @!visibility private
    def self.detect_physical_device_on_usb
      require "command_runner"

      udid = nil
      begin
        hash = CommandRunner.run([UDID_DETECT], timeout: 1)
        udid = hash[:out].chomp
        if udid == ""
          udid = nil
        end
      rescue => e
        RunLoop.log_debug("Running `udidetect` raised: #{e}")
      ensure
        `killall udidetect &> /dev/null`
      end
      udid
    end

    # @!visibility private
    def simulator_required_child_processes
      # required: ["SimulatorBridge", "medialibraryd"]
      @simulator_required_child_processes ||= begin
        if xcode.version_gte_100?
          required = ["backboardd", "installd", "SpringBoard"]
        elsif xcode.version_gte_83? && version.major > 10
          required = ["backboardd", "installd", "SpringBoard", "suggestd"]
        else
          required = ["backboardd", "installd", "SimulatorBridge", "SpringBoard"]
        end

        if xcode.version_gte_90?
          required << "filecoordinationd"
        elsif xcode.version_gte_8? && (version.major > 8 && version.major < 11)
          required << "medialibraryd"
        end

        if simulator_is_ipad? && version.major == 9
          required << "com.apple.audio.SystemSoundServer-iOS-Simulator"
        end

        required
      end
    end

    # @!visibility private
    def simulator_launchd_sim_pid
      waiter = RunLoop::ProcessWaiter.new("launchd_sim")
      waiter.wait_for_any

      return nil if !waiter.running_process?

      pid = nil

      waiter.pids.each do |launchd_sim_pid|
        cmd = ["ps", "x", "-o", "pid,command", launchd_sim_pid.to_s]
        hash = run_shell_command(cmd)
        out = hash[:out]
        process_line = out.split($-0)[1]
        if !process_line || process_line == ""
          false
        else
          pid = process_line.split(" ").first.strip
          if process_line[/#{udid}/] == nil
            RunLoop.log_debug("Terminating launchd_sim process with pid #{pid}")
            RunLoop::ProcessTerminator.new(pid, "KILL", "launchd_sim").kill_process
            pid = nil
          end
        end
      end
      pid
    end

    # @!visibility private
    def process_parent_is_launchd_sim?(pid)
      launchd_sim_pid = simulator_launchd_sim_pid
      return false if !launchd_sim_pid

      cmd = ["ps", "x", "-o", "ppid=", "-p", pid.to_s]
      hash = run_shell_command(cmd)

      out = hash[:out]
      if out.nil? || out == ""
        false
      else
        ppid = out.strip
        ppid == launchd_sim_pid.to_s
      end
    end

    # @!visibility private
    def simulator_process_running?(process_name)
      waiter = RunLoop::ProcessWaiter.new(process_name)
      waiter.pids.any? do |pid|
        process_parent_is_launchd_sim?(pid)
      end
    end

    # @!visibility private
    def simulator_data_directory_sha
      path = File.join(simulator_root_dir, 'data')
      begin
        # Typically, this returns in < 0.3 seconds.
        Timeout.timeout(10, TimeoutError) do
          # Errors are ignorable and users are confused by the messages.
          options = { :handle_errors_by => :ignoring }
          RunLoop::Directory.directory_digest(path, options)
        end
      rescue => _
        SecureRandom.uuid
      end
    end

    # @!visibility private
    def simulator_log_file_sha
      file = simulator_log_file_path

      return nil if !File.exist?(file)

      sha = OpenSSL::Digest::SHA256.new

      begin
        sha << File.read(file)
      rescue => _
        sha = SecureRandom.uuid
      end

      sha
    end

    # @!visibility private
    # Value of <UDID>/.device.plist 'deviceType' key.
    def simulator_device_type
      plist = File.join(simulator_device_plist)
      pbuddy.plist_read("deviceType", plist)
    end

    # @!visibility private
    def simulator_is_ipad?
      simulator_device_type[/iPad/, 0]
    end

    # @!visibility private
    def self.ensure_physical_device_connected(identifier, options)
      if identifier.nil?
        env = self.device_from_environment
        if env == "device"
          message = "DEVICE_TARGET=device means that you want to test on physical device"
        elsif env && env[DEVICE_UDID_REGEX, 0]
          message = "DEVICE_TARGET=#{env} did not match any connected device"
        else
          if options[:device]
            key = ":device"
          elsif options[:device_target]
            key = ":device_target"
          else
            key = ":udid"
          end
          message = "#{key} => \"device\" means that you want to test on a physical device"
        end

        raise ArgumentError, %Q[Expected a physical device to be connected via USB.

#{message}

1. Is your device connected?
2. Does your device appear in the output of `xcrun instruments -s devices`?
3. Does your device appear in Xcode > Windows > Devices without a warning message?

Please see the documentation about testing on physical devices.

https://github.com/calabash/calabash-ios/wiki/Testing-on-Physical-Devices
]
      end
      true
    end

    # @!visibility private
    def simulator_running_app_pids
      simulator_running_user_app_pids +
        simulator_running_system_app_pids
    end

    # @!visibility private
    def simulator_running_user_app_pids
      path = File.join(udid, "data", "Containers", "Bundle")
      RunLoop::ProcessWaiter.pgrep_f(path)
    end

    # @!visibility private
    def simulator_running_system_app_pids
      base_dir = xcode.developer_dir
      if xcode.version_gte_90?
        sim_apps_dir = "Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot/Applications"
      else
        sim_apps_dir = "Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/Applications"
      end
      path = File.expand_path(File.join(base_dir, sim_apps_dir))
      RunLoop::ProcessWaiter.pgrep_f(path)
    end
  end
end

