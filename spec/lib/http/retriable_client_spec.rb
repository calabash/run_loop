describe RunLoop::HTTP::RetriableClient do
  let(:endpoint) { 'http://localhost:4000' }
  let(:server) { RunLoop::HTTP::Server.new(URI.parse(endpoint)) }
  let(:retriable_client) { RunLoop::HTTP::RetriableClient.new(server, interval:0) }

  let(:request) do
    Class.new do
      def route; 'route'; end
      def params; JSON.generate([]); end
    end.new
  end

  before do
    allow(RunLoop::Environment).to receive(:debug?).and_return(true)
  end

  describe '.new' do
    it 'sets the instance variables' do
      expect(::HTTPClient).to receive(:new).and_return :new
      expect(retriable_client.client).to be == :new
      expect(retriable_client.instance_variable_get(:@client)).to be == :new
      expect(retriable_client.instance_variable_get(:@server)).to be == server
      expect(retriable_client.instance_variable_get(:@retries)).to be_truthy
      expect(retriable_client.instance_variable_get(:@timeout)).to be_truthy
      expect(retriable_client.instance_variable_get(:@interval)).to be_truthy
    end

    it 'respects the options' do
      options =
            {
                  client: :client,
                  retries: :retries,
                  timeout: :timeout,
                  interval: :interval
            }
      retriable_client = RunLoop::HTTP::RetriableClient.new(server, options)
      expect(retriable_client.instance_variable_get(:@client)).to be == :client
      expect(retriable_client.instance_variable_get(:@retries)).to be == :retries
      expect(retriable_client.instance_variable_get(:@timeout)).to be == :timeout
      expect(retriable_client.instance_variable_get(:@interval)).to be == :interval
    end
  end

  it '#get' do
    expect(retriable_client).to receive(:request).with(request, :get, {}).and_return []

    expect(retriable_client.get(request, {})).to be_truthy
  end

  it '#post' do
    expect(retriable_client).to receive(:request).with(request, :post, {}).and_return []

    expect(retriable_client.post(request, {})).to be_truthy
  end

  describe '#request' do
    let(:dupped_client) { retriable_client.client }
    let(:retriable_error) { Errno::ECONNREFUSED }

    before do
      expect(dupped_client).to receive(:dup).and_return(dupped_client)
    end

    it 'retries several times' do
      expect(dupped_client).to receive(:send).exactly(3).times.and_raise retriable_error

      expect do
        retriable_client.send(:request, request, :post, {:retries => 3})
      end.to raise_error RunLoop::HTTP::Error
    end

    it 'respects a timeout' do
      expect(dupped_client).to receive(:send).exactly(:once) do
        sleep 0.01
        raise retriable_error
      end

      expect do
        retriable_client.send(:request, request, :post, {:timeout => 0.01})
      end.to raise_error RunLoop::HTTP::Error
    end

    it 'raises the last error' do
      expect(dupped_client).to receive(:send).at_least(:once).and_raise retriable_error

      expect do
        retriable_client.send(:request, request, :post)
      end.to raise_error(RunLoop::HTTP::Error, retriable_error.new.message)
    end
  end
end

