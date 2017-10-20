
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

      # @visibility private
      def self.terminate_simulator_tests
        should_term_test = lambda do |process_description|
          xcodebuild_destination_is_simulator?(process_description)
        end

        self.terminate_xcodebuild_test_processes(should_term_test)
      end

      # @visibility private
      def self.terminate_device_test(udid)
        should_term_test = lambda do |process_description|
          process_description[/id=#{udid}/]
        end
        self.terminate_xcodebuild_test_processes(should_term_test)
      end

      # @visibility private
      def self.terminate_xcodebuild_test_processes(should_term_test)
        options = { :timeout => 0.5, :raise_on_timeout => false }
        pids = RunLoop::ProcessWaiter.new("xcodebuild", options).pids
        pids.each do |pid|
          if should_term_test.call(process_env(pid))
            RunLoop.log_debug("Will terminate xcodebuild process: #{pid}")
            terminate_xcodebuild_test_process(pid)
          end
        end
      end

      # @visibility private
      def self.terminate_xcodebuild_test_process(pid)
        term_options = { :timeout => 1.5 }
        kill_options = { :timeout => 1.0 }

        process_name = "xcodebuild test-without-building"

        term = RunLoop::ProcessTerminator.new(pid.to_i,
                                              "TERM",
                                              process_name,
                                              term_options)
        if !term.kill_process
          kill = RunLoop::ProcessTerminator.new(pid.to_i,
                                                "KILL",
                                                process_name,
                                                kill_options)
          kill.kill_process
        end
        sleep(1.0)
      end

      # @visibility private
      def self.xcodebuild_destination_is_simulator?(process_description)
        process_description[/-destination id=#{RunLoop::Regex::CORE_SIMULATOR_UDID_REGEX}/]
      end

      # @visibility private
      def self.process_env(pid)
        options = {:log_cmd => true}
        args = ["ps", "-p", pid.to_s, "-wwwE"]
        hash = RunLoop::Shell.run_shell_command(args, options)
        hash[:out]
      end
    end
  end
end
