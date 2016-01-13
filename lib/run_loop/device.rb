module RunLoop
  class Device

    include RunLoop::Regex

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
      :timeout => RunLoop::Environment.ci? ? 120 : 30
    }

    attr_reader :name
    attr_reader :version
    attr_reader :udid
    attr_reader :state
    attr_reader :simulator_root_dir
    attr_reader :simulator_accessibility_plist_path
    attr_reader :simulator_preferences_plist_path
    attr_reader :simulator_log_file_path
    attr_reader :pbuddy

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
    # @option options [RunLoop::SimControl] :sim_control An instance of
    #  SimControl.
    # @option options [RunLoop::Instruments] :instruments An instance of
    #  Instruments.
    #
    # @return [RunLoop::Device] A device that matches `udid_or_name`.
    # @raise [ArgumentError] If no matching device can be found.
    def self.device_with_identifier(udid_or_name, options={})
      if options.is_a?(RunLoop::SimControl)
        RunLoop.deprecated('1.5.0', %q(
The 'sim_control' argument has been deprecated.  It has been replaced by an
options hash with two keys: :sim_control and :instruments.
Please update your sources.))
        merged_options = {
              :sim_control => options,
              :instruments => RunLoop::Instruments.new
        }
      else
        default_options = {
              :sim_control => RunLoop::SimControl.new,
              :instruments => RunLoop::Instruments.new
        }
        merged_options = default_options.merge(options)
      end

      instruments = merged_options[:instruments]
      sim_control = merged_options[:sim_control]

      xcode = sim_control.xcode
      simulator = sim_control.simulators.detect do |sim|
        sim.instruments_identifier(xcode) == udid_or_name ||
              sim.udid == udid_or_name
      end

      return simulator if !simulator.nil?

      physical_device = instruments.physical_devices.detect do |device|
        device.name == udid_or_name ||
              device.udid == udid_or_name
      end

      return physical_device if !physical_device.nil?

      raise ArgumentError, "Could not find a device with a UDID or name matching '#{udid_or_name}'"
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
    def instruments_identifier(xcode=SIM_CONTROL.xcode)
      if physical_device?
        udid
      else
        if version == RunLoop::Version.new('7.0.3')
          version_part = version.to_s
        else
          version_part = "#{version.major}.#{version.minor}"
        end

        if xcode.version_gte_7?
          "#{name} (#{version_part})"
        elsif xcode.version_gte_6?
          "#{name} (#{version_part} Simulator)"
        else
          udid
        end
      end
    end

    # Is this a physical device?
    # @return [Boolean] Returns true if this is a device.
    def physical_device?
      not udid[DEVICE_UDID_REGEX, 0].nil?
    end

    # Is this a simulator?
    # @return [Boolean] Returns true if this is a simulator.
    def simulator?
      not physical_device?
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

      @state = fetch_simulator_state
    end

    # @!visibility private
    def simulator_root_dir
      @simulator_root_dir ||= lambda {
        return nil if physical_device?
        File.join(CORE_SIMULATOR_DEVICE_DIR, udid)
      }.call
    end

    # @!visibility private
    def simulator_accessibility_plist_path
      @simulator_accessibility_plist_path ||= lambda {
        return nil if physical_device?
        File.join(simulator_root_dir, 'data/Library/Preferences/com.apple.Accessibility.plist')
      }.call
    end

    # @!visibility private
    def simulator_preferences_plist_path
      @simulator_preferences_plist_path ||= lambda {
        return nil if physical_device?
        File.join(simulator_root_dir, 'data/Library/Preferences/com.apple.Preferences.plist')
      }.call
    end

    # @!visibility private
    def simulator_log_file_path
      @simulator_log_file_path ||= lambda {
        return nil if physical_device?
        File.join(CORE_SIMULATOR_LOGS_DIR, udid, 'system.log')
      }.call
    end

    # @!visibility private
    def simulator_device_plist
      @simulator_device_plist ||= lambda do
        return nil if physical_device?
        File.join(simulator_root_dir, 'device.plist')
      end.call
    end

    # @!visibility private
    def simulator_global_preferences_path
      @simulator_global_preferences_path ||= lambda do
        return nil if physical_device?
        File.join(simulator_root_dir, "data/Library/Preferences/.GlobalPreferences.plist")
      end.call
    end

    # @!visibility private
    # Is this the first launch of this Simulator?
    #
    # TODO Needs unit and integration tests.
    def simulator_first_launch?
      megabytes = simulator_data_dir_size

      if version >= RunLoop::Version.new('9.0')
        megabytes < 20
      elsif version >= RunLoop::Version.new('8.0')
        megabytes < 12
      else
        megabytes < 8
      end
    end

    # @!visibility private
    # The size of the simulator data/ directory.
    #
    # TODO needs unit tests.
    def simulator_data_dir_size
      path = File.join(simulator_root_dir, 'data')
      RunLoop::Directory.size(path, :mb)
    end

    # @!visibility private
    #
    # Waits for three conditions:
    #
    # 1. The SHA sum of the simulator data/ directory to be stable.
    # 2. No more log messages are begin generated
    # 3. 1 and 2 must hold for 1 seconds.
    #
    # When the simulator version is >= iOS 9 _and_ it is the first launch of
    # the simulator after a reset or a new simulator install, a fourth condition
    # is added:
    #
    # 4. The first three conditions must be met a second time.
    #
    # and the quiet time is increased to 2.0.
    def simulator_wait_for_stable_state
      require 'securerandom'

      # How long to wait between stability checks.
      delay = 0.5

      first_launch = false

      # At launch there is a brief moment when the SHA and
      # the log file are are stable.  Then a bunch of activity
      # occurs.  This is the quiet time.
      #
      # Starting in iOS 9, simulators display at _booting_ screen
      # at first launch.  At first launch, these simulators need
      # a much longer quiet time.
      if version >= RunLoop::Version.new('9.0')
        first_launch = simulator_data_dir_size < 20
        quiet_time = 2.0
      else
        quiet_time = 1.0
      end

      now = Time.now
      timeout = SIM_STABLE_STATE_OPTIONS[:timeout]
      poll_until = now + timeout
      quiet = now + quiet_time

      is_stable = false

      path = File.join(simulator_root_dir, 'data')
      current_sha = nil
      sha_fn = lambda do |data_dir|
        begin
          # Typically, this returns in < 0.3 seconds.
          Timeout.timeout(10, TimeoutError) do
            # Errors are ignorable and users are confused by the messages.
            options = { :handle_errors_by => :ignoring }
            RunLoop::Directory.directory_digest(data_dir, options)
          end
        rescue => _
          SecureRandom.uuid
        end
      end

      RunLoop.log_debug("Waiting for simulator to stabilize with timeout: #{timeout}")
      if first_launch
        RunLoop.log_debug("Detected the first launch of an iOS >= 9.0 Simulator")
      end

      current_line = nil

      while Time.now < poll_until do
        latest_sha = sha_fn.call(path)
        latest_line = last_line_from_simulator_log_file

        is_stable = current_sha == latest_sha && current_line == latest_line

        if is_stable
          if Time.now > quiet
            if first_launch
              RunLoop.log_debug('First launch detected - allowing additional time to stabilize')
              first_launch = false
              sleep 1.2
              quiet = Time.now + quiet_time
            else
              break
            end
          else
            quiet = Time.now + quiet_time
          end
        end

        current_sha = latest_sha
        current_line = latest_line
        sleep delay
      end

      if is_stable
        elapsed = Time.now - now
        stabilized = elapsed - quiet_time
        RunLoop.log_debug("Simulator stable after #{stabilized} seconds")
        RunLoop.log_debug("Waited a total of #{elapsed} seconds for simulator to stabilize")
      else
        RunLoop.log_debug("Timed out: simulator not stable after #{timeout} seconds")
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

    private

    # @!visibility private
    # TODO write a unit test.
    def last_line_from_simulator_log_file
      file = simulator_log_file_path

      return nil if !File.exist?(file)

      debug = RunLoop::Environment.debug?

      begin
        io = File.open(file, 'r')
        io.seek(-100, IO::SEEK_END)

        line = io.readline
      rescue StandardError => e
        RunLoop.log_error("Caught #{e} while reading simulator log file") if debug
      ensure
        io.close if io && !io.closed?
      end

      if line
        line.chomp
      else
        line
      end
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
    def detect_state_from_line(line)

      if line[/unavailable/, 0]
        RunLoop.log_debug("Simulator state is unavailable: #{line}")
        return 'Unavailable'
      end

      state = line[/(Booted|Shutdown|Shutting Down)/,0]

      if state.nil?
        RunLoop.log_debug("Simulator state is unknown: #{line}")
        'Unknown'
      else
        state
      end
    end

    # @!visibility private
    def fetch_simulator_state
      if physical_device?
        raise RuntimeError, 'This method is available only for simulators'
      end

      args = ['simctl', 'list', 'devices']
      hash = xcrun.exec(args)
      out = hash[:out]

      matched_line = out.split("\n").find do |line|
        line.include?(udid)
      end

      if matched_line.nil?
        raise RuntimeError,
              "Expected a simulator with udid '#{udid}', but found none"
      end

      detect_state_from_line(matched_line)
    end

    # @!visibility private
    CORE_SIMULATOR_DEVICE_DIR = File.expand_path('~/Library/Developer/CoreSimulator/Devices')

    # @!visibility private
    CORE_SIMULATOR_LOGS_DIR = File.expand_path('~/Library/Logs/CoreSimulator')

    # TODO Is this a good idea?  It speeds up rspec tests by a factor of ~2x...
    SIM_CONTROL = RunLoop::SimControl.new
  end
end
