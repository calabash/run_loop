module RunLoop
  class Device

    attr_reader :name
    attr_reader :version
    attr_reader :udid

    def initialize(name, version, udid)
      @name = name

      if version.is_a? String
        @version = RunLoop::Version.new version
      else
        @version = version
      end

      @udid = udid
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

    private

    def instruction_set
      if self.simulator?
        if ['iPhone 4s', 'iPhone 5', 'iPad 2', 'iPad Retina'].include?(self.name)
          :i386
        else
          :x86_64
        end
      else
        raise 'Finding this instruction set of a device requires a third-party tool like ideviceinfo'
        # Example
        # $ ideviceinfo  -u 89b59 < snip > ab7ba --key 'CPUArchitecture'
        # arm64
      end
    end
  end
end
