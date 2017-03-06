describe RunLoop::Xcode do

  let(:xcode) { RunLoop::Xcode.new }

  it '#xcode_select_path' do
    path = xcode.send(:xcode_select_path)
    expect(Dir.exist?(path)).to be_truthy
    expect(path[/Contents\/Developer/, 0]).to be_truthy
  end
end
