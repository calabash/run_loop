
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
      def self.derived_data_directory
        path = File.join(Xcodebuild.dot_dir, "DerivedData")
        FileUtils.mkdir_p(path) if !File.exist?(path)
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
          # sim = CoreSimulator.new(device, "")
          # sim.launch_simulator({:wait_for_stable => false})
        end

        xcodebuild
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
          "-derivedDataPath", Xcodebuild.derived_data_directory,
          "-scheme", "AppStub",
          "-workspace", workspace,
          "-config", "Debug",
          "-destination",
          "id=#{device.udid}",
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

        sleep_for = 15
        RunLoop.log_debug("Waiting #{sleep_for} seconds for DeviceAgent to build...")
        sleep(sleep_for)

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

