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
