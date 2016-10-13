
describe RunLoop::DeviceAgent::Client do

  let(:bundle_id) { "com.apple.Preferences" }
  let(:launcher_options) { {} }
  let(:device) { Resources.shared.simulator("9.0") }
  let(:cbx_launcher) { RunLoop::DeviceAgent::LauncherStrategy.new(device) }
  let(:client) do
    RunLoop::DeviceAgent::Client.new(bundle_id, device,
                                     cbx_launcher, launcher_options)
  end

  let(:response) do
    Class.new do
      def body; "body"; end
      def to_s; "#<HTTP::Response: #{body}>" ; end
      def inspect; to_s; end
    end.new
  end

  context ".details_for_dylib_injection" do
    let(:app) { RunLoop::App.new(Resources.shared.app_bundle_path) }
    let(:app_details) do
      {
        app: app,
        bundle_id: app.bundle_identifier,
        is_ipa: false
      }
    end
    let(:options) { {} }
    let(:path) { Resources.shared.sim_dylib_path }

    it "returns nil if the options do not include :inject_dylib" do
      expect(RunLoop::DylibInjector).to receive(:dylib_path_from_options).and_return(nil)

      actual = RunLoop::DeviceAgent::Client.details_for_dylib_injection(device,
                                                                        options,
                                                                        app_details)
      expect(actual).to be == nil
    end

    context "dylib injection" do

      before do
        expect(RunLoop::DylibInjector).to(
          receive(:dylib_path_from_options).with(options).and_return(path)
        )
      end

      it "raises error if device is physical device" do
        allow(device).to receive(:physical_device?).and_return(true)

        expect do
          RunLoop::DeviceAgent::Client.details_for_dylib_injection(device,
                                                                   options,
                                                                   app_details)
        end.to raise_error ArgumentError,
                           /Detected :inject_dylib option when targeting a physical device:/
      end

      context "app details only include bundle identifier" do

        before do
          app_details[:app] = nil
          app_details[:is_ipa] = false
        end

        it "returns process details for Settings.app" do
          app_details[:bundle_id] = "com.apple.Preferences"

          actual = RunLoop::DeviceAgent::Client.details_for_dylib_injection(device,
                                                                            options,
                                                                            app_details)
          expect(actual[:process_name]).to be == "Preferences"
          expect(actual[:dylib_path]).to be == path
        end

        it "raises an error for all other bundle identifiers" do
          expect do
            RunLoop::DeviceAgent::Client.details_for_dylib_injection(device,
                                                                     options,
                                                                     app_details)
          end.to raise_error ArgumentError,
                             /target application is a bundle identifier/
        end
      end

      it "returns a hash with the app executable name and dylib path" do
        actual = RunLoop::DeviceAgent::Client.details_for_dylib_injection(device,
                                                                          options,
                                                                          app_details)
        expect(actual[:process_name]).to be == "CalSmoke"
        expect(actual[:dylib_path]).to be == path
      end
    end
  end

  it ".new" do
    expect(client.instance_variable_get(:@bundle_id)).to be == bundle_id
    expect(client.instance_variable_get(:@device)).to be == device
    expect(client.instance_variable_get(:@cbx_launcher)).to be == cbx_launcher
  end

  it "#launch" do
    expect(client).to receive(:launch_cbx_runner).and_return(true)
    expect(client).to receive(:launch_aut).and_return(true)

    expect(client.launch).to be_truthy
  end

  describe "#running?" do
    let(:options) { client.send(:ping_options) }
    it "returns health if running" do
      body = { :health => "good" }
      expect(client).to receive(:health).with(options).and_return(body)

      expect(client.running?).to be == body
    end

    it "returns nil if not running" do
      expect(client).to receive(:health).with(options).and_raise(RuntimeError)

      expect(client.running?).to be == nil
    end
  end

  describe "#stop" do
    it "returns shutdown if running" do
      body = { :health => "shutting down" }
      expect(client).to receive(:shutdown).and_return(body)

      expect(client.stop).to be == body
    end

    it "returns nil if not running" do
      expect(client).to receive(:shutdown).and_raise(RuntimeError)

      expect(client.stop).to be == nil
    end
  end

  it "#launch_other_app" do
    expect(client).to receive(:launch_aut).with(bundle_id).and_return(true)

    expect(client.launch_other_app(bundle_id)).to be_truthy
  end

  it "#url" do
    expected = "http://denis.local:27753/"
    expect(client).to receive(:detect_device_agent_url).and_return(expected)

    actual = client.send(:url)
    expect(actual).to be == expected
    expect(client.instance_variable_get(:@url)).to be == expected
  end

  describe "#detect_device_agent_url" do
    it "DEVICE_AGENT_URL is defined" do
      expect(client).to receive(:url_from_environment).and_return("from environment")

      actual = client.send(:detect_device_agent_url)
      expect(actual).to be == "from environment"
    end

    describe "DEVICE_AGENT_URL is not defined" do
      before do
        expect(client).to receive(:url_from_environment).and_return(nil)
      end

      it "returns 127.0.0.1 url for simulators" do
        expect(client).to receive(:url_for_simulator).and_return("simulator")

        actual = client.send(:detect_device_agent_url)
        expect(actual).to be == "simulator"
      end

      it "returns the DEVICE_ENDPOINT url with correct port" do
        expect(client).to receive(:url_for_simulator).and_return(nil)
        expect(client).to receive(:url_from_device_endpoint).and_return("device endpoint")

        actual = client.send(:detect_device_agent_url)
        expect(actual).to be == "device endpoint"
      end

      it "returns the device name as a DNS hostname" do
        expect(client).to receive(:url_for_simulator).and_return(nil)
        expect(client).to receive(:url_from_device_endpoint).and_return(nil)
        expect(client).to receive(:url_from_device_name).and_return("device name")

        actual = client.send(:detect_device_agent_url)
        expect(actual).to be == "device name"
      end
    end
  end
  describe "#url_from_environment" do
    it "returns nil if DEVICE_AGENT_URL is not set" do
      expect(RunLoop::Environment).to receive(:device_agent_url).and_return(nil)

      actual = client.send(:url_from_environment)
      expect(actual).to be == nil
    end

    context "DEVICE_AGENT_URL is set" do
      let(:url) { "http://denis.local:27753" }

      it "returns the url if it has a trailing /" do
        with_trailing = "#{url}/"
        expect(RunLoop::Environment).to receive(:device_agent_url).and_return(with_trailing)

        actual = client.send(:url_from_environment)
        expect(actual).to be == with_trailing
      end

      it "appends a trailing / if it does not have one" do
        expect(RunLoop::Environment).to receive(:device_agent_url).and_return(url)

        actual = client.send(:url_from_environment)
        expect(actual).to be == "#{url}/"
      end
    end
  end

  describe "#url_for_simulator" do
    let(:port) { RunLoop::DeviceAgent::Client::DEFAULTS[:port] }

    it "returns 127.0.0.1:22753 for simulators" do
      expect(device).to receive(:simulator?).at_least(:once).and_return(true)

      actual = client.send(:url_for_simulator)
      expected = "http://127.0.0.1:#{port}/"
      expect(actual).to be == expected
    end

    it "returns nil for physical devices" do
      expect(device).to receive(:simulator?).at_least(:once).and_return(false)

      actual = client.send(:url_for_simulator)
      expect(actual).to be == nil
    end
  end

  describe "#url_from_device_endpoint" do
    let(:host_url) { "http://denis.local" }

    it "returns nil if DEVICE_ENDPOINT is not set" do
      expect(RunLoop::Environment).to receive(:device_endpoint).and_return(nil)

      actual = client.send(:url_from_device_endpoint)
      expect(actual).to be == nil
    end

    context "DEVICE_ENDPOINT is set" do
      let(:port) { RunLoop::DeviceAgent::Client::DEFAULTS[:port] }
      let(:expected) { "#{host_url}:#{port}/" }

      it "returns a url with the Calabash port replaced" do
        url_with_port = "#{host_url}:37265"
        expect(RunLoop::Environment).to receive(:device_endpoint).and_return(url_with_port)
        actual = client.send(:url_from_device_endpoint)
        expect(actual).to be == expected
      end

      it "returns a url with port appended" do
        expect(RunLoop::Environment).to receive(:device_endpoint).and_return(host_url)

        actual = client.send(:url_from_device_endpoint)
        expect(actual).to be == expected
      end
    end
  end

  describe "#url_from_device_name" do
    let(:port) { RunLoop::DeviceAgent::Client::DEFAULTS[:port] }
    it "returns a url based on the device name" do
      expect(device).to receive(:name).and_return("denis")

      expected = "http://denis.local:#{port}/"
      actual = client.send(:url_from_device_name)
      expect(actual).to be == expected
    end

    context "encodes the name as bonjour name" do
      it "replaces ' with empty character" do
        expect(device).to receive(:name).and_return("Joshua's")

        expected = "http://Joshuas.local:#{port}/"
        actual = client.send(:url_from_device_name)
        expect(actual).to be == expected
      end

      it "replaces spaces with hyphens" do
        expect(device).to receive(:name).and_return("denis the menance")

        expected = "http://denis-the-menance.local:#{port}/"
        actual = client.send(:url_from_device_name)
        expect(actual).to be == expected
      end

      it "reformats default device name" do
        expect(device).to receive(:name).and_return("Joshua's iPhone")

        expected = "http://Joshuas-iPhone.local:#{port}/"
        actual = client.send(:url_from_device_name)
        expect(actual).to be == expected
      end

      it "encodes non ASCII characters" do
        expect(device).to receive(:name).and_return("ITZVÓÃ ●℆❡♡")

        expected = "http://ITZVOA-.local:27753/"
        actual = client.send(:url_from_device_name)
        expect(actual).to be == expected
      end
    end
  end

  it "#server" do
    url = "http://example.com"
    expect(client).to receive(:url).and_return(url)

    actual = client.send(:server)
    expect(actual).to be_a_kind_of(RunLoop::HTTP::Server)
    expect(client.instance_variable_get(:@server)).to be == actual
    expect(client.send(:server)).to be == actual
  end

  it "#client" do
    options = { :timeout => 5 }
    server = client.send(:server)
    expect(RunLoop::HTTP::RetriableClient).to receive(:new).with(server, options).and_call_original

    expect(client.send(:http_client, options)).to be_a_kind_of(RunLoop::HTTP::RetriableClient)
  end

  context "#versioned_route" do
    it "adds leading version to route" do
      stub_const("RunLoop::DeviceAgent::Client::DEFAULTS", {:route_version => "0.1"})
      expect(client.send(:versioned_route, "route")).to be == "0.1/route"
    end
  end

  it "#request" do
    parameters = {:a => "a", :b => "b"}
    route = "route"
    expect(client).to receive(:versioned_route).with(route).and_return(route)
    expect(RunLoop::HTTP::Request).to receive(:request).with(route, parameters).and_call_original

    expect(client.send(:request, route, parameters)).to be_a_kind_of(RunLoop::HTTP::Request)
  end

  describe "#shutdown" do
    it "shuts down the CBX-Runner" do
      pending("behavior is not defined yet")
      raise "NYI"
    end
  end

  # describe "shutdown" do
  #   let(:options) { client.send(:ping_options) }
  #   let(:client) { client.send(:client, options) }
  #   let(:request) { client.send(:request, "shutdown") }
  #
  #   before do
  #     expect(client).to receive(:client).with(options).and_return(client)
  #     expect(client).to receive(:request).with("shutdown").and_return(request)
  #   end
  #
  #   it "can connect" do
  #     expect(client).to receive(:post).with(request).and_return(response)
  #
  #     expect(client.send(:shutdown)).to be == response.body
  #   end
  #
  #   it "cannot connect" do
  #     expect(client).to receive(:post).with(request).and_raise(StandardError,
  #                                                              "Could not connect")
  #
  #     expect(client.send(:shutdown)).to be == nil
  #   end
  # end

  describe "#health" do
    it "reports the health of the CBX-Runner" do
      pending("behavior is not defined yet")
      raise "NYI"
    end
  end

  # describe "#health" do
  #   let(:options) { client.send(:http_options) }
  #   let(:client) { client.send(:client, options) }
  #   let(:request) { client.send(:request, "health") }
  #
  #   before do
  #     expect(client).to receive(:client).with(options).and_return(client)
  #     expect(client).to receive(:request).with("health").and_return(request)
  #   end
  #
  #   it "succeeds" do
  #     expect(client).to receive(:get).with(request).and_return(response)
  #
  #     expect(client.send(:health)).to be == response.body
  #   end
  # end

  it ".default_cbx_launcher" do
    actual = RunLoop::DeviceAgent::Client.default_cbx_launcher(device)
    expect(actual).to be_kind_of(RunLoop::DeviceAgent::IOSDeviceManager)
  end

  describe ".detect_cbx_launcher" do
    let(:options) { {} }
    it "default" do
      actual = RunLoop::DeviceAgent::Client.detect_cbx_launcher(options, device)
      expect(actual).to be_kind_of(RunLoop::DeviceAgent::IOSDeviceManager)
    end

    it ":xcodebuild" do
      options[:cbx_launcher] = :xcodebuild
      actual = RunLoop::DeviceAgent::Client.detect_cbx_launcher(options, device)
      expect(actual).to be_kind_of(RunLoop::DeviceAgent::Xcodebuild)
    end

    it ":ios_device_manager" do
      options[:cbx_launcher] = :ios_device_manager
      actual = RunLoop::DeviceAgent::Client.detect_cbx_launcher(options, device)
      expect(actual).to be_kind_of(RunLoop::DeviceAgent::IOSDeviceManager)
    end

    it "unrecognized" do
      options[:cbx_launcher] = :unknown
      expect do
        RunLoop::DeviceAgent::Client.detect_cbx_launcher(options, device)
      end.to raise_error(ArgumentError,
                         /to be :xcodebuild or :ios_device_manager/)
    end
  end

  context "flattening the tree" do
    it "returns a flat hash of GET /tree" do
      hash = Resources.shared.device_agent_tree_hashes(:preferences)
      expect(client).to receive(:tree).and_return(hash)

      actual = client.send(:_flatten_tree)
      expect(actual.count).to be == 61
      top = actual[0]
      expect(top["id"]).to be == "Settings"
      bottom = actual[60]
      expect(bottom["type"]).to be == "Other"

      expect(actual.all? { |element| element["children"] == nil }).to be_truthy
    end
  end

  context "#_wildcard_query?" do
    it "returns true if uiquery is empty" do
      expect(client.send(:_wildcard_query?, {})).to be_truthy
    end

    it "returns true if uiquery contains only the :all key" do
      expect(client.send(:_wildcard_query?, {:all => true})).to be_truthy
      expect(client.send(:_wildcard_query?, {:all => false})).to be_truthy
    end

    it "return false otherwise" do
      expect(client.send(:_wildcard_query?, {:type => "Button"})).to be_falsey
    end
  end
end
