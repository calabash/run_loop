module RunLoop

  # @!visibility private
  class XCUITest

    class HTTPError < RuntimeError; end

    # @!visibility private
    DEFAULTS = {
      :port => 27753,
      :simulator_ip => "127.0.0.1",
      :http_timeout => RunLoop::Environment.ci? ? 120 : 60,
      :version => "1.0"
    }

    # @!visibility private
    def self.run(options={})
      # logger = options[:logger]
      simctl = options[:sim_control] || options[:simctl] || RunLoop::Simctl.new
      xcode = options[:xcode] || RunLoop::Xcode.new
      instruments = options[:instruments] || RunLoop::Instruments.new

      # Find the Device under test, the App under test, UIA strategy, and reset options
      device = RunLoop::Device.detect_device(options, xcode, simctl, instruments)
      app_details = RunLoop::DetectAUT.detect_app_under_test(options)
      reset_options = RunLoop::Core.send(:detect_reset_options, options)

      app = app_details[:app]
      bundle_id = app_details[:bundle_id]

      if device.simulator? && app
        core_sim = RunLoop::CoreSimulator.new(device, app, :xcode => xcode)
        if reset_options
          core_sim.reset_app_sandbox
        end

        simctl.ensure_software_keyboard(device)
        core_sim.install
      end

      xcuitest = RunLoop::XCUITest.new(bundle_id, device)
      xcuitest.launch
      xcuitest
    end

    # @!visibility private
    def self.xcodebuild_log_file
      path = File.join(XCUITest.dot_dir, "xcodebuild.log")
      FileUtils.touch(path) if !File.exist?(path)
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

    def to_s
      "#<XCUITest #{url} : #{bundle_id} : #{device}>"
    end

    def inspect
      to_s
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

    # @!visibility private
    def query(mark)
      options = http_options
      parameters = { :text => mark }
      request = request("query", parameters)
      client = client(options)
      response = client.post(request)
      expect_200_response(response)
    end

    # @!visibility private
    def tap_mark(mark)
      options = http_options
      parameters = {
        :gesture => "tap",
        :text => mark
      }
      request = request("gesture", parameters)
      client(options)
      response = client.post(request)
      expect_200_response(response)
    end

    # @!visibility private
    def tap_coordinate(x, y)
      options = http_options
      parameters = {
        :gesture => "tap_coordinate",
        :coordinate => {x: x, y: y}
      }
      request = request("gesture", parameters)
      client(options)
      response = client.post(request)
      expect_200_response(response)
    end

    # @!visibility private
    def tap_query_result(hash)
      rect = hash["rect"]
      h = rect["height"]
      w = rect["width"]
      x = rect["x"]
      y = rect["y"]

      touchx = x + (h/2)
      touchy = y + (w/2)
      tap_coordinate(touchx, touchy)
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
    def versioned_route(route)
      if ["health", "ping", "sessionIdentifier"].include?(route)
        route
      else
        "#{DEFAULTS[:version]}/#{route}"
      end
    end

    # @!visibility private
    def request(route, parameters={})
      versioned = versioned_route(route)
      RunLoop::HTTP::Request.request(versioned, parameters)
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
    def session_delete
      options = ping_options
      request = request("delete")
      client = client(options)
      begin
        response = client.delete(request)
        body = expect_200_response(response)
        RunLoop.log_debug("CBX-Runner says, #{body}")
        body
      rescue => e
        RunLoop.log_debug("CBX-Runner session delete error: #{e}")
        nil
      end
    end

    # @!visibility private
    # TODO expect 200 response and parse body (atm the body in not valid JSON)
    def shutdown
      session_delete
      options = ping_options
      request = request("shutdown")
      client = client(options)
      begin
        response = client.post(request)
        body = response.body
        RunLoop.log_debug("CBX-Runner says, \"#{body}\"")
        5.times do
          begin
            health
            sleep(0.2)
          rescue => _
            break
          end
        end
        body
      rescue => e
        RunLoop.log_debug("CBX-Runner shutdown error: #{e}")
        nil
      end
    end

    # @!visibility private
    # TODO expect 200 response and parse body (atm the body is not valid JSON)
    def health(options={})
      merged_options = http_options.merge(options)
      request = request("health")
      client = client(merged_options)
      response = client.get(request)
      body = response.body
      RunLoop.log_debug("CBX-Runner driver says, \"#{body}\"")
      body
    end

    # @!visibility private
    def xcodebuild
      env = {
        "COMMAND_LINE_BUILD" => "1"
      }

      args = [
        "xcrun",
        "xcodebuild",
        "-scheme", "CBXAppStub",
        "-workspace", workspace,
        "-config", "Debug",
        "-destination",
        "id=#{device.udid}",
        "clean",
        "test"
      ]

      log_file = XCUITest.xcodebuild_log_file

      options = {
        :out => log_file,
        :err => log_file
      }

      command = "#{env.map.each { |k, v| "#{k}=#{v}" }.join(" ")} #{args.join(" ")}"
      RunLoop.log_unix_cmd("#{command} >& #{log_file}")

      pid = Process.spawn(env, *args, options)
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

      start = Time.now
      pid = xcodebuild
      RunLoop.log_debug("Waiting for CBX-Runner to build...")
      health

      RunLoop.log_debug("Took #{Time.now - start} seconds to build and launch")
      pid.to_i
    end

    # @!visibility private
    def launch_aut(bundle_id = @bundle_id)
      client = client(http_options)
      request = request("session", {:bundleID => bundle_id})

      begin
        response = client.post(request)
        RunLoop.log_debug("Launched #{bundle_id} on #{device}")
        RunLoop.log_debug("#{response.body}")
        if device.simulator?
          device.simulator_wait_for_stable_state
        end
        expect_200_response(response)
      rescue => e
        raise e.class, %Q[Could not launch #{bundle_id} on #{device}:

#{e.message}

Something went wrong.
]
      end
    end

    # @!visibility private
    def response_body_to_hash(response)
      body = response.body
      begin
        JSON.parse(body)
      rescue TypeError, JSON::ParserError => _
        raise RunLoop::XCUITest::HTTPError,
              "Could not parse response '#{body}'; the app has probably crashed"
      end
    end

    # @!visibility private
    def expect_200_response(response)
      body = response_body_to_hash(response)
      return body if response.status_code < 300

      raise RunLoop::XCUITest::HTTPError,
        %Q[Expected status code < 200, found #{response.status_code}.

Server replied with:

#{body}
]
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

