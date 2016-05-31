
module RunLoop
  # @!visibility private
  class CBXRunner

    require "run_loop/shell"

    # @!visibility private
    @@cbxdevice = nil

    # @!visibility private
    @@cbxsim = nil

    # @!visibility private
    def self.device_agent_dir
      @@device_agent_dir ||= File.expand_path(File.dirname(__FILE__))
    end

    # @!visibility private
    def self.detect_cbxsim
      @@cbxsim ||= lambda do
        from_env = RunLoop::Environment.cbxsim

        if from_env
          if File.exist?(from_env)
            from_env
          else
            raise RuntimeError, %Q[
CBXSIM environment variable defined:

  #{from_env}

but runner does not exist at that path.
]
          end
        else
          self.default_cbxsim
        end
      end.call
    end

    # @!visibility private
    def self.detect_cbxdevice
      @@cbxdevice ||= lambda do
        from_env = RunLoop::Environment.cbxdevice

        if from_env
          if File.exist?(from_env)
            from_env
          else
            raise RuntimeError, %Q[
CBXDEVICE environment variable defined:

  #{from_env}

but runner does not exist at that path.
]
          end
        else
          self.default_cbxdevice
        end
      end.call
    end

    # @!visibility private
    def self.default_cbxdevice
      cbx = File.join(self.device_agent_dir, "ipa", "CBX-Runner.app")

      if !File.exist?(cbx)
        self.expand_runner_archive("#{cbx}.zip")
      else
        cbx
      end
    end

    # @!visibility private
    def self.default_cbxsim
      cbx = File.join(self.device_agent_dir, "app", "CBX-Runner.app")

      if !File.exist?(cbx)
        self.expand_runner_archive("#{cbx}.zip")
      else
        cbx
      end
    end

    # @!visibility private
    def self.expand_runner_archive(archive)
      shell = Class.new do
        include RunLoop::Shell
        def to_s; "#<CBXRunner Shell>"; end
        def inspect; to_s; end
      end.new

      dir = File.dirname(archive)
      options = { :log_cmd => true }
      Dir.chdir(dir) do
        RunLoop.log_unix_cmd("cd #{dir}")
        shell.exec(["unzip", File.basename(archive)], options)
      end
      File.join(dir, "CBX-Runner.app")
    end

    # @!visibility private
    attr_reader :device

    # @!visibility private
    # @param [RunLoop::Device] device the target device
    def initialize(device)
      @device = device
    end

    # @!visibility private
    def runner
      @runner ||= lambda do
        if device.physical_device?
          RunLoop::CBXRunner.detect_cbxdevice
        else
          RunLoop::CBXRunner.detect_cbxsim
        end
      end.call
    end

    # @!visibility private
    def tester
      @tester ||= File.join(runner, "PlugIns", "CBX.xctest")
    end

    # @!visibility private
    def version
      @version ||= lambda do
        short = pbuddy.plist_read("CFBundleShortVersionString", info_plist)
        build = pbuddy.plist_read("CFBundleVersion", info_plist)
        str = "#{short}.pre#{build}"
        RunLoop::Version.new(str)
      end.call
    end

    private

    # @!visibility private
    def info_plist
      @info_plist ||= File.join(runner, "PlugIns", "CBX.xctest", "Info.plist")
    end

    # @!visibility private
    def pbuddy
      @pbuddy ||= RunLoop::PlistBuddy.new
    end
  end
end
