describe RunLoop::HTTP::RetriableClient do
  let(:endpoint) { 'http://localhost:4000' }
  let(:server) { RunLoop::HTTP::Server.new(URI.parse(endpoint)) }

  let(:request) do
    Class.new do
      def route; 'route'; end
      def params; JSON.generate([]); end
    end.new
  end

  before do
    allow(RunLoop::Environment).to receive(:debug?).and_return(true)
  end

   context "self.dylib_path_from_options" do
    context "raises errors" do
      it "when options argument is not a Hash" do
        expect { RunLoop::DylibInjector.dylib_path_from_options([]) }.to raise_error TypeError
        expect { RunLoop::DylibInjector.dylib_path_from_options(nil) }.to raise_error NoMethodError
      end

      it "when :inject_dylib is not a String" do
        options = { :inject_dylib => true }
        expect do
          RunLoop::DylibInjector.dylib_path_from_options(options)
        end.to raise_error ArgumentError, /to be a path to a dylib/
      end

      it "when dylib does not exist" do
        options = { :inject_dylib => 'foo/bar.dylib' }
        expect do
          RunLoop::DylibInjector.dylib_path_from_options(options)
        end.to raise_error RuntimeError, /Cannot load dylib/
      end
    end

    it "returns nil if options does not contain :inject_dylib key" do
      expect(RunLoop::DylibInjector.dylib_path_from_options({})).to be == nil
    end

    it "value of :inject_dylib key if the path exists" do
      path = Resources.shared.sim_dylib_path
      options = { :inject_dylib => path }
      expect(RunLoop::DylibInjector.dylib_path_from_options(options)).to be == path
    end
  end

  context ".new" do
    let(:client) { ::HTTPClient.new }

    before do
      allow_any_instance_of(
        RunLoop::HTTP::RetriableClient).to(
        receive(:new_client!).and_return(client)
      )
    end

    it "sets the instance variables" do
      retriable_client = RunLoop::HTTP::RetriableClient.new(server)

      expect(retriable_client.instance_variable_get(:@server)).to be == server
      expect(retriable_client.instance_variable_get(:@retries)).to be == 5
      expect(retriable_client.instance_variable_get(:@timeout)).to be == 5
      expect(retriable_client.instance_variable_get(:@interval)).to be == 0.5
      expect(retriable_client.instance_variable_get(:@client)).to be == client
    end

    it "respects the options" do
      options =
        {
          retries: :retries,
          timeout: :timeout,
          interval: :interval
        }
      retriable_client = RunLoop::HTTP::RetriableClient.new(server, options)

      expect(retriable_client.instance_variable_get(:@retries)).to be == :retries
      expect(retriable_client.instance_variable_get(:@timeout)).to be == :timeout
      expect(retriable_client.instance_variable_get(:@interval)).to be == :interval
      expect(retriable_client.instance_variable_get(:@client)).to be == client
    end
  end

  context "#reset_all!" do
    let(:client) { ::HTTPClient.new }

    before do
      allow_any_instance_of(
        RunLoop::HTTP::RetriableClient).to(
        receive(:new_client!).and_return(client)
      )
    end

    it "calls HTTPClient#reset_all and sets @client to nil" do
      retriable_client = RunLoop::HTTP::RetriableClient.new(server)
      expect(client).to receive(:reset_all).and_return(true)

      actual = retriable_client.reset_all!
      expect(actual).to be == nil
      expect(retriable_client.instance_variable_get(:@client)).to be == nil
    end

    it "does nothing if there is no @client" do
      retriable_client = RunLoop::HTTP::RetriableClient.new(server)
      retriable_client.instance_variable_set(:@client, nil)
      actual = retriable_client.reset_all!
      expect(actual).to be == nil
    end
  end

  context "#new_client!" do
    let(:client) { ::HTTPClient.new }

    it "calls #reset_all! and returns a new HTTPClient" do
      # The first call to HTTPClient.new from in .new
      expect(::HTTPClient).to receive(:new).and_return(client)
      retriable_client = RunLoop::HTTP::RetriableClient.new(server)

      # Test
      expect(retriable_client.client).to be == client

      # Mock
      expect(retriable_client).to receive(:reset_all!).and_return(nil)
      expect(retriable_client).to receive(:timeout).and_return(3030)

      # The next call to HTTPClient.new made in new_client!
      expect(::HTTPClient).to receive(:new).and_call_original

      # Test
      actual = retriable_client.send(:new_client!)

      expect(actual).not_to be == client
      expect(retriable_client.instance_variable_get(:@client)).to be == actual
      expect(actual.ssl_config.verify_mode).to be == OpenSSL::SSL::VERIFY_NONE

      # Using our timeout and a default connect timeout
      expect(actual.receive_timeout).to be == 3030
      expect(actual.connect_timeout).to be == 15

      # ::HTTPClient defaults are what we expect
      expect(actual.send_timeout).to be == 120
    end
  end

  context "http routes" do
    let(:retriable_client) { RunLoop::HTTP::RetriableClient.new(server, interval:0) }

    it '#get' do
      expect(retriable_client).to receive(:request).with(request, :get, {}).and_return []

      expect(retriable_client.get(request, {})).to be_truthy
    end

    it '#post' do
      expect(retriable_client).to receive(:request).with(request, :post, {}).and_return []

      expect(retriable_client.post(request, {})).to be_truthy
    end

    it "#delete" do
      expect(retriable_client).to receive(:request).with(request, :delete, {}).and_return []

      expect(retriable_client.delete(request, {})).to be_truthy
    end
  end

  context "#request" do

    let(:retriable_client) { RunLoop::HTTP::RetriableClient.new(server, interval:0) }
    let(:retriable_error) { Errno::ECONNREFUSED }

    it 'retries several times' do
      expect(retriable_client).to receive(:send_request).exactly(3).times.and_raise retriable_error

      expect do
        retriable_client.send(:request, request, :post, {:retries => 3})
      end.to raise_error RunLoop::HTTP::Error
    end

    it 'respects a timeout' do
      expect(retriable_client).to receive(:send_request).exactly(:once) do
        sleep 0.1
        raise retriable_error
      end

      expect do
        retriable_client.send(:request, request, :post, {:timeout => 0.01})
      end.to raise_error RunLoop::HTTP::Error
    end

    it 'raises the last error' do
      expect(retriable_client).to receive(:send_request).at_least(:once).and_raise retriable_error

      expect do
        retriable_client.send(:request, request, :post)
      end.to raise_error(RunLoop::HTTP::Error, retriable_error.new.message)
    end
  end

  context "#send_request" do
    let(:retriable_client) { RunLoop::HTTP::RetriableClient.new(server, interval:0) }

    it "calls client#send with the arguments" do
      client = Class.new do
        def to_s; "#<HTTPClient RSPEC STUB>"; end
        def inspect; to_s; end
        def post(_, _, _); :response; end
      end.new

      expect(client).to receive(:post).with(:endpoint, :parameters, :headers).and_call_original

      actual = retriable_client.send(:send_request, client, :post, :endpoint, :parameters, :headers)
      expect(actual).to be == :response
    end
  end
end

