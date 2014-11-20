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

    # Is this device a simulator?
    # @return [Boolean] Return true if this device is a simulator.
    def simulator?
      not physical_device?
    end

    # Is this is a physical device?
    # @return [Boolean] Return true if this is a physical device.
    def physical_device?
      (self.udid =~ /[a-f0-9]{40}/) == 0
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
  end
end
