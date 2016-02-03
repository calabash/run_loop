
describe RunLoop::App do

  let(:app_path) { Resources.shared.app_bundle_path }
  let(:app) { RunLoop::App.new(app_path) }

  let(:cal_path) { Resources.shared.cal_app_bundle_path }
  let(:cal_app) { RunLoop::App.new(cal_path) }

  it "#info_plist_path" do
    actual = app.info_plist_path
    expected = File.join(app_path, "Info.plist")

    expect(actual).to be == expected
  end

  it "#bundle_identifier" do
    expect(app.bundle_identifier).to be == "sh.calaba.CalSmoke"
    expect(cal_app.bundle_identifier).to be == "sh.calaba.CalSmoke-cal"
  end

  it "#executable_name" do
    expect(app.executable_name).to be == "CalSmoke"
    expect(cal_app.executable_name).to be == "CalSmoke-cal"
  end

  it "#calabash_server_version" do
    expect(app.calabash_server_version).to be == nil
    expect(cal_app.calabash_server_version).to be_a_kind_of(RunLoop::Version)
  end

  it "#sha1" do
    expect(app.sha1).to be_truthy
  end
end

