module RunLoop
  class Device

    include RunLoop::Regex

    # @!visibility private
    # State from device.plist if simulator has been launched once.
    SIM_INSTALLED_STATE_YES = 3

    # @!visibility private
    # State from device.plist if the simulator has not been launched since
    # a reset or a new Simulator install.
    SIM_INSTALLED_STATE_NO = 1

    # @!visibility private
    # The installation state if there is a problem reading the device.plist.
    SIM_INSTALLED_STATE_UNKNOWN = -1

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
    # @note As of 1.5.0, the XCTools optional argument has become a non-optional
    #  Xcode argument.
    #
    # @param [RunLoop::Xcode, RunLoop::XCTools] xcode The version of the active
    #  Xcode.
    # @return [String] An instruments-ready device identifier.
    # @raise [RuntimeError] If trying to obtain a instruments-ready identifier
    #  for a simulator when Xcode < 6.
    def instruments_identifier(xcode=SIM_CONTROL.xcode)
      if xcode.is_a?(RunLoop::XCTools)
        RunLoop.deprecated('1.5.0',
                           %q(
RunLoop::XCTools has been replaced with a non-optional RunLoop::Xcode argument.
Please update your sources to pass an instance of RunLoop::Xcode))
      end

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
    #
    # Don't get this confused with the simulator _installed_ state which
    # indicates whether or not the simulator has been launched once since a
    # reset or new Simulator installation.
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
    # The install state of the simulator indicates whether or not the Simulator
    # has been launched since a reset or new Simulator installation.
    #
    # The installation process populates the data/ directory of the Simulator.
    #
    # The size of the data directory varies with iOS version and model, so the
    # first launch can sometimes take more than 15 seconds.
    #
    # This is particularly true of the iOS 9 simulators which are completely
    # unresponsive during the "install" process; displaying an Apple logo with
    # a progress bar.
    #
    # Unfortunately, the value of the 'state' key in the device.plist changes
    # the moment the simulator is launched and so we cannot wait for a good
    # state.
    #
    #  * -1  # something when wrong while trying to read the state
    #  * 1   # has not been launched
    #  * 3   # has been launched once and is presumably ready
    #
    # TODO needs better unit tests.
    def simulator_install_state
      state = SIM_INSTALLED_STATE_UNKNOWN
      begin
        state = pbuddy.plist_read('state', simulator_device_plist).to_i
      rescue StandardError => e
        RunLoop.log_error(e)
      end
      state
    end

    # @!visibility private
    # The model name by inspecting the device.plist.
    #
    # We will need this value when trying to determine the size of the installed
    # CoreSimulator.  We cannot rely on the device.name because it might be
    # simulator created by the user.
    #
    # Fall back to `name` if there is an error.
    #
    # TODO needs unit tests.
    def simulator_model_name
      begin
        value = pbuddy.plist_read('deviceType', simulator_device_plist)
        value.split('.').last.tr('-', ' ')
      rescue StandardError => e
        RunLoop.log_error(e)
        name
      end
    end

    # @!visibility private
    # The size of the simulator data/ directory.
    #
    # TODO needs unit tests.
    def simulator_data_dir_size
      path = File.join(simulator_root_dir, 'data')
      args = ['du', '-m', '-d', '0', path]
      hash = xcrun.exec(args)
      hash[:out].split(' ').first.to_i
    end

    # @!visibility private
    # TODO needs unit tests.
    def wait_for_simulator_to_install(timeout=15)
      target_mb = target_mb_for_install
      now = Time.now
      timeout = timeout
      poll_until = now + timeout
      delay = 0.1
      is_installed = false

      while Time.now < poll_until
        is_installed = simulator_data_dir_size >= target_mb
        break if is_installed
        sleep delay
      end

      if is_installed
        elapsed = Time.now - now
        RunLoop.log_debug("Waited #{elapsed} seconds for the simulator to install '#{target_mb} MB'")
      else
        mb = simulator_data_dir_size
        RunLoop.log_debug("Simulator did not finish installing after #{timeout} seconds and installing '#{mb} MB'; proceeding regardless")
      end

      is_installed
    end

    # @!visibility private
    #
    # The timeout should be ~5 seconds.
    # A quiet_time of 1 seconds is sufficient.
    #
    # Note: this does not solve the problem of "simulator is booting" that
    # appeared in Xcode 7 - the log stops writing, but the device is still
    # booting.
    #
    # TODO write a unit test.
    def wait_for_simulator_log_to_stop_updating(timeout, quiet_time)
      now = Time.now
      timeout = timeout
      poll_until = now + timeout
      delay = 0.1
      quiet = now + quiet_time

      same_line = false
      current_line = nil

      while Time.now < poll_until do
        latest_line = last_line_from_simulator_log_file
        same_line = current_line == latest_line

        break if same_line && Time.now > quiet

        current_line = latest_line
        sleep delay
      end

      if same_line
        elapsed = Time.now - now
        stabilized = elapsed - quiet_time
        RunLoop.log_debug("Simulator log file stop updating after #{stabilized} seconds")
        RunLoop.log_debug("Waited a total of #{elapsed} seconds for the log to stabilize")
      else
        RunLoop.log_debug("Simulator log file did not stabilize after #{timeout} seconds; proceeding regardless")
      end
    end

    private

    # @!visibility private
    # TODO write a unit test.
    def last_line_from_simulator_log_file
      file = simulator_log_file_path

      return nil if !File.exist?(file)

      begin
        io = File.open(file, 'r')
        io.seek(-100, IO::SEEK_END)

        line = io.readline
      rescue StandardError => e
        RunLoop.log_debug("Caught #{e} while reading simulator log file")
      ensure
        io.close if io && !io.closed?
      end

      line
    end

    # @!visibility private
    def xcrun
      RunLoop::Xcrun.new
    end

    # @!visibility private
    def pbuddy
      @pbuddy ||= RunLoop::PlistBuddy.new
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

    # @!visibility private
    def target_mb_for_install
      model_key = simulator_model_name
      version_key = version.to_s

      version_hash = MB_FOR_SIM_DATA_DIR[version_key]

      if !version_hash
        value = MB_FOR_SIM_DATA_DIR[model_key]
      else
        value = version_hash[model_key]
      end

      value = 34 if !value

      value * MB_FOR_SIM_DATA_DIR_SCALE
    end

    # @!visibility private
    # How much to scale the default MB when waiting for install.
    MB_FOR_SIM_DATA_DIR_SCALE = 0.66

    # @!visibility private
    # Typical size for data/ directory by iOS and model.
    MB_FOR_SIM_DATA_DIR = {
          '7.1' => {
                'iPhone 4s' => 12,
                'iPhone 5' => 12,
                'iPhone 5s' => 17,
                'iPad 2' => 10,
                'iPad Retina' => 14,
                'iPad Air' => 14
          },

          '8.0' => {
                'iPhone 4s' => 23,
                'iPhone 5' => 25,
                'iPhone 5s' => 25,
                'iPhone 6' => 26,
                'iPhone 6 Plus' => 30,
                'iPad 2' => 21,
                'iPad Retina' => 27,
                'iPad Air' => 27,
                'Resizable iPhone' => 37,
                'Resizable iPad' => 34
          },

          '8.1' => {
                'iPhone 4s' => 23,
                'iPhone 5' => 25,
                'iPhone 5s' => 25,
                'iPhone 6' => 26,
                'iPhone 6 Plus' => 30,
                'iPad 2' => 21,
                'iPad Retina' => 27,
                'iPad Air' => 27,
                'Resizable iPhone' => 37,
                'Resizable iPad' => 34
          },

          '8.2' => {
                'iPhone 4s' => 16,
                'iPhone 5' => 16,
                'iPhone 5s' => 16,
                'iPhone 6' => 25,
                'iPhone 6 Plus' => 40,
                'iPad 2' => 21,
                'iPad Retina' => 35,
                'iPad Air' => 35,
                'Resizable iPhone' => 33,
                'Resizable iPad' => 34
          },

          '8.3' => {
                'iPhone 4s' => 32,
                'iPhone 5' => 33,
                'iPhone 5s' => 33,
                'iPhone 6' => 33,
                'iPhone 6 Plus' => 43,
                'iPad 2' => 32,
                'iPad Retina' => 35,
                'iPad Air' => 35,
                'Resizable iPhone' => 29,
                'Resizable iPad' => 30
          },

          '8.4' => {
                'iPhone 4s' => 32,
                'iPhone 5' => 33,
                'iPhone 5s' => 33,
                'iPhone 6' => 33,
                'iPhone 6 Plus' => 43,
                'iPad 2' => 32,
                'iPad Retina' => 35,
                'iPad Air' => 35,
                'Resizable iPhone' => 26,
                'Resizable iPad' => 27
          },

          '9.0' => {
                'iPhone 4s' => 33,
                'iPhone 5' => 32,
                'iPhone 5s' => 27,
                'iPhone 6' => 27,
                'iPhone 6 Plus' => 38,
                'iPhone 6s' => 32,
                'iPhone 6s Plus' => 39,
                'iPad 2' => 29,
                'iPad Retina' => 34,
                'iPad Air' => 34,
                'iPad Air 2' => 44
          },

          # Thinking ahead to iOS 9.*
          'iPhone 4s' => 34,
          'iPhone 5' => 34,
          'iPhone 5s' => 35,
          'iPhone 6' => 40,
          'iPhone 6 Plus' => 39,
          'iPhone 6s' => 40,
          'iPhone 6s Plus' => 46,
          'iPad 2' => 31,
          'iPad Retina' => 35,
          'iPad Air' => 37,
          'iPad Air 2' => 53
    }

  end
end
