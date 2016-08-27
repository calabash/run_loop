
module RunLoop

  # @!visibility private
  module DeviceAgent

    # @!visibility private
    class Xcodebuild < RunLoop::DeviceAgent::LauncherStrategy

      # @!visibility private
      def self.log_file
        path = File.join(Xcodebuild.dot_dir, "xcodebuild.log")
        FileUtils.touch(path) if !File.exist?(path)
        path
      end

      # @!visibility private
      def to_s
        "#<Xcodebuild #{workspace}>"
      end

      # @!visibility private
      def inspect
        to_s
      end

      # @!visibility private
      def name
        :xcodebuild
      end

      # @!visibility private
      def launch(_)
        workspace

        if device.simulator?
          # quits the simulator
          sim = CoreSimulator.new(device, "")
          sim.launch_simulator
        end

        start = Time.now
        RunLoop.log_debug("Waiting for CBX-Runner to build...")
        pid = xcodebuild
        RunLoop.log_debug("Took #{Time.now - start} seconds to build and launch CBX-Runner")
        pid
      end

      # @!visibility private
      def workspace
        @workspace ||= begin
          path = RunLoop::Environment.send(:cbxws) || default_workspace

          if File.exist?(path)
            path
          else
            raise(RuntimeError, %Q[
Cannot find the DeviceAgent.xcworkspace.

Expected it here:

  #{path}

Use the CBXWS environment variable to override the default.

])

          end
        end
      end

      # @!visibility private
      def xcodebuild
        env = {
          "COMMAND_LINE_BUILD" => "1",
          "CLOBBER" => "1"
        }

        args = [
          "xcrun",
          "xcodebuild",
          "-scheme", "AppStub",
          "-workspace", workspace,
          "-config", "Debug",
          "-destination",
          "id=#{device.udid}",
          "CLANG_ENABLE_CODE_COVERAGE=YES",
          "GCC_GENERATE_TEST_COVERAGE_FILES=NO",
          "GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=NO",
          # Scheme setting.
          "-enableCodeCoverage", "YES",
          "test"
        ]

        log_file = Xcodebuild.log_file

        options = {
          :out => log_file,
          :err => log_file
        }

        command = "#{env.map.each { |k, v| "#{k}=#{v}" }.join(" ")} #{args.join(" ")}"
        RunLoop.log_unix_cmd("#{command} >& #{log_file}")

        pid = Process.spawn(env, *args, options)
        Process.detach(pid)
        pid.to_i
      end

      def default_workspace
        this_dir = File.expand_path(File.dirname(__FILE__))
        relative = File.expand_path(File.join(this_dir, "..", "..", "..", ".."))
        File.join(relative, "DeviceAgent.iOS/DeviceAgent.xcworkspace")
      end
    end
  end
end

