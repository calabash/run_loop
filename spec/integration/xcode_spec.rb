describe RunLoop::Xcode do

  let(:xcode) { RunLoop::Xcode.new }

  it '#version' do
    stdout = %q(
Xcode 7.0.1
Build version 7A192o
)
    yielded = [StringIO.new(stdout), StringIO.new(''), nil]
    expect(xcode).to receive(:execute_command).with(['-version']).and_yield(*yielded)

    expected = RunLoop::Version.new('7.0.1')
    expect(xcode.version).to be == expected
    expect(xcode.instance_variable_get(:@xcode_version)).to be == expected

    #Testing memoization
    expect(xcode.version).to be == expected
  end
end
