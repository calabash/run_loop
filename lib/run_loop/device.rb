module RunLoop
  class Device

    attr_reader :name
    attr_reader :version
    attr_reader :udid
    attr_reader :state
    attr_reader :simulator_root_dir
    attr_reader :simulator_preferences_path

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

    # Returns and instruments-ready device identifier that is a suitable value
    # for DEVICE_TARGET environment variable.
    #
    # @return [String] An instruments-ready device identifier.
    # @raise [RuntimeError] If trying to obtain a instruments-ready identifier
    #  for a simulator when Xcode < 6.
    def instruments_identifier(xcode_tools=RunLoop::XCTools.new)
      if physical_device?
        self.udid
      else
        unless xcode_tools.xcode_version_gte_6?
          raise "Expected Xcode >= 6, but found version #{xcode_tools.version} - cannot create an identifier"
        end
        if self.version == RunLoop::Version.new('7.0.3')
          version_part = self.version.to_s
        else
          version_part = "#{self.version.major}.#{self.version.minor}"
        end
        "#{self.name} (#{version_part} Simulator)"
      end
    end

    # Is this a physical device?
    # @return [Boolean] Returns true if this is a device.
    def physical_device?
      not self.udid[/[a-f0-9]{40}/, 0].nil?
    end

    # Is this a simulator?
    # @return [Boolean] Returns true if this is a simulator.
    def simulator?
      not self.physical_device?
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
      if self.simulator?
        if ['iPhone 4s', 'iPhone 5', 'iPad 2', 'iPad Retina'].include?(self.name)
          'i386'
        else
          'x86_64'
        end
      else
        raise 'Finding the instruction set of a device requires a third-party tool like ideviceinfo'
      end
    end

    def simulator_root_dir
      @simulator_root_dir ||= lambda {
        return nil if physical_device?
        File.join(CORE_SIMULATOR_DEVICE_DIR, udid)
      }.call
    end

    def simulator_accessibility_plist_path
      @simulator_accessibility_plist_path ||= lambda {
        return nil if physical_device?
        File.join(simulator_root_dir, 'data/Library/Preferences/com.apple.Accessibility.plist')
      }.call
    end

    private

    CORE_SIMULATOR_DEVICE_DIR = File.expand_path('~/Library/Developer/CoreSimulator/Devices')
  end
end
