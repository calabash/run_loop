
describe RunLoop::XCUITest do

  let(:bundle_id) { "com.apple.Preferences" }
  let(:device) { Resources.shared.simulator("9.0") }
  let(:cbx_launcher) { RunLoop::DeviceAgent::Launcher.new(device) }
  let(:xcuitest) { RunLoop::XCUITest.new(bundle_id, device, cbx_launcher) }

  let(:response) do
    Class.new do
      def body; "body"; end
      def to_s; "#<HTTP::Response: #{body}>" ; end
      def inspect; to_s; end
    end.new
  end

  it ".new" do
    expect(xcuitest.instance_variable_get(:@bundle_id)).to be == bundle_id
    expect(xcuitest.instance_variable_get(:@device)).to be == device
    expect(xcuitest.instance_variable_get(:@cbx_launcher)).to be == cbx_launcher
  end

  it "#launch" do
    expect(xcuitest).to receive(:launch_cbx_runner).and_return(true)
    expect(xcuitest).to receive(:launch_aut).and_return(true)

    expect(xcuitest.launch).to be_truthy
  end

  describe "#running?" do
    let(:options) { xcuitest.send(:ping_options) }
    it "returns health if running" do
      body = { :health => "good" }
      expect(xcuitest).to receive(:health).with(options).and_return(body)

      expect(xcuitest.running?).to be == body
    end

    it "returns nil if not running" do
      expect(xcuitest).to receive(:health).with(options).and_raise(RuntimeError)

      expect(xcuitest.running?).to be == nil
    end
  end

  describe "#stop" do
    it "returns shutdown if running" do
      body = { :health => "shutting down" }
      expect(xcuitest).to receive(:shutdown).and_return(body)

      expect(xcuitest.stop).to be == body
    end

    it "returns nil if not running" do
      expect(xcuitest).to receive(:shutdown).and_raise(RuntimeError)

      expect(xcuitest.stop).to be == nil
    end
  end

  it "#launch_other_app" do
    expect(xcuitest).to receive(:launch_aut).with(bundle_id).and_return(true)

    expect(xcuitest.launch_other_app(bundle_id)).to be_truthy
  end

  it "#url" do
    expected = "http://denis.local:27753/"
    expect(xcuitest).to receive(:detect_device_agent_url).and_return(expected)

    actual = xcuitest.send(:url)
    expect(actual).to be == expected
    expect(xcuitest.instance_variable_get(:@url)).to be == expected
  end

  describe "#detect_device_agent_url" do
    it "DEVICE_AGENT_URL is defined" do
      expect(xcuitest).to receive(:url_from_environment).and_return("from environment")

      actual = xcuitest.send(:detect_device_agent_url)
      expect(actual).to be == "from environment"
    end

    describe "DEVICE_AGENT_URL is not defined" do
      before do
        expect(xcuitest).to receive(:url_from_environment).and_return(nil)
      end

      it "returns 127.0.0.1 url for simulators" do
        expect(xcuitest).to receive(:url_for_simulator).and_return("simulator")

        actual = xcuitest.send(:detect_device_agent_url)
        expect(actual).to be == "simulator"
      end

      it "returns the DEVICE_ENDPOINT url with correct port" do
        expect(xcuitest).to receive(:url_for_simulator).and_return(nil)
        expect(xcuitest).to receive(:url_from_device_endpoint).and_return("device endpoint")

        actual = xcuitest.send(:detect_device_agent_url)
        expect(actual).to be == "device endpoint"
      end

      it "returns the device name as a DNS hostname" do
        expect(xcuitest).to receive(:url_for_simulator).and_return(nil)
        expect(xcuitest).to receive(:url_from_device_endpoint).and_return(nil)
        expect(xcuitest).to receive(:url_from_device_name).and_return("device name")

        actual = xcuitest.send(:detect_device_agent_url)
        expect(actual).to be == "device name"
      end
    end
  end
  describe "#url_from_environment" do
    it "returns nil if DEVICE_AGENT_URL is not set" do
      expect(RunLoop::Environment).to receive(:device_agent_url).and_return(nil)

      actual = xcuitest.send(:url_from_environment)
      expect(actual).to be == nil
    end

    context "DEVICE_AGENT_URL is set" do
      let(:url) { "http://denis.local:27753" }

      it "returns the url if it has a trailing /" do
        with_trailing = "#{url}/"
        expect(RunLoop::Environment).to receive(:device_agent_url).and_return(with_trailing)

        actual = xcuitest.send(:url_from_environment)
        expect(actual).to be == with_trailing
      end

      it "appends a trailing / if it does not have one" do
        expect(RunLoop::Environment).to receive(:device_agent_url).and_return(url)

        actual = xcuitest.send(:url_from_environment)
        expect(actual).to be == "#{url}/"
      end
    end
  end

  describe "#url_for_simulator" do
    let(:port) { RunLoop::XCUITest::DEFAULTS[:port] }

    it "returns 127.0.0.1:22753 for simulators" do
      expect(device).to receive(:simulator?).at_least(:once).and_return(true)

      actual = xcuitest.send(:url_for_simulator)
      expected = "http://127.0.0.1:#{port}/"
      expect(actual).to be == expected
    end

    it "returns nil for physical devices" do
      expect(device).to receive(:simulator?).at_least(:once).and_return(false)

      actual = xcuitest.send(:url_for_simulator)
      expect(actual).to be == nil
    end
  end

  describe "#url_from_device_endpoint" do
    let(:host_url) { "http://denis.local" }

    it "returns nil if DEVICE_ENDPOINT is not set" do
      expect(RunLoop::Environment).to receive(:device_endpoint).and_return(nil)

      actual = xcuitest.send(:url_from_device_endpoint)
      expect(actual).to be == nil
    end

    context "DEVICE_ENDPOINT is set" do
      let(:port) { RunLoop::XCUITest::DEFAULTS[:port] }
      let(:expected) { "#{host_url}:#{port}/" }

      it "returns a url with the Calabash port replaced" do
        url_with_port = "#{host_url}:37265"
        expect(RunLoop::Environment).to receive(:device_endpoint).and_return(url_with_port)
        actual = xcuitest.send(:url_from_device_endpoint)
        expect(actual).to be == expected
      end

      it "returns a url with port appended" do
        expect(RunLoop::Environment).to receive(:device_endpoint).and_return(host_url)

        actual = xcuitest.send(:url_from_device_endpoint)
        expect(actual).to be == expected
      end
    end
  end

  describe "#url_from_device_name" do
    let(:port) { RunLoop::XCUITest::DEFAULTS[:port] }
    it "returns a url based on the device name" do
      expect(device).to receive(:name).and_return("denis")

      expected = "http://denis.local:#{port}/"
      actual = xcuitest.send(:url_from_device_name)
      expect(actual).to be == expected
    end

    context "encodes the name as bonjour name" do
      it "replaces ' with empty character" do
        expect(device).to receive(:name).and_return("Joshua's")

        expected = "http://Joshuas.local:#{port}/"
        actual = xcuitest.send(:url_from_device_name)
        expect(actual).to be == expected
      end

      it "replaces spaces with hyphens" do
        expect(device).to receive(:name).and_return("denis the menance")

        expected = "http://denis-the-menance.local:#{port}/"
        actual = xcuitest.send(:url_from_device_name)
        expect(actual).to be == expected
      end

      it "reformats default device name" do
        expect(device).to receive(:name).and_return("Joshua's iPhone")

        expected = "http://Joshuas-iPhone.local:#{port}/"
        actual = xcuitest.send(:url_from_device_name)
        expect(actual).to be == expected
      end

      it "encodes non ASCII characters" do
        expect(device).to receive(:name).and_return("ITZVÓÃ ●℆❡♡")

        expected = "http://ITZVOA-.local:27753/"
        actual = xcuitest.send(:url_from_device_name)
        expect(actual).to be == expected
      end
    end
  end

  it "#server" do
    url = "http://example.com"
    expect(xcuitest).to receive(:url).and_return(url)

    actual = xcuitest.send(:server)
    expect(actual).to be_a_kind_of(RunLoop::HTTP::Server)
    expect(xcuitest.instance_variable_get(:@server)).to be == actual
    expect(xcuitest.send(:server)).to be == actual
  end

  it "#client" do
    options = { :timeout => 5 }
    server = xcuitest.send(:server)
    expect(RunLoop::HTTP::RetriableClient).to receive(:new).with(server, options).and_call_original

    expect(xcuitest.send(:client, options)).to be_a_kind_of(RunLoop::HTTP::RetriableClient)
  end

  describe "#versioned_route" do
    it "exceptions" do
      expect(xcuitest.send(:versioned_route, "health")).to be == "health"
      expect(xcuitest.send(:versioned_route, "ping")).to be == "ping"
      expect(xcuitest.send(:versioned_route, "sessionIdentifier")).to be == "sessionIdentifier"
    end

    it "any other route" do
      stub_const("RunLoop::XCUITest::DEFAULTS", {:version => "0.1"})
      expect(xcuitest.send(:versioned_route, "route")).to be == "0.1/route"
    end
  end

  it "#request" do
    parameters = {:a => "a", :b => "b"}
    route = "route"
    expect(xcuitest).to receive(:versioned_route).with(route).and_return(route)
    expect(RunLoop::HTTP::Request).to receive(:request).with(route, parameters).and_call_original

    expect(xcuitest.send(:request, route, parameters)).to be_a_kind_of(RunLoop::HTTP::Request)
  end

  # describe "shutdown" do
  #   let(:options) { xcuitest.send(:ping_options) }
  #   let(:client) { xcuitest.send(:client, options) }
  #   let(:request) { xcuitest.send(:request, "shutdown") }
  #
  #   before do
  #     expect(xcuitest).to receive(:client).with(options).and_return(client)
  #     expect(xcuitest).to receive(:request).with("shutdown").and_return(request)
  #   end
  #
  #   it "can connect" do
  #     expect(client).to receive(:post).with(request).and_return(response)
  #
  #     expect(xcuitest.send(:shutdown)).to be == response.body
  #   end
  #
  #   it "cannot connect" do
  #     expect(client).to receive(:post).with(request).and_raise(StandardError,
  #                                                              "Could not connect")
  #
  #     expect(xcuitest.send(:shutdown)).to be == nil
  #   end
  # end

  describe "#health" do
    let(:options) { xcuitest.send(:http_options) }
    let(:client) { xcuitest.send(:client, options) }
    let(:request) { xcuitest.send(:request, "health") }

    before do
      expect(xcuitest).to receive(:client).with(options).and_return(client)
      expect(xcuitest).to receive(:request).with("health").and_return(request)
    end

    it "succeeds" do
      expect(client).to receive(:get).with(request).and_return(response)

      expect(xcuitest.send(:health)).to be == response.body
    end
  end

  it ".default_cbx_launcher" do
    actual = RunLoop::XCUITest.default_cbx_launcher(device)
    expect(actual).to be_kind_of(RunLoop::DeviceAgent::IOSDeviceManager)
  end

  describe ".detect_cbx_launcher" do
    let(:options) { {} }
    it "default" do
      actual = RunLoop::XCUITest.detect_cbx_launcher(options, device)
      expect(actual).to be_kind_of(RunLoop::DeviceAgent::IOSDeviceManager)
    end

    it ":xcodebuild" do
      options[:cbx_launcher] = :xcodebuild
      actual = RunLoop::XCUITest.detect_cbx_launcher(options, device)
      expect(actual).to be_kind_of(RunLoop::DeviceAgent::Xcodebuild)
    end

    it ":ios_device_manager" do
      options[:cbx_launcher] = :ios_device_manager
      actual = RunLoop::XCUITest.detect_cbx_launcher(options, device)
      expect(actual).to be_kind_of(RunLoop::DeviceAgent::IOSDeviceManager)
    end

    it "unrecognized" do
      options[:cbx_launcher] = :unknown
      expect do
        RunLoop::XCUITest.detect_cbx_launcher(options, device)
      end.to raise_error(ArgumentError,
                         /to be :xcodebuild or :ios_device_manager/)
    end
  end
end
