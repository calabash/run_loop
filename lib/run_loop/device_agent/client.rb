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
      require "run_loop/dylib_injector"

      class HTTPError < RuntimeError; end

      # @!visibility private
      #
      # These defaults may change at any time.
      #
      # You can override these values if they do not work in your environment.
      #
      # For cucumber users, the best place to override would be in your
      # features/support/env.rb.
      #
      # For example:
      #
      # RunLoop::DeviceAgent::Client::DEFAULTS[:http_timeout] = 60
      # RunLoop::DeviceAgent::Client::DEFAULTS[:device_agent_install_timeout] = 120
      DEFAULTS = {
        :port => 27753,
        :simulator_ip => "127.0.0.1",
        :http_timeout => (RunLoop::Environment.ci? || RunLoop::Environment.xtc?) ? 120 : 20,
        :route_version => "1.0",

        # Ignored in the XTC.
        # This key is subject to removal or changes
        :device_agent_install_timeout => RunLoop::Environment.ci? ? 240 : 120,

        # This value must always be false on the XTC.
        # This is should only be used by gem maintainers or very advanced users.
        :shutdown_device_agent_before_launch => false,

        # This value controls whether or not DeviceAgent should terminate the
        # the Application Under Test (AUT) when a new testing session is
        # started.  The default behavior is to _not_ terminate the AUT if it
        # is already running. If you want your next test to start with your
        # application in a freshly launched state, set this option to true.
        #
        # If the AUT is not running, DeviceAgent performs no action.
        :terminate_aut_before_test => false,

        # This value was derived empirically by typing hundreds of strings
        # using XCUIElement#typeText.  It corresponds to the DeviceAgent
        # constant CBX_DEFAULT_SEND_STRING_FREQUENCY which is 60.  _Decrease_
        # this value if you are timing out typing strings.
        :characters_per_second => 12
      }

      AUT_LAUNCHED_BY_RUN_LOOP_ARG = "LAUNCHED_BY_RUN_LOOP"

      # @!visibility private
      #
      # These defaults may change at any time.
      #
      # You can override these values if they do not work in your environment.
      #
      # For cucumber users, the best place to override would be in your
      # features/support/env.rb.
      #
      # For example:
      #
      # RunLoop::DeviceAgent::Client::WAIT_DEFAULTS[:timeout] = 30
      WAIT_DEFAULTS = {
        timeout: (RunLoop::Environment.ci? ||
                  RunLoop::Environment.xtc?) ? 30 : 15,
        # This key is subject to removal or changes.
        retry_frequency: 0.1,
        # This key is subject to removal or changes.
        exception_class: Timeout::Error
      }

      # @!visibility private
      def self.run(options={})
        simctl = options[:sim_control] || options[:simctl] || RunLoop::Simctl.new
        xcode = options[:xcode] || RunLoop::Xcode.new
        instruments = options[:instruments] || RunLoop::Instruments.new

        # Find the Device under test, the App under test, and reset options.
        device = RunLoop::Device.detect_device(options, xcode, simctl, instruments)
        app_details = RunLoop::DetectAUT.detect_app_under_test(options)
        reset_options = RunLoop::Core.send(:detect_reset_options, options)

        app = app_details[:app]
        bundle_id = app_details[:bundle_id]

        # process name and dylib path
        dylib_injection_details = Client.details_for_dylib_injection(device,
                                                                     options,
                                                                     app_details)

        default_options = {
            :xcode => xcode
        }

        merged_options = default_options.merge(options)

        if device.simulator? && app
          RunLoop::Core.expect_simulator_compatible_arch(device, app)

          # Enable or disable keyboard autocorrection, caps lock and
          # autocapitalization when running on simulator, disables these value by default
          # unless user don't pass true values for these keys
          sim_keyboard = RunLoop::SimKeyboardSettings.new(device)
          sim_keyboard.enable_autocorrection(options[:autocorrection_enabled])
          sim_keyboard.enable_caps_lock(options[:capslock_enabled])
          sim_keyboard.enable_autocapitalization(options[:autocapitalization_enabled])

          if merged_options[:relaunch_simulator]
            RunLoop.log_debug("Detected :relaunch_simulator option; will force simulator to restart")
            RunLoop::CoreSimulator.quit_simulator
          end

          core_sim = RunLoop::CoreSimulator.new(device, app, merged_options)

          if reset_options
            core_sim.reset_app_sandbox
          end

          core_sim.install
        end

        if !RunLoop::Environment.xtc?
          if device.physical_device? && app
            if reset_options
              idm = RunLoop::PhysicalDevice::IOSDeviceManager.new(device)
              idm.reset_app_sandbox(app)
            end
          end
        end

        cbx_launcher = Client.detect_cbx_launcher(merged_options, device)

        code_sign_identity = options[:code_sign_identity]
        if !code_sign_identity
          code_sign_identity = RunLoop::Environment::code_sign_identity
        end

        provisioning_profile = options[:provisioning_profile]
        if !provisioning_profile
          provisioning_profile = RunLoop::Environment::provisioning_profile
        end

        install_timeout = options.fetch(:device_agent_install_timeout,
                                                     DEFAULTS[:device_agent_install_timeout])
        shutdown_device_agent_before_launch = options.fetch(:shutdown_device_agent_before_launch,
                                                            DEFAULTS[:shutdown_device_agent_before_launch])
        terminate_aut_before_test = options.fetch(:terminate_aut_before_test,
                                                   DEFAULTS[:terminate_aut_before_test])

        aut_args = options.fetch(:args, [])
        aut_env = options.fetch(:env, {})

        if !aut_args.include?(AUT_LAUNCHED_BY_RUN_LOOP_ARG)
          aut_args << AUT_LAUNCHED_BY_RUN_LOOP_ARG
        end

        launcher_options = {
            code_sign_identity: code_sign_identity,
            provisioning_profile: provisioning_profile,
            device_agent_install_timeout: install_timeout,
            shutdown_device_agent_before_launch: shutdown_device_agent_before_launch,
            terminate_aut_before_test: terminate_aut_before_test,
            dylib_injection_details: dylib_injection_details,
            aut_args: aut_args,
            aut_env: aut_env
        }

        xcuitest = RunLoop::DeviceAgent::Client.new(bundle_id, device,
                                                    cbx_launcher, launcher_options)
        xcuitest.launch

        if !RunLoop::Environment.xtc?
          cache = {
            :udid => device.udid,
            :app => bundle_id,
            :automator => :device_agent,
            :code_sign_identity => code_sign_identity,
            :provisioning_profile => provisioning_profile,
            :launcher => cbx_launcher.name,
            :launcher_pid => xcuitest.launcher_pid,
            :launcher_options => xcuitest.launcher_options
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

      def self.details_for_dylib_injection(device, options, app_details)
        dylib_path = RunLoop::DylibInjector.dylib_path_from_options(options)

        return nil if !dylib_path

        if device.physical_device?
          raise ArgumentError, %Q[

Detected :inject_dylib option when targeting a physical device:

  #{device}

Injecting the Calabash iOS Server is not supported on physical devices.

]
        end

        app = app_details[:app]
        bundle_id = app_details[:bundle_id]

        details = { dylib_path: dylib_path }

        if !app
          # Special case handling of the Settings.app
          if bundle_id == "com.apple.Preferences"
            details[:process_name] = "Preferences"
          else
            raise ArgumentError, %Q[

Detected :inject_dylib option, but the target application is a bundle identifier:

  app: #{bundle_id}

To use dylib injection, you must provide a path to an .app bundle.

]
          end
        else
          details[:process_name] = app.executable_name
        end
        details
      end

=begin
INSTANCE METHODS
=end
      attr_reader :bundle_id, :device, :cbx_launcher, :launcher_options, :launcher_pid

      # @!visibility private
      #
      # The app with `bundle_id` needs to be installed.
      #
      # @param [String] bundle_id The identifier of the app under test.
      # @param [RunLoop::Device] device The device under test.
      # @param [RunLoop::DeviceAgent::LauncherStrategy] cbx_launcher The entity that
      #  launches the CBXRunner.
      def initialize(bundle_id, device, cbx_launcher, launcher_options)
        @bundle_id = bundle_id
        @device = device
        @cbx_launcher = cbx_launcher
        @launcher_options = launcher_options

        if !@launcher_options[:device_agent_install_timeout]
          default = DEFAULTS[:device_agent_install_timeout]
          @launcher_options[:device_agent_install_timeout] = default
        end
      end

      # @!visibility private
      def to_s
        "#<DeviceAgent #{url} : #{bundle_id} : #{device} : #{cbx_launcher}>"
      end

      # @!visibility private
      def inspect
        to_s
      end

      def launcher_options!(new_options)
        @launcher_options = new_options.dup
      end

      # @!visibility private
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
        if RunLoop::Environment.xtc?
          RunLoop.log_error("Calling shutdown on the XTC is not supported.")
          return
        end

        begin
          shutdown
        rescue => _
          nil
        end
      end

      # @!visibility private
      #
      # Experimental!
      #
      # This will launch the other app using the same arguments and environment
      # as the AUT.
      def launch_other_app(bundle_id)
        launch_aut(bundle_id)
      end

      # @!visibility private
      def device_info
        options = http_options
        request = request("device")
        client = http_client(options)
        response = client.get(request)
        expect_300_response(response)
      end

      # @!visibility private
      def server_version
        options = http_options
        request = request("version")
        client = http_client(options)
        response = client.get(request)
        expect_300_response(response)
      end

      # @!visibility private
      def tree
        options = tree_http_options
        request = request("tree")
        client = http_client(options)
        response = client.get(request)
        expect_300_response(response)
      end

      # @!visibility private
      def keyboard_visible?
        options = http_options
        parameters = { :type => "Keyboard" }
        request = request("query", parameters)
        client = http_client(options)
        response = client.post(request)
        hash = expect_300_response(response)
        result = hash["result"]

        return false if result.count == 0
        return false if result[0].count == 0

        element = result[0]
        hit_point = element["hit_point"]
        hit_point["x"] != -1 && hit_point["y"] != -1
      end

      # @!visibility private
      def clear_text
        # Tries to touch the keyboard delete key, but falls back on typing the
        # backspace character.
        options = enter_text_http_options("\b")
        parameters = {
          :gesture => "clear_text"
        }
        request = request("gesture", parameters)
        client = http_client(options)
        response = client.post(request)
        expect_300_response(response)
      end

      # @!visibility private
      def enter_text(string)
        if !keyboard_visible?
          raise RuntimeError, "Keyboard must be visible"
        end
        options = enter_text_http_options(string.to_s)
        parameters = {
          :gesture => "enter_text",
          :options => {
            :string => string.to_s
          }
        }
        request = request("gesture", parameters)
        client = http_client(options)
        response = client.post(request)
        expect_300_response(response)
      end

      # @!visibility private
      #
      # Some clients are performing keyboard checks _before_ calling #enter_text.
      #
      # 1. Removes duplicate check.
      # 2. It turns out DeviceAgent query can be very slow.
      def enter_text_without_keyboard_check(string)
        options = enter_text_http_options(string.to_s)
        parameters = {
          :gesture => "enter_text",
          :options => {
            :string => string.to_s
          }
        }
        request = request("gesture", parameters)
        client = http_client(options)
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
      #  # Equivalent to Calabash query("*")
      #  query({})
      #
      #  # Equivalent to Calabash query("all *")
      #  query({all: true})
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
      # @see https://developer.apple.com/documentation/xctest/xcuielementtype
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

Allowed keys for a query are:

#{keys}

]
        end

        if _wildcard_query?(uiquery)
          elements = _flatten_tree
        else
          parameters = merged_options.dup.tap { |hs| hs.delete(:all) }
          if parameters.empty?
            keys = allowed_keys.map { |key| ":#{key}" }.join(", ")
            raise ArgumentError, %Q[
Query must contain at least one of these keys:

#{keys}

]
          end

          request = request("query", parameters)
          client = http_client(http_options)

          RunLoop.log_debug %Q[Sending query with parameters:

#{JSON.pretty_generate(parameters)}

]

          response = client.post(request)
          hash = expect_300_response(response)
          elements = hash["result"]
        end

        if merged_options[:all]
          elements
        else
          elements.select do |element|
            element["hitable"]
          end
        end
      end

      # @!visibility private
      def alert
        parameters = { :type => "Alert" }
        request = request("query", parameters)
        client = http_client(http_options)
        response = client.post(request)
        hash = expect_300_response(response)
        hash["result"]
      end

      # @!visibility private
      def alert_visible?
        !alert.empty?
      end

      # @!visibility private
      def springboard_alert
        request = request("springboard-alert")
        client = http_client(http_options)
        response = client.get(request)
        expect_300_response(response)
      end

      # @!visibility private
      def springboard_alert_visible?
        !springboard_alert.empty?
      end

      # @!visibility private
      def dismiss_springboard_alert(button_title)
        parameters = { :button_title => button_title }
        request = request("dismiss-springboard-alert", parameters)
        client = http_client(http_options)
        response = client.post(request)
        hash = expect_300_response(response)

        if hash["error"]
          raise RuntimeError, %Q[
Could not dismiss SpringBoard alert by touching button with title '#{button_title}':

#{hash["error"]}

]
        end
        true
      end

      # @!visibility private
      def set_dismiss_springboard_alerts_automatically(true_or_false)
        if ![true, false].include?(true_or_false)
          raise ArgumentError, "Expected #{true_or_false} to be a boolean true or false"
        end

        parameters = { :dismiss_automatically => true_or_false }
        request = request("set-dismiss-springboard-alerts-automatically", parameters)
        client = http_client(http_options)
        response = client.post(request)
        hash = expect_300_response(response)
        hash["is_dismissing_alerts_automatically"]
      end

      # @!visibility private
      # @see #query
      def query_for_coordinate(uiquery)
        element = wait_for_view(uiquery)
        coordinate_from_query_result([element])
      end

      # @!visibility private
      #
      # :num_fingers
      # :duration
      # :repetitions
      # @see #query
      def touch(uiquery, options={})
        coordinate = query_for_coordinate(uiquery)
        perform_coordinate_gesture("touch", coordinate[:x], coordinate[:y], options)
      end

      # @!visibility private
      # @see #touch
      def touch_coordinate(coordinate, options={})
        x = coordinate[:x] || coordinate["x"]
        y = coordinate[:y] || coordinate["y"]
        touch_point(x, y, options)
      end

      # @!visibility private
      # @see #touch
      def touch_point(x, y, options={})
        perform_coordinate_gesture("touch", x, y, options)
      end

      # @!visibility private
      # @see #touch
      # @see #query
      def double_tap(uiquery, options={})
        coordinate = query_for_coordinate(uiquery)
        perform_coordinate_gesture("double_tap",
                                   coordinate[:x], coordinate[:y],
                                   options)
      end

      # @!visibility private
      # @see #touch
      # @see #query
      def two_finger_tap(uiquery, options={})
        coordinate = query_for_coordinate(uiquery)
        perform_coordinate_gesture("two_finger_tap",
                                   coordinate[:x], coordinate[:y],
                                   options)
      end

      # @!visibility private
      # @see #touch
      # @see #query
      def long_press(uiquery, options={})
        merged_options = {
          :duration => 1.1
        }.merge(options)

        coordinate = query_for_coordinate(uiquery)
        perform_coordinate_gesture("touch", coordinate[:x], coordinate[:y],
                                   merged_options)
      end

      # @!visibility private
      def rotate_home_button_to(position, sleep_for=1.0)
        orientation = normalize_orientation_position(position)
        parameters = {
          :orientation => orientation,
          :seconds_to_sleep_after => sleep_for
        }
        request = request("rotate_home_button_to", parameters)
        client = http_client(http_options)
        response = client.post(request)
        expect_300_response(response)
      end

      # @!visibility private
      def orientations
        request = request("orientations")
        client = http_client(http_options)
        response = client.get(request)
        expect_300_response(response)
      end

      # @!visibility private
      def pan_between_coordinates(start_point, end_point, options={})
        default_options = {
          :num_fingers => 1,
          :duration => 0.5,
          # How long the first touch needs to activate or grab the element.
          :first_touch_hold_duration => 0.0
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
        client = http_client(http_options)
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
        client = http_client(http_options)
        response = client.post(request)
        json = expect_300_response(response)
        # Set in the route
        sleep(0.2)
        json
      end

      def element_types
        request = request("element-types")
        client = http_client(http_options)
        response = client.get(request)
        expect_300_response(response)["types"]
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
      def wait_for_no_keyboard(timeout=WAIT_DEFAULTS[:timeout])
        options = WAIT_DEFAULTS.dup
        options[:timeout] = timeout
        message = %Q[

Timed out after #{timeout} seconds waiting for the keyboard to disappear.

]
        wait_for(message, options) do
          !keyboard_visible?
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
      def wait_for_springboard_alert(timeout=WAIT_DEFAULTS[:timeout])
        options = WAIT_DEFAULTS.dup
        options[:timeout] = timeout
        message = %Q[

Timed out after #{timeout} seconds waiting for a SpringBoard alert to appear.

]
        wait_for(message, options) do
          springboard_alert_visible?
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
      def wait_for_no_springboard_alert(timeout=WAIT_DEFAULTS[:timeout])
        options = WAIT_DEFAULTS.dup
        options[:timeout] = timeout
        message = %Q[

Timed out after #{timeout} seconds waiting for a SpringBoard alert to disappear.

]
        wait_for(message, options) do
          !springboard_alert_visible?
        end
      end

      # @!visibility private
      def wait_for_text_in_view(text, uiquery, options={})
        merged_options = WAIT_DEFAULTS.merge(options)

        begin
          wait_for("TMP", merged_options) do
            view = query(uiquery).first

            if view
              # Guard against this edge case:
              #
              # Text is "" and value or label keys do not exist in view which
              # implies that value or label was the empty string (see the
              # DeviceAgent JSONUtils and Facebook macros).
              if text == "" || text == nil
                view["value"] == nil && view["label"] == nil
              else
                [view["value"], view["label"]].any? { |elm| elm == text }
              end
            else
              false
            end
          end
        rescue merged_options[:exception_class] => e
          view = query(uiquery)
          if !view
            message = %Q[
Timed out wait after #{merged_options[:timeout]} seconds waiting for a view to match:

  #{uiquery}

]
          else
            message = %Q[
Timed out after #{merged_options[:timeout]} seconds waiting for a view matching:

  '#{uiquery}'

to have 'value' or 'label' matching text:

  '#{text}'

Found:

#{JSON.pretty_generate(view)}

]
          end
          fail(merged_options[:exception_class], message)
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

=begin
PRIVATE
=end
      private

      attr_reader :http_client

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
      def http_client(options={})
        if !@http_client
          @http_client = RunLoop::HTTP::RetriableClient.new(server, options)
        else
          # If the options are different, create a new client
          if options[:retries] != @http_client.retries ||
            options[:timeout] != @http_client.timeout ||
            options[:interval] != @http_client.interval
            reset_http_client!
            @http_client = RunLoop::HTTP::RetriableClient.new(server, options)
          else
          end
        end
        @http_client
      end

      # @!visibility private
      def reset_http_client!
        if @http_client
          @http_client.reset_all!
          @http_client = nil
        end
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
      #
      # Tree can take a very long time.
      def tree_http_options
        timeout = DEFAULTS[:http_timeout] * 6
        {
          :timeout => timeout,
          :interval => 0.1,
          :retries => (timeout/0.1).to_i
        }
      end

      # @!visibility private
      #
      # A patch while we are trying to figure out what is wrong with text entry.
      def enter_text_http_options(string)
        characters = string.length + 1
        characters_per_second = DEFAULTS[:characters_per_second]
        to_type_timeout = [characters/characters_per_second, 2.0].max
        timeout = (DEFAULTS[:http_timeout] * 3) + to_type_timeout
        {
          :timeout => timeout,
          :interval => 0.1,
          :retries => (timeout/0.1).to_i
        }
      end

      # @!visibility private
      def process_pid(bundle_identifier)
        request = request("pid", { bundleID: bundle_identifier })
        client = http_client(http_options)
        response = client.post(request)
        expect_300_response(response)["pid"]
      end

      # @!visibility private
      def app_running?(bundle_identifier)
        process_pid(bundle_identifier) != "0"
      end

      # @!visibility private
      def terminate_app(bundle_identifier, strategy=nil)
        request = request("terminate", { bundleID: bundle_identifier,
                                         strategy: strategy})
        client = http_client(http_options)
        response = client.post(request)
        expect_300_response(response)
      end

      # @!visibility private
      def app_state(bundle_identifier)
        request = request("pid", { bundleID: bundle_identifier })
        client = http_client(http_options)
        response = client.post(request)
        expect_300_response(response)["state_string"]
      end

      # @!visibility private
      def send_app_to_background(bundle_identifier, options={})
        state = app_state(bundle_identifier)

        if state != "foreground"
          raise(RuntimeError, %Q[

Expected '#{bundle_identifier}' to be in the foreground, but found '#{state}'"

])

        else
          parameters = {
            # How long to touch the home bottom.
            duration: 0.001
          }.merge(options)

          request = request("home", parameters)
          client = http_client(http_options)
          response = client.post(request)
          expect_300_response(response)["state_string"]
        end
      end

      # @!visibility private
      def session_identifier
        options = http_options
        request = request("sessionIdentifier")
        client = http_client(options)
        response = client.get(request)
        expect_300_response(response)
      end

      # @!visibility private
      def session_delete
        # https://xamarin.atlassian.net/browse/TCFW-255
        # httpclient is unable to send a valid DELETE
        args = ["curl", "--insecure", "--silent", "--request", "DELETE",
                %Q[#{url}#{versioned_route("session")}]]

        begin
          hash = run_shell_command(args, {:log_cmd => true, :timeout => 10})

          begin
            JSON.parse(hash[:out])
          rescue TypeError, JSON::ParserError => _
            raise RunLoop::DeviceAgent::Client::HTTPError, %Q[
Could not parse response from server:

body => "#{hash[:out]}"

If the body empty, the DeviceAgent has probably crashed.

]
          end
        rescue Shell::TimeoutError => _
          RunLoop.log_debug("Timed out calling DELETE session/ after 10 seconds")
          {}
        end
      end

      # @!visibility private
      def shutdown

        if RunLoop::Environment.xtc?
          RunLoop.log_error("Calling shutdown on the XTC is not supported.")
          return
        end

        begin
          if !running?
            RunLoop.log_debug("DeviceAgent-Runner is not running")
          else
            session_delete

            request = request("shutdown")
            client = http_client(ping_options)
            response = client.post(request)
            hash = expect_300_response(response)
            message = hash["message"]

            RunLoop.log_debug(%Q[DeviceAgent-Runner says, "#{message}"])

            now = Time.now
            poll_until = now + 10.0
            stopped = false
            while Time.now < poll_until
              stopped = !running?
              break if stopped
              sleep(0.1)
            end

            RunLoop.log_debug("Waited for #{Time.now - now} seconds for DeviceAgent to shutdown")
          end
        rescue RunLoop::DeviceAgent::Client::HTTPError, HTTPClient::ReceiveTimeoutError => e
          RunLoop.log_debug("DeviceAgent-Runner shutdown error: #{e.message}")
        ensure
          if @launcher_pid
            term_options = { :timeout => 1.5 }
            kill_options = { :timeout => 1.0 }

            process_name = cbx_launcher.name
            pid = @launcher_pid.to_i

            term = RunLoop::ProcessTerminator.new(pid, "TERM", process_name, term_options)
            if !term.kill_process
              kill = RunLoop::ProcessTerminator.new(pid, "KILL", process_name, kill_options)
              kill.kill_process
            end
          end
        end
        hash
      end

      # @!visibility private
      def health(options={})
        merged_options = http_options.merge(options)
        request = request("health")
        client = http_client(merged_options)
        response = client.get(request)
        hash = expect_300_response(response)
        status = hash["status"]
        RunLoop.log_debug(%Q[DeviceAgent says, "#{status}"])
        hash
      end

      # @!visibility private
      def cbx_runner_stale?
        return false if RunLoop::Environment.xtc?
        return false if cbx_launcher.name == :xcodebuild
        return false if !running?

        version_info = server_version
        running_version_timestamp = version_info["bundle_version"].to_i

        app = RunLoop::App.new(cbx_launcher.runner.runner)
        plist_buddy = RunLoop::PlistBuddy.new
        version_timestamp = plist_buddy.plist_read("CFBundleVersion", app.info_plist_path).to_i

        if running_version_timestamp == version_timestamp
          RunLoop.log_debug("The running DeviceAgent version is the same as the version on disk")
          false
        else
          RunLoop.log_debug("The running DeviceAgent version is not the same as the version on disk")
          true
        end
      end

      # @!visibility private
      def launch_cbx_runner
        options = launcher_options

        if options[:shutdown_device_agent_before_launch]
          RunLoop.log_debug("Launch options insist that the DeviceAgent be shutdown")
          shutdown
        end

        if cbx_runner_stale?
          RunLoop.log_debug("The DeviceAgent that is running is stale; shutting down")
          shutdown
        end

        if running?
          RunLoop.log_debug("DeviceAgent is already running")
          return true
        end

        start = Time.now
        RunLoop.log_debug("Waiting for DeviceAgent to launch...")
        @launcher_pid = cbx_launcher.launch(options)

        begin
          timeout = options[:device_agent_install_timeout] * 1.5
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

$ tail -1000 -F #{cbx_launcher_log_file}

]
        end

        RunLoop.log_debug("Took #{Time.now - start} launch and respond to /health")
        true
      end

      # @!visibility private
      def launch_aut(bundle_id = @bundle_id)
        # This check needs to be done _before_ the DeviceAgent is launched.
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
            # Too slow for most devices
            # https://jira.xamarin.com/browse/TCFW-273
            # installed = cbx_launcher.app_installed?(bundle_id)
            installed = true
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

        retries = 5

        # Launch arguments and environment arguments cannot be nil
        # The public interface Client.run has a guard against this, but
        # internal callers to do not.
        aut_args = launcher_options.fetch(:aut_args, [])
        aut_env = launcher_options.fetch(:aut_env, {})
        terminate_aut = launcher_options.fetch(:terminate_aut_before_test, false)

        begin
          client = http_client(http_options)
          request = request("session",
                            {
                              :bundle_id => bundle_id,
                              :launchArgs => aut_args,
                              :environment => aut_env,
                              :terminate_aut_if_running => terminate_aut
                            })
          response = client.post(request)
          RunLoop.log_debug("Launched #{bundle_id} on #{device}")
          RunLoop.log_debug("#{response.body}")

          expect_300_response(response)

          # Dylib injection.  DeviceAgent.run checks the arguments.
          dylib_injection_details = launcher_options[:dylib_injection_details]
          if dylib_injection_details
            process_name = dylib_injection_details[:process_name]
            dylib_path = dylib_injection_details[:dylib_path]
            injector = RunLoop::DylibInjector.new(process_name, dylib_path)
            injector.retriable_inject_dylib
          end
        rescue => e
          retries = retries - 1
          if !RunLoop::Environment.xtc?
            if retries >= 0
              if !running?
                RunLoop.log_debug("The DeviceAgent stopped running after POST /session; retrying")
                launch_cbx_runner
              else
                RunLoop.log_debug("Failed to launch the AUT: #{bundle_id}; retrying")
              end
              retry
            end
          end

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
          raise RunLoop::DeviceAgent::Client::HTTPError, %Q[
Could not parse response from server:

body => "#{body}"

If the body empty, the DeviceAgent has probably crashed.

]
        end
      end

      # @!visibility private
      def expect_300_response(response)
        body = response_body_to_hash(response)
        if response.status_code < 400 && !body["error"]
          return body
        end

        reset_http_client!

        if response.status_code >= 400
          raise RunLoop::DeviceAgent::Client::HTTPError,
                %Q[
Expected status code < 400, found #{response.status_code}.

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

      # @!visibility private
      def cbx_launcher_log_file
        if cbx_launcher.name == :ios_device_manager
          # The location of the iOSDeviceManager logs has changed
          File.join(RunLoop::Environment.user_home_directory,
                    ".calabash", "iOSDeviceManager", "logs", "current.log")
        else
          cbx_launcher.class.log_file
        end
      end

      # @!visibility private
      # Private method.  Do not call.
      # Flattens the result of `tree`.
      def _flatten_tree
        result = []
        _flatten_tree_helper(tree, result)
        result
      end

      # @!visibility private
      # Private method.  Do not call.
      def _flatten_tree_helper(tree, accumulator_array)
        element_in_tree = {}
        tree.each_pair do |key, value|
          if key != "children"
            element_in_tree[key] = value
          end
        end
        accumulator_array.push(element_in_tree)

        if tree.key?("children")
          tree["children"].each do |subtree|
            _flatten_tree_helper(subtree, accumulator_array)
          end
        end
      end

      # @!visibility private
      # Private method.  Do not call.
      def _dismiss_springboard_alerts
        request = request("dismiss-springboard-alerts")
        client = http_client(http_options)
        response = client.post(request)
        expect_300_response(response)
      end

      # @!visibility private
      # Private method.  Do not call.
      def _wildcard_query?(uiquery)
        return true if uiquery.empty?
        return false if uiquery.count != 1

        uiquery.has_key?(:all)
      end

    end
  end
end
