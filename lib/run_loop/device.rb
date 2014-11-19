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
  end
end
