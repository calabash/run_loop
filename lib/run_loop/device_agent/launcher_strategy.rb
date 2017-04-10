
module RunLoop
  # @!visibility private
  module DeviceAgent
    # @!visibility private
    #
    # A base class for something that can launch the DeviceAgent-Runner on a
    # device.
    class LauncherStrategy
      require "run_loop/abstract"
      include RunLoop::Abstract

      # @!visibility private
      attr_reader :device

      # @!visibility private
      # @param [RunLoop::Device] device where to launch the DeviceAgent-Runner
      def initialize(device)
        @device = device

        if device.version < RunLoop::Version.new("9.0")
          raise ArgumentError, %Q[
Invalid device:

#{device}

DeviceAgent is only available for iOS >= 9.0
]
        end
      end

      # @!visibility private
      # The name of this launcher. Must be a symbol (keyword).  This value will
      # be used for the key :cbx_launcher in the RunLoop::Cache so Calabash
      # iOS can attach and reattach to a DeviceAgent instance.
      def name
        abstract_method!
      end

      # @!visibility private
      #
      # Does whatever it takes to launch the DeviceAgent-Runner on the device.
      def launch(options)
        abstract_method!
      end

      # @!visibility private
      def self.dot_dir
        path = File.join(RunLoop::DotDir.directory, "DeviceAgent")
        legacy_path = File.join(RunLoop::DotDir.directory, "xcuitest")

        if File.directory?(legacy_path)
          FileUtils.cp_r(legacy_path, path)
          FileUtils.rm_rf(legacy_path)
        else
          if !File.exist?(path)
            FileUtils.mkdir_p(path)
          end
        end
        path
      end
    end
  end
end
