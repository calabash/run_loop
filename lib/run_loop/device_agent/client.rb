module RunLoop

  # @!visibility private
  module DeviceAgent

    # @!visibility private
    class Client

      require "run_loop/shell"
      include RunLoop::Shell

      require "run_loop/encoding"
      include RunLoop::Encoding

      require "run_loop/cache"

      class HTTPError < RuntimeError; end

      # @!visibility private
      #
      # These defaults may change at any time.
      DEFAULTS = {
        :port => 27753,
        :simulator_ip => "127.0.0.1",
        :http_timeout => RunLoop::Environment.ci? ? 120 : 10,
        :route_version => "1.0",
        :shutdown_device_agent_before_launch => false
      }

      # @!visibility private
      #
      # These defaults may change at any time.
      WAIT_DEFAULTS = {
        timeout: RunLoop::Environment.ci? ? 16 : 8,
        retry_frequency: 0.1,
        exception_class: Timeout::Error
      }

      # @!visibility private
      def self.run(options={})
        # logger = options[:logger]
        simctl = options[:sim_control] || options[:simctl] || RunLoop::Simctl.new
        xcode = options[:xcode] || RunLoop::Xcode.new
        instruments = options[:instruments] || RunLoop::Instruments.new

        # Find the Device under test, the App under test, and reset options.
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

        cbx_launcher = Client.detect_cbx_launcher(options, device)

        code_sign_identity = options[:code_sign_identity]
        if !code_sign_identity
          code_sign_identity = RunLoop::Environment::code_sign_identity
        end

        if device.physical_device? && cbx_launcher.name == :ios_device_manager
          if !code_sign_identity
            raise RuntimeError, %Q[
Targeting a physical devices requires a code signing identity.

Rerun your test with:

$ CODE_SIGN_IDENTITY="iPhone Developer: Your Name (ABCDEF1234)" cucumber

To see the valid code signing identities on your device run:

$ xcrun security find-identity -v -p codesigning

]
          end
        end

        launch_options = options.merge({:code_sign_identity => code_sign_identity})
        xcuitest = RunLoop::DeviceAgent::Client.new(bundle_id, device, cbx_launcher)
        xcuitest.launch(launch_options)

        if !RunLoop::Environment.xtc?
          cache = {
            :cbx_launcher => cbx_launcher.name,
            :udid => device.udid,
            :app => bundle_id,
            :automator => :device_agent,
            :code_sign_identity => code_sign_identity
          }
          RunLoop::Cache.default.write(cache)
        end
        xcuitest
      end

      # @!visibility private
      #
      # @param [RunLoop::Device] device the device under test
      def self.default_cbx_launcher(device)
        RunLoop::DeviceAgent::IOSDeviceManager.new(device)
      end

      # @!visibility private
      # @param [Hash] options the options passed by the user
      # @param [RunLoop::Device] device the device under test
      def self.detect_cbx_launcher(options, device)
        value = options[:cbx_launcher]
        if value
          if value == :xcodebuild
            RunLoop::DeviceAgent::Xcodebuild.new(device)
          elsif value == :ios_device_manager
            RunLoop::DeviceAgent::IOSDeviceManager.new(device)
          else
            raise(ArgumentError,
                  "Expected :cbx_launcher => #{value} to be :xcodebuild or :ios_device_manager")
          end
        else
          Client.default_cbx_launcher(device)
        end
      end

      attr_reader :bundle_id, :device, :cbx_launcher, :launch_options

      # @!visibility private
      #
      # The app with `bundle_id` needs to be installed.
      #
      # @param [String] bundle_id The identifier of the app under test.
      # @param [RunLoop::Device] device The device under test.
      # @param [RunLoop::DeviceAgent::LauncherStrategy] cbx_launcher The entity that
      #  launches the CBXRunner.
      def initialize(bundle_id, device, cbx_launcher)
        @bundle_id = bundle_id
        @device = device
        @cbx_launcher = cbx_launcher
      end

      # @!visibility private
      def to_s
        "#<DeviceAgent #{url} : #{bundle_id} : #{device} : #{cbx_launcher}>"
      end

      # @!visibility private
      def inspect
        to_s
      end

      # @!visibility private
      def launch(options={})
        @launch_options = options
        start = Time.now
        launch_cbx_runner(options)
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
      def device_info
        options = http_options
        request = request("device")
        client = client(options)
        response = client.get(request)
        expect_300_response(response)
      end

      # TODO Legacy API; remove once this branch is merged:
      # https://github.com/calabash/DeviceAgent.iOS/pull/133
      alias_method :runtime, :device_info

      # @!visibility private
      def server_pid
        options = http_options
        request = request("pid")
        client = client(options)
        response = client.get(request)
        expect_300_response(response)
      end

      # @!visibility private
      def server_version
        options = http_options
        request = request("version")
        client = client(options)
        response = client.get(request)
        expect_300_response(response)
      end

      # @!visibility private
      def session_identifier
        options = http_options
        request = request("sessionIdentifier")
        client = client(options)
        response = client.get(request)
        expect_300_response(response)
      end

      # @!visibility private
      def tree
        options = http_options
        request = request("tree")
        client = client(options)
        response = client.get(request)
        expect_300_response(response)
      end

      # @!visibility private
      def keyboard_visible?
        options = http_options
        parameters = { :type => "Keyboard" }
        request = request("query", parameters)
        client = client(options)
        response = client.post(request)
        hash = expect_300_response(response)
        result = hash["result"]
        result.count != 0
      end

      # @!visibility private
      def enter_text(string)
        if !keyboard_visible?
          raise RuntimeError, "Keyboard must be visible"
        end
        options = http_options
        parameters = {
          :gesture => "enter_text",
          :options => {
            :string => string
          }
        }
        request = request("gesture", parameters)
        client = client(options)
        response = client.post(request)
        expect_300_response(response)
      end

      # @!visibility private
      #
      # @example
      #  query({id: "login", :type "Button"})
      #
      #  query({marked: "login"})
      #
      #  query({marked: "login", type: "TextField"})
      #
      #  query({type: "Button", index: 2})
      #
      #  query({text: "Log in"})
      #
      #  query({id: "hidden button", :all => true})
      #
      #  # Escaping single quote is not necessary, but supported.
      #  query({text: "Karl's problem"})
      #  query({text: "Karl\'s problem"})
      #
      #  # Escaping double quote is not necessary, but supported.
      #  query({text: "\"To know is not enough.\""})
      #  query({text: %Q["To know is not enough."]})
      #
      # Querying for text with newlines is not supported yet.
      #
      # The query language supports the following keys:
      # * :marked - accessibilityIdentifier, accessibilityLabel, text, and value
      # * :id - accessibilityIdentifier
      # * :type - an XCUIElementType shorthand, e.g. XCUIElementTypeButton =>
      #   Button. See the link below for available types.  Note, however that
      #   some XCUIElementTypes are not available on iOS.
      # * :index - Applied after all other specifiers.
      # * :all - Filter the result by visibility. Defaults to false. See the
      #   discussion below about visibility.
      #
      # ### Visibility
      #
      # The rules for visibility are:
      #
      # 1. If any part of the view is visible, the visible.
      # 2. If the view has alpha 0, it is not visible.
      # 3. If the view has a size (0,0) it is not visible.
      # 4. If the view is not within the bounds of the screen, it is not visible.
      #
      # Visibility is determined using the "hitable" XCUIElement property.
      # XCUITest, particularly under Xcode 7, is not consistent about setting
      # the "hitable" property correctly.  Views that are not "hitable" might
      # respond to gestures.
      #
      # Regarding rule #1 - this is different from the Calabash iOS and Android
      # definition of visibility which requires the mid-point of the view to be
      # visible.
      #
      # ### Results
      #
      # Results are returned as an Array of Hashes.
      #
      # ```
      # [
      #  {
      #    "enabled": true,
      #    "id": "mostly hidden button",
      #    "hitable": true,
      #    "rect": {
      #      "y": 459,
      #      "x": 24,
      #      "height": 25,
      #      "width": 100
      #    },
      #    "label": "Mostly Hidden",
      #    "type": "Button",
      #    "hit_point": {
      #      "x": 25,
      #      "y": 460
      #    },
      #    "test_id": 1
      #  }
      # ]
      # ```
      #
      # @see http://masilotti.com/xctest-documentation/Constants/XCUIElementType.html
      # @param [Hash] uiquery A hash describing the query.
      # @return [Array<Hash>] An array of elements matching the `uiquery`.
      def query(uiquery)
        merged_options = {
          all: false
        }.merge(uiquery)

        allowed_keys = [:all, :id, :index, :marked, :text, :type]
        unknown_keys = uiquery.keys - allowed_keys
        if !unknown_keys.empty?
          keys = allowed_keys.map { |key| ":#{key}" }.join(", ")
          raise ArgumentError, %Q[
Unsupported key or keys found: '#{unknown_keys}'.

Allowed keys for a query are: #{keys}

          ]
        end

        has_any_key = (allowed_keys & uiquery.keys).any?
        if !has_any_key
          keys = allowed_keys.map { |key| ":#{key}" }.join(", ")
          raise ArgumentError, %Q[
Query does not contain any keysUnsupported key or keys found: '#{unknown_keys}'.

Allowed keys for a query are: #{keys}

]
        end

        parameters = merged_options.dup.tap { |hs| hs.delete(:all) }
        if parameters.empty?
          keys = allowed_keys.map { |key| ":#{key}" }.join(", ")
          raise ArgumentError, %Q[
Query must contain at least one of these keys:

#{keys}

]
        end

        request = request("query", parameters)
        client = client(http_options)

        RunLoop.log_debug %Q[Sending query with parameters:

#{JSON.pretty_generate(parameters)}

]

        response = client.post(request)
        hash = expect_300_response(response)
        elements = hash["result"]

        if merged_options[:all]
          elements
        else
          elements.select do |element|
            element["hitable"]
          end
        end
      end

      # @!visibility private
      def alert_visible?
        parameters = { :type => "Alert" }
        request = request("query", parameters)
        client = client(http_options)
        response = client.post(request)
        hash = expect_300_response(response)
        !hash["result"].empty?
      end

      # @!visibility private
      def query_for_coordinate(mark)
        elements = query(mark)
        coordinate_from_query_result(elements)
      end

      # @!visibility private
      def touch(mark, options={})
        coordinate = query_for_coordinate(mark)
        perform_coordinate_gesture("touch",
                                   coordinate[:x], coordinate[:y],
                                   options)
      end

      alias_method :tap, :touch

      # @!visibility private
      def double_tap(mark, options={})
        coordinate = query_for_coordinate(mark)
        perform_coordinate_gesture("double_tap",
                                   coordinate[:x], coordinate[:y],
                                   options)
      end

      # @!visibility private
      def two_finger_tap(mark, options={})
        coordinate = query_for_coordinate(mark)
        perform_coordinate_gesture("two_finger_tap",
                                   coordinate[:x], coordinate[:y],
                                   options)
      end

      # @!visibility private
      def rotate_home_button_to(position, sleep_for=1.0)
        orientation = normalize_orientation_position(position)
        parameters = {
          :orientation => orientation
        }
        request = request("rotate_home_button_to", parameters)
        client = client(http_options)
        response = client.post(request)
        json = expect_300_response(response)
        sleep(sleep_for)
        json
      end

      # @!visibility private
      def pan_between_coordinates(start_point, end_point, options={})
        default_options = {
          :num_fingers => 1,
          :duration => 0.5
        }

        merged_options = default_options.merge(options)

        parameters = {
          :gesture => "drag",
          :specifiers => {
            :coordinates => [start_point, end_point]
          },
          :options => merged_options
        }

        make_gesture_request(parameters)
      end

      # @!visibility private
      def perform_coordinate_gesture(gesture, x, y, options={})
        parameters = {
          :gesture => gesture,
          :specifiers => {
            :coordinate => {x: x, y: y}
          },
          :options => options
        }

        make_gesture_request(parameters)
      end

      # @!visibility private
      def make_gesture_request(parameters)

        RunLoop.log_debug %Q[Sending request to perform '#{parameters[:gesture]}' with:

#{JSON.pretty_generate(parameters)}

]
        request = request("gesture", parameters)
        client = client(http_options)
        response = client.post(request)
        expect_300_response(response)
      end

      # @!visibility private
      def coordinate_from_query_result(matches)

        if matches.nil? || matches.empty?
          raise "Expected #{hash} to contain some results"
        end

        rect = matches.first["rect"]
        h = rect["height"]
        w = rect["width"]
        x = rect["x"]
        y = rect["y"]

        touchx = x + (w/2.0)
        touchy = y + (h/2.0)

        new_rect = rect.dup
        new_rect[:center_x] = touchx
        new_rect[:center_y] = touchy

        RunLoop.log_debug(%Q[Rect from query:

#{JSON.pretty_generate(new_rect)}

                          ])
        {:x => touchx,
         :y => touchy}
      end


      # @!visibility private
      def change_volume(up_or_down)
        string = up_or_down.to_s
        parameters = {
          :volume => string
        }
        request = request("volume", parameters)
        client = client(http_options)
        response = client.post(request)
        json = expect_300_response(response)
        # Set in the route
        sleep(0.2)
        json
      end

      # TODO: animation model
      def wait_for_animations
        sleep(0.5)
      end

      # @!visibility private
      def wait_for(timeout_message, options={}, &block)
        wait_options = WAIT_DEFAULTS.merge(options)
        timeout = wait_options[:timeout]
        exception_class = wait_options[:exception_class]
        with_timeout(timeout, timeout_message, exception_class) do
          loop do
            value = block.call
            return value if value
            sleep(wait_options[:retry_frequency])
          end
        end
      end

      # @!visibility private
      def wait_for_keyboard(timeout=WAIT_DEFAULTS[:timeout])
        options = WAIT_DEFAULTS.dup
        options[:timeout] = timeout
        message = %Q[

Timed out after #{timeout} seconds waiting for the keyboard to appear.

]
        wait_for(message, options) do
          keyboard_visible?
        end
      end

      # @!visibility private
      def wait_for_alert(timeout=WAIT_DEFAULTS[:timeout])
        options = WAIT_DEFAULTS.dup
        options[:timeout] = timeout
        message = %Q[

Timed out after #{timeout} seconds waiting for an alert to appear.

]
        wait_for(message, options) do
          alert_visible?
        end
      end

      # @!visibility private
      def wait_for_no_alert(timeout=WAIT_DEFAULTS[:timeout])
        options = WAIT_DEFAULTS.dup
        options[:timeout] = timeout
        message = %Q[

Timed out after #{timeout} seconds waiting for an alert to disappear.

]

        wait_for(message, options) do
          !alert_visible?
        end
      end

      # @!visibility private
      def wait_for_text_in_view(text, uiquery, options={})
        merged_options = WAIT_DEFAULTS.merge(options)
        result = wait_for_view(uiquery, merged_options)

        candidates = [result["value"],
                      result["label"]]
        match = candidates.any? do |elm|
          elm == text
        end
        if !match
          fail(%Q[

Expected to find '#{text}' as a 'value' or 'label' in

#{JSON.pretty_generate(result)}

])
        end
      end

      # @!visibility private
      def wait_for_view(uiquery, options={})
        merged_options = WAIT_DEFAULTS.merge(options)

        unless merged_options[:message]
          message = %Q[

Waited #{merged_options[:timeout]} seconds for

#{uiquery}

to match a view.

]
          merged_options[:timeout_message] = message
        end

        result = nil
        wait_for(merged_options[:timeout_message], options) do
          result = query(uiquery)
          !result.empty?
        end

        result[0]
      end

      # @!visibility private
      def wait_for_no_view(uiquery, options={})
        merged_options = WAIT_DEFAULTS.merge(options)
        unless merged_options[:message]
          message = %Q[

Waited #{merged_options[:timeout]} seconds for

#{uiquery}

to match no views.

]
          merged_options[:timeout_message] = message
        end

        result = nil
        wait_for(merged_options[:timeout_message], options) do
          result = query(uiquery)
          result.empty?
        end

        result[0]
      end

      # @!visibility private
      class PrivateWaitTimeoutError < RuntimeError ; end

      # @!visibility private
      def with_timeout(timeout, timeout_message,
                       exception_class=WAIT_DEFAULTS[:exception_class], &block)
        if timeout_message.nil? ||
          (timeout_message.is_a?(String) && timeout_message.empty?)
          raise ArgumentError, 'You must provide a timeout message'
        end

        unless block_given?
          raise ArgumentError, 'You must provide a block'
        end

        # Timeout.timeout will never timeout if the given `timeout` is zero.
        # We will raise an exception if the timeout is zero.
        # Timeout.timeout already raises an exception if `timeout` is negative.
        if timeout == 0
          raise ArgumentError, 'Timeout cannot be 0'
        end

        message = if timeout_message.is_a?(Proc)
          timeout_message.call({timeout: timeout})
        else
          timeout_message
        end

        failed = false

        begin
          Timeout.timeout(timeout, PrivateWaitTimeoutError) do
            return block.call
          end
        rescue PrivateWaitTimeoutError => _
          # If we raise Timeout here the stack trace will be cluttered and we
          # wish to show the user a clear message, avoiding
          # "`rescue in with_timeout':" in the stack trace.
          failed = true
        end

        if failed
          fail(exception_class, message)
        end
      end

      # @!visibility private
      def fail(*several_variants)
        arg0 = several_variants[0]
        arg1 = several_variants[1]

        if arg1.nil?
          exception_type = RuntimeError
          message = arg0
        else
          exception_type = arg0
          message = arg1
        end

        raise exception_type, message
      end

      private

      # @!visibility private
      def xcrun
        RunLoop::Xcrun.new
      end

      # @!visibility private
      def url
        @url ||= detect_device_agent_url
      end

      # @!visibility private
      def detect_device_agent_url
        url_from_environment ||
          url_for_simulator ||
          url_from_device_endpoint ||
          url_from_device_name
      end

      # @!visibility private
      def url_from_environment
        url = RunLoop::Environment.device_agent_url
        return if url.nil?

        if url.end_with?("/")
          url
        else
          "#{url}/"
        end
      end

      # @!visibility private
      def url_for_simulator
        if device.simulator?
          "http://#{DEFAULTS[:simulator_ip]}:#{DEFAULTS[:port]}/"
        else
          nil
        end
      end

      # @!visibility private
      def url_from_device_endpoint
        calabash_endpoint = RunLoop::Environment.device_endpoint
        if calabash_endpoint
          base = calabash_endpoint.split(":")[0..1].join(":")
          "#{base}:#{DEFAULTS[:port]}/"
        else
          nil
        end
      end

      # @!visibility private
      # TODO This block is not well tested
      # TODO extract to a module; Calabash can use to detect device endpoint
      def url_from_device_name
        # Transforms the default "Joshua's iPhone" to a DNS name.
        device_name = device.name.gsub(/[']/, "").gsub(/[\s]/, "-")

        # Replace diacritic markers and unknown characters.
        transliterated = transliterate(device_name).tr("?", "")

        # Anything that cannot be transliterated is a ?
        replaced = transliterated.tr("?", "")

        "http://#{replaced}.local:#{DEFAULTS[:port]}/"
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
        "#{DEFAULTS[:route_version]}/#{route}"
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
        if cbx_launcher.name == :xcodebuild
          timeout = DEFAULTS[:http_timeout] * 2
          {
            :timeout => timeout,
            :interval => 0.1,
            :retries => (timeout/0.1).to_i
          }
        else
          {
            :timeout => DEFAULTS[:http_timeout],
            :interval => 0.1,
            :retries => (DEFAULTS[:http_timeout]/0.1).to_i
          }
        end
      end

      # @!visibility private
      def session_delete
        # https://xamarin.atlassian.net/browse/TCFW-255
        # httpclient is unable to send a valid DELETE
        args = ["curl", "-X", "DELETE", %Q[#{url}#{versioned_route("session")}]]
        run_shell_command(args, {:log_cmd => true})

        # options = ping_options
        # request = request("session")
        # client = client(options)
        # begin
        #   response = client.delete(request)
        #   body = expect_200_response(response)
        #   RunLoop.log_debug("CBX-Runner says, #{body}")
        #   body
        # rescue => e
        #   RunLoop.log_debug("CBX-Runner session delete error: #{e}")
        #   nil
        # end
      end

      # @!visibility private
      # TODO expect 200 response and parse body (atm the body in not valid JSON)
      def shutdown
        session_delete
        options = ping_options
        request = request("shutdown")
        client = client(options)
        body = nil
        begin
          response = client.post(request)
          body = response.body
          RunLoop.log_debug("DeviceAgent-Runner says, \"#{body}\"")

          now = Time.now
          poll_until = now + 10.0
          running = true
          while Time.now < poll_until
            running = !running?
            break if running
            sleep(0.1)
          end

          RunLoop.log_debug("Waited for #{Time.now - now} seconds for DeviceAgent to shutdown")
          body
        rescue => e
          RunLoop.log_debug("DeviceAgent-Runner shutdown error: #{e}")
        ensure
          quit_options = { :timeout => 0.5 }
          term_options = { :timeout => 0.5 }
          kill_options = { :timeout => 0.5 }

          process_name = "iOSDeviceManager"
          RunLoop::ProcessWaiter.new(process_name).pids.each do |pid|
            quit = RunLoop::ProcessTerminator.new(pid, "QUIT", process_name, quit_options)
            if !quit.kill_process
              term = RunLoop::ProcessTerminator.new(pid, "TERM", process_name, term_options)
              if !term.kill_process
                kill = RunLoop::ProcessTerminator.new(pid, "KILL", process_name, kill_options)
                kill.kill_process
              end
            end
          end
        end
        body
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


      # TODO cbx_runner_stale? returns false always
      def cbx_runner_stale?
        false
        # The RunLoop::Version class needs to be updated to handle timestamps.
        #
        # if cbx_launcher.name == :xcodebuild
        #   return false
        # end

        # version_info = server_version
        # running_bundle_version = RunLoop::Version.new(version_info[:bundle_version])
        # bundle_version = RunLoop::App.new(cbx_launcher.runner.runner).bundle_version
        #
        # running_bundle_version < bundle_version
      end

      # @!visibility private
      def launch_cbx_runner(options={})
        merged_options = DEFAULTS.merge(options)

        if merged_options[:shutdown_device_agent_before_launch]
          RunLoop.log_debug("Launch options insist that the DeviceAgent be shutdown")
          shutdown

          if cbx_launcher.name == :xcodebuild
            sleep(5.0)
          end
        end

        if running?
          RunLoop.log_debug("DeviceAgent is already running")
          if cbx_runner_stale?
            shutdown
          else
            # TODO: is it necessary to return the pid?  Or can we return true?
            return server_pid
          end
        end

        if cbx_launcher.name == :xcodebuild
          RunLoop.log_debug("xcodebuild is the launcher - terminating existing xcodebuild processes")
          term_options = { :timeout => 0.5 }
          kill_options = { :timeout => 0.5 }
          RunLoop::ProcessWaiter.new("xcodebuild").pids.each do |pid|
            term = RunLoop::ProcessTerminator.new(pid, 'TERM', "xcodebuild", term_options)
            killed = term.kill_process
            unless killed
              RunLoop::ProcessTerminator.new(pid, 'KILL', "xcodebuild", kill_options)
            end
          end
          sleep(2.0)
        end

        start = Time.now
        RunLoop.log_debug("Waiting for CBX-Runner to launch...")
        pid = cbx_launcher.launch(options)

        if cbx_launcher.name == :xcodebuild
          sleep(2.0)
        end

        begin
          timeout = RunLoop::Environment.ci? ? 120 : 60
          health_options = {
            :timeout => timeout,
            :interval => 0.1,
            :retries => (timeout/0.1).to_i
          }

          health(health_options)
        rescue RunLoop::HTTP::Error => _
          raise %Q[

Could not connect to the DeviceAgent service.

device: #{device}
   url: #{url}

To diagnose the problem tail the launcher log file:

$ tail -1000 -F #{cbx_launcher.class.log_file}

]
        end

        RunLoop.log_debug("Took #{Time.now - start} launch and respond to /health")

        # TODO: is it necessary to return the pid?  Or can we return true?
        pid
      end

      # @!visibility private
      def launch_aut(bundle_id = @bundle_id)
        client = client(http_options)
        request = request("session", {:bundleID => bundle_id})

        if device.simulator?
          # Yes, we could use iOSDeviceManager to check, I dont understand the
          # behavior yet - does it require the simulator be launched?
          # CoreSimulator can check without launching the simulator.
          installed = CoreSimulator.app_installed?(device, bundle_id)
        else
          if cbx_launcher.name == :xcodebuild
            # :xcodebuild users are on their own.
            RunLoop.log_debug("Detected :xcodebuild launcher; skipping app installed check")
            installed = true
          else
            installed = cbx_launcher.app_installed?(bundle_id)
          end
        end

        if !installed
          raise RuntimeError, %Q[
The app you are trying to launch is not installed on the target device:

bundle identifier: #{bundle_id}
           device: #{device}

Please install it.

]
        end

        begin
          response = client.post(request)
          RunLoop.log_debug("Launched #{bundle_id} on #{device}")
          RunLoop.log_debug("#{response.body}")
          if device.simulator?
            # It is not clear yet whether we should do this.  There is a problem
            # in the simulator_wait_for_stable_state; it waits too long.
            # device.simulator_wait_for_stable_state
          end
          expect_300_response(response)
        rescue => e
          raise e.class, %Q[

Could not launch #{bundle_id} on #{device}:

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
          raise RunLoop::DeviceAgent::Client::HTTPError,
                "Could not parse response '#{body}'; the app has probably crashed"
        end
      end

      # @!visibility private
      def expect_300_response(response)
        body = response_body_to_hash(response)
        if response.status_code < 300 && !body["error"]
          return body
        end

        if response.status_code > 300
          raise RunLoop::DeviceAgent::Client::HTTPError,
                %Q[
Expected status code < 300, found #{response.status_code}.

Server replied with:

#{body}

]
        else
          raise RunLoop::DeviceAgent::Client::HTTPError,
                %Q[
Expected JSON response with no error, but found

#{body["error"]}

]

        end
      end

      # @!visibility private
      def normalize_orientation_position(position)
        if position.is_a?(Symbol)
          orientation_for_position_symbol(position)
        elsif position.is_a?(Fixnum)
          position
        else
          raise ArgumentError, %Q[
Expected #{position} to be a Symbol or Fixnum but found #{position.class}

          ]
        end
      end

      # @!visibility private
      def orientation_for_position_symbol(position)
        symbol = position.to_sym

        case symbol
          when :down, :bottom
            return 1
          when :up, :top
            return 2
          when :right
            return 3
          when :left
            return 4
          else
            raise ArgumentError, %Q[
Could not coerce '#{position}' into a valid orientation.

Valid values are: :down, :up, :right, :left, :bottom, :top
]
        end
      end
    end
  end
end
