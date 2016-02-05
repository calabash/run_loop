
describe RunLoop::Strings do

  let(:app_path) { Resources.shared.app_bundle_path }
  let(:app) { RunLoop::App.new(app_path) }
  let(:app_executable) { File.join(app.path, app.executable_name) }
  let(:cal_app_path) { Resources.shared.cal_app_bundle_path }
  let(:cal_app) { RunLoop::App.new(cal_app_path) }
  let(:cal_executable) { File.join(cal_app_path, cal_app.executable_name) }
  let(:dylib) { Resources.shared.sim_dylib_path }

  describe "#server_version" do
    it "linked with calabash" do
      actual = RunLoop::Strings.new(cal_executable).server_version
      expect(actual).to be_a_kind_of(RunLoop::Version)
      ap actual
    end

    it "not linked with calabash" do
      expect(RunLoop::Strings.new(app_executable).server_version).to be == nil
    end

    it "dylib" do
      actual = RunLoop::Strings.new(dylib).server_version
      expect(actual).to be_a_kind_of(RunLoop::Version)
      ap actual
    end
  end
end

