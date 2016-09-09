
module RunLoop
  # @!visibility private
  module DeviceAgent
    # @!visibility private
    class Frameworks

      require "singleton"
      include Singleton

      # @!visibility private
      def install
        if File.exist?(frameworks)
          return true
        end

        options = { :log_cmd => true }

        Dir.chdir(rootdir) do
          RunLoop.log_unix_cmd("cd #{rootdir}")
          shell.run_shell_command(["ditto", "-xk", File.basename(zip), "."], options)
        end
      end

      private

      # @!visibility private
      # TODO replace with include Shell
      def shell
        require "run_loop/shell"
        Class.new do
          include RunLoop::Shell
          def to_s; "#<Frameworks Shell>"; end
          def inspect; to_s; end
        end.new
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
        @rootdir ||= File.expand_path(File.join(File.dirname(__FILE__)))
      end
    end
  end
end
