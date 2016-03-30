module RunLoop

  # @!visibility private
  class XCUITest

    # @!visibility private
    DEFAULTS = {
      :port => 27753,
      :simulator_ip => "127.0.0.1",
      :http_timeout => RunLoop::Environment.ci? ? 120 : 60
    }


    # @!visibility private
    def self.log_file
      path = File.join(XCUITest.dot_dir, "xcuitest.log")

      if !File.exist?(path)
        FileUtils.touch(path)
      end
      path
    end

    # @!visibility private
    #
    # The app with `bundle_id` needs to be installed.
    #
    # @param [String] bundle_id The identifier of the app under test.
    # @param [RunLoop::Device] device The device device.
    def initialize(bundle_id, device)
      @bundle_id = bundle_id
      @device = device
    end

    # @!visibility private
    def bundle_id
      @bundle_id
    end

    # @!visibility private
    def device
      @device
    end

    # @!visibility private
    def workspace
      @workspace ||= lambda do
        path = RunLoop::Environment.send(:cbxws)
        if path
          path
        else
          raise "TODO: figure out how to distribute the CBX-Runner"
        end
      end.call
    end

    def launch
      start = Time.now
      launch_cbx_runner
      launch_aut
      elapsed = Time.now - start
      RunLoop.log_debug("Took #{elapsed} seconds to launch #{bundle_id} on #{device}")
      true
    end

    # @!visibility private
    def running?
      begin
        health(ping_options)
      rescue => _
        nil
      end
    end

    # @!visibility private
    def stop
      begin
        shutdown
      rescue => _
        nil
      end
    end

    # @!visibility private
    def launch_other_app(bundle_id)
      launch_aut(bundle_id)
    end

    private

    # @!visibility private
    def xcrun
      RunLoop::Xcrun.new
    end

    # @!visibility private
    def url
      @url ||= lambda do
        if device.simulator?
          "http://#{DEFAULTS[:simulator_ip]}:#{DEFAULTS[:port]}/"
        else
          # This block is untested.
          calabash_endpoint = RunLoop::Environment.device_endpoint
          if calabash_endpoint
            base = calabash_endpoint.split(":")[0..1].join(":")
            "http://#{base}:#{DEFAULTS[:port]}/"
          else
            device_name = device.name.gsub(/['\s]/, "")
            encoding_options = {
              :invalid           => :replace,  # Replace invalid byte sequences
              :undef             => :replace,  # Replace anything not defined in ASCII
              :replace           => ""         # Use a blank for those replacements
            }
            encoded = device_name.encode(Encoding.find("ASCII"), encoding_options)
            "http://#{encoded}.local:27753/"
          end
        end
      end.call
    end

    # @!visibility private
    def server
      @server ||= RunLoop::HTTP::Server.new(url)
    end

    # @!visibility private
    def client(options={})
      RunLoop::HTTP::RetriableClient.new(server, options)
    end

    # @!visibility private
    def request(route, parameters={})
      RunLoop::HTTP::Request.request(route, parameters)
    end

    # @!visibility private
    def ping_options
      @ping_options ||= { :timeout => 0.5, :retries => 1 }
    end

    # @!visibility private
    def http_options
      {
        :timeout => DEFAULTS[:http_timeout],
        :interval => 0.1,
        :retries => (DEFAULTS[:http_timeout]/0.1).to_i
      }
    end

    # @!visibility private
    def shutdown
      options = ping_options
      request = request("shutdown")
      client = client(options)
      begin
        response = client.post(request)
        RunLoop.log_debug("CBX-Runner says, \"#{response.body}\"")
        response.body
      rescue => e
        RunLoop.log_debug("CBX-Runner shutdown error: #{e}")
        nil
      end
    end

    # @!visibility private
    def health(options={})
      merged_options = http_options.merge(options)
      request = request("health")
      client = client(merged_options)
      response = client.get(request)
      RunLoop.log_debug("CBX-Runner driver says, \"#{response.body}\"")
      response.body
    end

    # @!visibility private
    def xcodebuild
      args = [
        "xcrun",
        "xcodebuild",
        "-scheme", "CBXAppStub",
        "-workspace", workspace,
        "-config", "Debug",
        "-destination", "id=#{device.udid}",
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
      pid
    end

    # @!visibility private
    def launch_cbx_runner
      # Fail fast if CBXWS is not defined.
      # WIP - we will distribute the workspace somehow.
      workspace

      shutdown

      if device.simulator?
        # quits the simulator
        sim = CoreSimulator.new(device, "")
        sim.launch_simulator
      else
        # anything special about physical devices?
      end

      pid = xcodebuild
      RunLoop.log_debug("Waiting for CBX-Runner to build...")
      health
      pid.to_i
    end

    # @!visibility private
    def launch_aut(bundle_id=bundle_id)
      client = client(http_options)
      request = request("session", {:bundleID => bundle_id})

      begin
        response = client.post(request)
        RunLoop.log_debug("Launched #{bundle_id} on #{device}")
        RunLoop.log_debug("#{response.body}")
        if device.simulator?
          device.simulator_wait_for_stable_state
        end
        response.body
      rescue => e
        raise e.class, %Q[Could not launch #{bundle_id} on #{device}:

#{e.message}

Something went wrong.
]
      end
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

