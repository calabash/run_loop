module RunLoop

  # @!visibility private
  class XCUITest

    # @!visibility private
    DEFAULTS = {
      :port => 27753,
      :simulator_ip => "127.0.0.1"
    }

    # @!visibility private
    def self.project
      value = ENV["XCUITEST_PROJ"]
      if value.nil? || value == ""
        return nil
      else
        value
      end
    end

    # @!visibility private
    def self.log_file
      path = File.join(XCUITest.dot_dir, "xcuitest.log")

      if !File.exist?(path)
        FileUtils.touch(path)
      end
      path
    end

    # @!visibility private
    def initialize(bundle_id)
      @bundle_id = bundle_id
    end

    # @!visibility private
    # TODO: move to Device ?
    # TODO: needs tests for device case
    def url
      if target.simulator?
        "http://#{DEFAULTS[:simulator_ip]}:#{DEFAULTS[:port]}"
      else
        calabash_endpoint = RunLoop::Environment.device_endpoint
        if calabash_endpoint
          base = calabash_endpoint.split(":")[0..1].join(":")
          "http://#{base}:#{DEFAULTS[:port]}"
        else
          device_name = target.name.gsub(/[\'\s]/, "")
          encoding_options = {
            :invalid           => :replace,  # Replace invalid byte sequences
            :undef             => :replace,  # Replace anything not defined in ASCII
            :replace           => ''        # Use a blank for those replacements
          }
          encoded = device_name.encode(Encoding.find("ASCII"), encoding_options)
          "http://#{encoded}.local:27753"
        end
      end
    end

    # @!visibility private
    def launch_calabus_driver

      driver_url = url
      server = RunLoop::HTTP::Server.new(driver_url)
      request = RunLoop::HTTP::Request.new("/shutdown", {})
      options = {
         :timeout => 0.5,
         :retries => 1
      }
      client = RunLoop::HTTP::RetriableClient.new(server, options)

      begin
        response = client.post(request)
        RunLoop.log_debug("Calabus driver says, \"#{response.body}\"")
        sleep(2.0)
      rescue => e
        RunLoop.log_debug("Driver shutdown raised #{e}")
      end

      project = XCUITest.project

      if !project || !File.directory?(project)
        raise RuntimeError, "No project found"
      end

      destination = target.udid

      # might be nil
      if target.simulator?
        # quits the simulator
        sim = CoreSimulator.new(target, "")
        sim.launch_simulator
      else

      end

      args = [
        "xcrun",
        "xcodebuild",
        "-scheme", "CBXAppStub",
        "-workspace", project,
        "-config", "Debug",
        "-destination", "id=#{destination}",
        "clean",
        "test"
      ]

      log_file = XCUITest.log_file

      options = {
        :out => log_file,
        :err => log_file
      }

      command = args.join(" ")
      RunLoop.log_unix_cmd("#{command} >& #{log_file}")

      pid = Process.spawn(*args, options)
      Process.detach(pid)

      if target.simulator?
        target.simulator_wait_for_stable_state
      end

      RunLoop.log_debug("Waiting for project to build...")

      server = RunLoop::HTTP::Server.new(driver_url)
      request = RunLoop::HTTP::Request.new("/health", {})

      options = {
        :timeout => 60,
        :interval => 0.1,
        :retries => 600
      }

      client = RunLoop::HTTP::RetriableClient.new(server, options)
      response = client.get(request)

      RunLoop.log_debug("Calabus driver says, \"#{response.body}\"")
      pid.to_i
    end

    def launch_app
      server = RunLoop::HTTP::Server.new(url)
      request = RunLoop::HTTP::Request.request("/session", {:bundleID => bundle_id})
      client = RunLoop::HTTP::RetriableClient.new(server)
      response = client.post(request)

      RunLoop.log_debug("Calabus driver says, \"#{response.body}\"")
    end

    # @!visibility private
    def target
      @device ||= lambda do
        target = RunLoop::Environment.device_target

        if !target
          target = RunLoop::Core.default_simulator
        end

        options = {
          :sim_control => simctl,
          :instruments => instruments
        }

        device = RunLoop::Device.device_with_identifier(target, options)

        if !device
          raise RuntimeError, "Could not find a device"
        end

        device
      end.call
    end

    # @!visibility private
    def bundle_id
      @bundle_id
    end

    private

    # @!visibility private
    def simctl
      @simctl ||= RunLoop::SimControl.new
    end

    # @!visibility private
    def instruments
      @instruments ||= RunLoop::Instruments.new
    end

    # @!visibility private
    def xcrun
      RunLoop::Xcrun.new
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

