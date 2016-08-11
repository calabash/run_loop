
describe RunLoop::Otool do

  let(:path) { Resources.shared.app_bundle_path }
  let(:app) { RunLoop::App.new(path) }
  let(:executable) { File.join(app.path, app.executable_name) }
  let(:info_plist) { app.info_plist_path }
  let(:dylib) { Resources.shared.sim_dylib_path }

  context "#executable?" do
    it "works with the active Xcode" do
      xcode = RunLoop::Xcode.new
      expect(RunLoop::Otool.new(xcode).executable?(executable)).to be_truthy
      expect(RunLoop::Otool.new(xcode).executable?(info_plist)).to be_falsey
      expect(RunLoop::Otool.new(xcode).executable?(dylib)).to be_truthy
    end

    context "other Xcode versions" do
      xcode_installs = Resources.shared.alt_xcode_details_hash
      if xcode_installs.empty?
        it 'no alternative versions of Xcode found' do
          expect(true).to be == true
        end
      else
        xcode_installs.each do |xcode_details|
          it "#{xcode_details[:path]} - #{xcode_details[:version]}" do
            Resources.shared.with_developer_dir(xcode_details[:path]) do
              xcode = RunLoop::Xcode.new
              expect(RunLoop::Otool.new(xcode).executable?(executable)).to be_truthy
              expect(RunLoop::Otool.new(xcode).executable?(info_plist)).to be_falsey
              expect(RunLoop::Otool.new(xcode).executable?(dylib)).to be_truthy
            end
          end
        end
      end
    end
  end
end

