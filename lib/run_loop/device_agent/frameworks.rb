
module RunLoop
  # @!visibility private
  module DeviceAgent
    # @!visibility private
    class Frameworks
      require "run_loop/shell"
      require "singleton"
      include Singleton

      # @!visibility private
      def install
        if File.exist?(frameworks)
          RunLoop.log_debug("#{frameworks} already exists; skipping install")
          return true
        end

        RunLoop.log_debug("Installing Frameworks to #{target}")

        options = { :log_cmd => true }

        Dir.chdir(rootdir) do
          RunLoop.log_unix_cmd("cd #{rootdir}")
          shell.exec(["unzip", File.basename(zip)], options)
        end

        shell.exec(["cp", "-r", "#{frameworks}/*.framework", target], options)
        shell.exec(["cp", "#{frameworks}/*LICENSE", target], options)
        RunLoop.log_debug("Installed frameworks to #{target}")
      end

      private

      # @!visibility private
      def shell
        Class.new do
          include RunLoop::Shell
          def to_s; "#<Frameworks Shell>"; end
          def inspect; to_s; end
        end.new
      end

      # @!visibility private
      def target
        @target ||= File.join(RunLoop::DotDir.directory, "Frameworks")
      end

      # @!visibility private
      def frameworks
        @frameworks ||= File.join(rootdir, "Frameworks")
      end

      # @!visibility private
      def zip
        @zip ||= File.join(rootdir, "Frameworks.zip")
      end

      # @!visibility private
      def rootdir
        @rootdir ||= File.expand_path(File.join(File.dirname(__FILE__), "frameworks"))
      end
    end
  end
end
