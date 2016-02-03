
describe RunLoop::Otool do

  let(:path) { Resources.shared.app_bundle_path }
  let(:app) { RunLoop::App.new(path) }
  let(:executable) { File.join(app.path, app.executable_name) }
  let(:info_plist) { app.info_plist_path }
  let(:dylib) { Resources.shared.sim_dylib_path }

  it "#executable?" do
    expect(RunLoop::Otool.new(executable).executable?).to be_truthy
    expect(RunLoop::Otool.new(info_plist).executable?).to be_falsey
    expect(RunLoop::Otool.new(dylib).executable?).to be_truthy
  end
end

