describe RunLoop::Simctl::Plists do

  it 'has a constant that points to plist dir' do
    dir = RunLoop::Simctl::Plists::SIMCTL_PLIST_DIR
    expect(Dir.exist?(dir)).to be_truthy
  end

  it 'returns uia plist path' do
    expect(File.exist?(RunLoop::Simctl::Plists.uia_automation_plist)).to be_truthy
  end

  it 'returns uia plugin plist path' do
    expect(File.exist?(RunLoop::Simctl::Plists.uia_automation_plugin_plist)).to be_truthy
  end

end
