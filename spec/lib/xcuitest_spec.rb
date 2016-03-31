
describe RunLoop::XCUITest do

  let(:bundle_id) { "com.apple.Preferences" }
  let(:device) { Resources.shared.default_simulator }
  let(:xcuitest) { RunLoop::XCUITest.new(bundle_id, device) }

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

  describe "#workspace" do
    it "raises an error if CBXWS is not defined" do
      expect(RunLoop::Environment).to receive(:cbxws).and_return(nil)

      expect do
        xcuitest.workspace
      end.to raise_error RuntimeError, /TODO: figure out how to distribute the CBX-Runner/
    end

    it "returns the path to the CBXDriver.xcworkspace" do
      path = "path/to/CBXDriver.xcworkspace"
      expect(RunLoop::Environment).to receive(:cbxws).and_return(path)

      expect(xcuitest.workspace).to be == path
    end
  end

  describe "#url" do
    it "uses 127.0.0.1 for simulator targets" do
      expect(device).to receive(:simulator?).at_least(:once).and_return(true)

      actual = xcuitest.send(:url)
      expected = "http://127.0.0.1:27753/"
      expect(actual).to be == expected
      expect(xcuitest.instance_variable_get(:@url)).to be == expected
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

  describe "health" do
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

  describe "file system" do
    let(:dot_dir) { File.expand_path(File.join("tmp", ".run-loop-xcuitest")) }
    let(:xcuitest_dir) { File.join(dot_dir, "xcuitest") }

    before do
      FileUtils.mkdir_p(dot_dir)
      allow(RunLoop::DotDir).to receive(:directory).and_return(dot_dir)
    end

    describe ".dot_dir" do
      it "creates a directory" do
        FileUtils.rm_rf(dot_dir)

        actual = RunLoop::XCUITest.send(:dot_dir)
        expect(actual).to be == xcuitest_dir
        expect(File.directory?(actual)).to be_truthy
      end

      it "returns a path" do
        FileUtils.mkdir_p(xcuitest_dir)

        actual = RunLoop::XCUITest.send(:dot_dir)
        expect(actual).to be == xcuitest_dir
      end
    end

    describe ".log_file" do
      before do
        FileUtils.mkdir_p(xcuitest_dir)
      end

      let(:path) { File.join(xcuitest_dir, "xcuitest.log") }

      it "creates a file" do
        FileUtils.rm_rf(path)

        expect(RunLoop::XCUITest.log_file).to be == path
        expect(File.exist?(path)).to be_truthy
      end

      it "returns existing file path" do
        FileUtils.touch(path)
        expect(RunLoop::XCUITest.log_file).to be == path
      end
    end
  end
end

