
describe RunLoop::DetectAUT::Detect do
  let(:app) { RunLoop::App.new(Resources.shared.cal_app_bundle_path) }
  let(:obj) { RunLoop::DetectAUT::Detect.new }

  describe "#simulator" do
    it "respects the APP variable" do
      expect(RunLoop::Environment).to receive(:path_to_app_bundle).and_return(app.path)

      actual = obj.app_for_simulator
      expect(actual.path).to be == app.path
    end

    describe "standalone project" do
      let(:local_dir) { File.expand_path("./") }
      let(:search_dirs) { [local_dir] }

      before do
        allow(RunLoop::Environment).to receive(:path_to_app_bundle).and_return(nil)
        allow(obj).to receive(:xcode_project?).and_return(false)
        allow(obj).to receive(:xamarin_project?).and_return(false)
      end

      it "finds an app by recursively searching down from the local directory" do
        apps = [app, app.dup, app.dup]
        expect(obj).to receive(:candidate_apps).with(local_dir).and_return(apps)
        expect(obj).to receive(:select_most_recent_app).with(apps).and_return(app)

        expect(obj.app_for_simulator).to be == app
      end

      it "it does not find any apps" do
        expect(obj).to receive(:candidate_apps).with(local_dir).and_return([])

        expect do
          obj.app_for_simulator
        end.to raise_error RunLoop::NoSimulatorAppFoundError
      end
    end

    describe "xamarin project" do
      let(:search_dirs) { ["path/a"] }

      before do
        allow(RunLoop::Environment).to receive(:path_to_app_bundle).and_return(nil)
        allow(obj).to receive(:xcode_project?).and_return(false)
        allow(obj).to receive(:xamarin_project?).and_return(true)
      end

      it "found apps" do
        apps = [app, app.dup, app.dup]
        expect(obj).to receive(:solution_directory).and_return(search_dirs.first)
        expect(obj).to receive(:candidate_apps).with(search_dirs.first).and_return(apps)
        expect(obj).to receive(:select_most_recent_app).with(apps).and_return(app)

        expect(obj.app_for_simulator).to be == app
      end

      it "found no apps" do
        expect(obj).to receive(:solution_directory).and_return(search_dirs.first)
        expect(obj).to receive(:candidate_apps).with(search_dirs.first).and_return([])
        expect(obj).to receive(:raise_no_simulator_app_found).with(search_dirs).and_call_original

        expect do
          obj.app_for_simulator
        end.to raise_error RunLoop::NoSimulatorAppFoundError
      end
    end

    describe "xcode project" do
      let(:search_dirs) { ["path/a", "path/b", "path/c"] }

      before do
        allow(RunLoop::Environment).to receive(:path_to_app_bundle).and_return(nil)
        allow(obj).to receive(:xcode_project?).and_return(true)
        allow(obj).to receive(:xamarin_project?).and_return(false)
      end

      it "found apps" do
        apps = [app, app.dup, app.dup]
        expect(obj).to receive(:detect_xcode_apps).and_return([apps, search_dirs])
        expect(obj).to receive(:select_most_recent_app).with(apps).and_return(app)

        expect(obj.app_for_simulator).to be == app
      end

      describe "found no apps" do
        it "found an app by recursively searching down from the local directory" do
          apps = [app]
          expect(obj).to receive(:detect_xcode_apps).and_return([[], search_dirs])
          expect(obj).to receive(:candidate_apps).with(File.expand_path("./")).and_return(apps)
          expect(obj).to receive(:select_most_recent_app).with(apps).and_return(app)

          expect(obj.app_for_simulator).to be == app
        end

        it "did not find any apps in DerivedData or by search recursively down from the directory" do
          expect(obj).to receive(:detect_xcode_apps).and_return([[], search_dirs])
          local_path = File.expand_path("./")
          search_dirs << local_path
          expect(obj).to receive(:candidate_apps).with(local_path).and_return([])
          expect(obj).to receive(:raise_no_simulator_app_found).with(search_dirs).and_call_original

          expect do
            obj.app_for_simulator
          end.to raise_error RunLoop::NoSimulatorAppFoundError
        end
      end
    end
  end

  it "#select_most_recent_app" do
    t0 = Time.now
    t1 = t0 - 1
    t2 = t0 - 2
    allow(obj).to receive(:mtime).with("a").and_return(t0)
    allow(obj).to receive(:mtime).with("b").and_return(t1)
    allow(obj).to receive(:mtime).with("c").and_return(t2)

    apps = ["a", "b", "c"].shuffle

    expect(obj.select_most_recent_app(apps)).to be == "a"
  end

  describe "#app_or_nil" do
    let(:path) { app.path }

    before do
      allow(obj).to receive(:app_with_bundle).and_return(app)
    end

    it "true" do
       expect(obj.app_or_nil(path)).to be_truthy
    end

    describe "false" do
      it "not a valid app bundle" do
        expect(RunLoop::App).to receive(:valid?).with(path).and_return(false)

        expect(obj.app_or_nil(path)).to be == nil
      end

      it "not a simulator app" do
        expect(app).to receive(:simulator?).and_return(false)

        expect(obj.app_or_nil(path)).to be == nil
      end

      it "not linked with Calabash" do
        expect(app).to receive(:simulator?).and_return(true)
        expect(app).to receive(:calabash_server_version).and_return(nil)

        expect(obj.app_or_nil(path)).to be == nil
      end
    end
  end

  it "#mtime" do
    expect(app).to receive(:path).and_return("path/to")
    expect(app).to receive(:executable_name).and_return("binary")
    path = "path/to/binary"
    expect(File).to receive(:mtime).with(path)

    obj.mtime(app)
  end
end
