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

  end

end