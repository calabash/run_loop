describe RunLoop::HTTP::Server do
  let(:endpoint) {:endpoint}

  it ".new" do
    server = RunLoop::HTTP::Server.new(endpoint)
    expect(server.instance_variable_get(:@endpoint)).to be == endpoint
    expect(server.endpoint).to be == endpoint
  end
end

