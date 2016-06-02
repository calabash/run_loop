
module RunLoop
  # @!visibility private
  #
  # An abstract base class for something that can launch the CBXRunner on a
  # device.  The CBXRunner is AKA the DeviceAgent.
  class Launcher
    require "run_loop/abstract"
    include RunLoop::Abstract

    # @!visibility private
    attr_reader :device

    # @!visibility private
    # @param [RunLoop::Device] device where to launch the CBX-Runner
    def initialize(device)
      @device = device

      if device.version < RunLoop::Version.new("9.0")
        raise ArgumentError, %Q[
Invalid device:

#{device}

XCUITest is only available for iOS >= 9.0
]
      end
    end

    # @!visibility private
    #
    # Does whatever it takes to launch the CBX-Runner on the device.
    def launch
      abstract_method!
    end

    # @!visibility private
    def self.dot_dir
      path = File.join(RunLoop::DotDir.directory, "xcuitest")

      if !File.exist?(path)
        FileUtils.mkdir_p(path)
      end

      path
    end
  end
end
