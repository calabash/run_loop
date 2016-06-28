
describe RunLoop::DetectAUT::Detect do
  let(:app) { RunLoop::App.new(Resources.shared.cal_app_bundle_path) }
  let(:obj) { RunLoop::DetectAUT::Detect.new }

  describe "#app_for_simulator" do
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
        depth = RunLoop::DetectAUT::Detect::DEFAULTS[:search_depth]
        expect(obj).to receive(:solution_directory).and_return(search_dirs.first)
        expect(obj).to receive(:candidate_apps).with(search_dirs.first).and_return([])
        expect(obj).to receive(:raise_no_simulator_app_found).with(search_dirs, depth).and_call_original

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

        it "did not find any apps in DerivedData or by search recursively down from the directory" do
          depth = RunLoop::DetectAUT::Detect::DEFAULTS[:search_depth]
          expect(obj).to receive(:detect_xcode_apps).and_return([[], search_dirs])
          expect(obj).to receive(:raise_no_simulator_app_found).with(search_dirs, depth).and_call_original

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

  describe "#globs_for_app_search" do
    it "array of globs that based on default search depth" do
      defaults = {:search_depth => 5}
      stub_const("RunLoop::DetectAUT::Detect::DEFAULTS", defaults)
      expected_count = RunLoop::DetectAUT::Detect::DEFAULTS[:search_depth]
      expected = [
        "./*.app",
        "./*/*.app",
        "./*/*/*.app",
        "./*/*/*/*.app",
        "./*/*/*/*/*.app"
      ]
      expect(expected.count).to be == expected_count

      actual = obj.send(:globs_for_app_search, "./")
      expect(actual).to be == expected
    end

    it "respects changes to DEFAULTS[:search_depth]" do
      stub_const("RunLoop::DetectAUT::Detect::DEFAULTS",  {search_depth: 2})

      expected_count = RunLoop::DetectAUT::Detect::DEFAULTS[:search_depth]
      expected = [
        "./*.app",
        "./*/*.app",
      ]
      expect(expected.count).to be == expected_count

      actual = obj.send(:globs_for_app_search, "./")
      expect(actual).to be == expected
    end
  end

  describe "detecting the AUT" do
    let(:app_path) { Resources.shared.app_bundle_path }
    let(:app) { RunLoop::App.new(app_path) }
    let(:app_bundle_id) { app.bundle_identifier }

    let(:ipa_path) { Resources.shared.ipa_path }
    let(:ipa) { RunLoop::Ipa.new(ipa_path) }
    let(:ipa_bundle_id) { ipa.bundle_identifier }
    let(:options) do
      {
        :app => app_path,
        :bundle_id => app_bundle_id
      }
    end

    describe ".app_from_options" do
      it ":app" do
        actual = RunLoop::DetectAUT.send(:app_from_options, options)
        expect(actual).to be == options[:app]
      end

      it ":bundle_id" do
        options[:app] = nil
        actual = RunLoop::DetectAUT.send(:app_from_options, options)
        expect(actual).to be == options[:bundle_id]
      end
    end

    describe ".app_from_environment" do
      describe "APP or APP_BUNDLE_PATH" do
        it "is a path to a directory that exists" do
          expect(RunLoop::Environment).to receive(:path_to_app_bundle).and_return(app_path)

          actual = RunLoop::DetectAUT.send(:app_from_environment)
          expect(actual).to be == app_path
        end

        it "is a bundle id" do
          bundle_id = "com.example.MyApp"
          expect(RunLoop::Environment).to receive(:path_to_app_bundle).and_return(bundle_id)

          actual = RunLoop::DetectAUT.send(:app_from_environment)
          expect(actual).to be == bundle_id
        end

        it "is a path to a bundle that does not exist" do
          expect(RunLoop::Environment).to receive(:path_to_app_bundle).and_return(app_path)
          expect(File).to receive(:exist?).with(app_path).and_return(false)

          actual = RunLoop::DetectAUT.send(:app_from_environment)
          expect(actual).to be == File.basename(app_path)
        end
      end

      it "BUNDLE_ID" do
        expect(RunLoop::Environment).to receive(:path_to_app_bundle).and_return(nil)
        expect(RunLoop::Environment).to receive(:bundle_id).and_return(app_bundle_id)

        actual = RunLoop::DetectAUT.send(:app_from_environment)
        expect(actual).to be == app_bundle_id
      end
    end

    # Untestable?
    # describe ".app_from_constant" do
    #   let(:world_with_app) do
    #     Class.new do
    #       APP = Resources.shared.app_bundle_path
    #       def self.app_from_constant
    #         RunLoop::DetectAUT.send(:app_from_constant)
    #       end
    #     end
    #   end
    #
    #   let(:world_with_app_bundle_path) do
    #     Class.new do
    #       APP_BUNDLE_PATH = Resources.shared.app_bundle_path
    #       def self.app_from_constant
    #         RunLoop::DetectAUT.send(:app_from_constant)
    #       end
    #     end
    #   end
    #
    #   after do
    #     if Object.constants.include?(world_with_app)
    #       Object.send(:remove_const, world_with_app)
    #     end
    #
    #     if Object.constants.include?(world_with_app_bundle_path)
    #       Object.send(:remove_const, world_with_app_bundle_path)
    #     end
    #   end
    #
    #   it "APP and APP_BUNDLE_PATH not defined" do
    #     actual = RunLoop::DetectAUT.send(:app_from_constant)
    #     expect(actual).to be == nil
    #   end
    #
    #   it "APP defined and non-nil" do
    #     actual = world_with_app.send(:app_from_constant)
    #     expect(actual).to be == app_path
    #   end
    #
    #   it "APP_BUNDLE_PATH defined and non-nil" do
    #     actual = world_with_app_bundle_path.send(:app_from_constant)
    #     expect(actual).to be == app_path
    #   end
    # end

    describe ".app_from_opts_or_env_or_constant" do
      it "app is defined in options" do
        expect(RunLoop::DetectAUT).to receive(:app_from_options).and_return(app)

        actual = RunLoop::DetectAUT.send(:app_from_opts_or_env_or_constant, options)
        expect(actual).to be == app
      end

      it "app is defined in environment" do
        expect(RunLoop::DetectAUT).to receive(:app_from_options).and_return(nil)
        expect(RunLoop::DetectAUT).to receive(:app_from_environment).and_return(app)

        actual = RunLoop::DetectAUT.send(:app_from_opts_or_env_or_constant, options)
        expect(actual).to be == app
      end

      it "app is defined as constant" do
        expect(RunLoop::DetectAUT).to receive(:app_from_options).and_return(nil)
        expect(RunLoop::DetectAUT).to receive(:app_from_environment).and_return(nil)
        expect(RunLoop::DetectAUT).to receive(:app_from_constant).and_return(app)

        actual = RunLoop::DetectAUT.send(:app_from_opts_or_env_or_constant, options)
        expect(actual).to be == app
      end

      it "app is not defined anywhere" do
        expect(RunLoop::DetectAUT).to receive(:app_from_options).and_return(nil)
        expect(RunLoop::DetectAUT).to receive(:app_from_environment).and_return(nil)
        expect(RunLoop::DetectAUT).to receive(:app_from_constant).and_return(nil)

        actual = RunLoop::DetectAUT.send(:app_from_opts_or_env_or_constant, options)
        expect(actual).to be == nil
      end
    end

    describe ".detect_app" do
      describe "defined some where" do
        it "is an App" do
          expect(RunLoop::DetectAUT).to receive(:app_from_opts_or_env_or_constant).with(options).and_return(app)

          actual = RunLoop::DetectAUT.send(:detect_app, options)
          expect(actual).to be == app
        end

        it "is an Ipa" do
          expect(RunLoop::DetectAUT).to receive(:app_from_opts_or_env_or_constant).with(options).and_return(ipa)

          actual = RunLoop::DetectAUT.send(:detect_app, options)
          expect(actual).to be == ipa
        end

        it "is an app path" do
          expect(RunLoop::DetectAUT).to receive(:app_from_opts_or_env_or_constant).with(options).and_return(app_path)

          actual = RunLoop::DetectAUT.send(:detect_app, options)
          expect(actual).to be_a_kind_of(RunLoop::App)
          expect(actual.bundle_identifier).to be == app.bundle_identifier
        end

        it "is an ipa path" do
          expect(RunLoop::DetectAUT).to receive(:app_from_opts_or_env_or_constant).with(options).and_return(ipa_path)

          actual = RunLoop::DetectAUT.send(:detect_app, options)
          expect(actual).to be_a_kind_of(RunLoop::Ipa)
          expect(actual.bundle_identifier).to be == ipa.bundle_identifier
        end

        it "is a bundle identifier" do
          expect(RunLoop::DetectAUT).to receive(:app_from_opts_or_env_or_constant).with(options).and_return(app_bundle_id)

          actual = RunLoop::DetectAUT.send(:detect_app, options)
          expect(actual).to be == app_bundle_id
        end
      end

      describe "it is not defined" do
        let(:detector) { RunLoop::DetectAUT::Detect.new }

        before do
          allow(RunLoop::DetectAUT).to receive(:detector).and_return(detector)
        end

        it "is auto detected" do
          expect(detector).to receive(:app_for_simulator).twice.and_return(app)

          expect(RunLoop::DetectAUT).to receive(:app_from_opts_or_env_or_constant).with(options).and_return(nil)
          actual = RunLoop::DetectAUT.send(:detect_app, options)
          expect(actual).to be == app

          expect(RunLoop::DetectAUT).to receive(:app_from_opts_or_env_or_constant).with(options).and_return("")
          actual = RunLoop::DetectAUT.send(:detect_app, options)
          expect(actual).to be == app
        end

        it "is not auto detected" do
          expect(RunLoop::DetectAUT).to receive(:app_from_opts_or_env_or_constant).with(options).and_return("")
          expect(detector).to receive(:app_for_simulator).and_raise(RuntimeError)

          expect do
            RunLoop::DetectAUT.send(:detect_app, options)
          end.to raise_error RuntimeError
        end
      end

      describe ".detect_app_under_test" do
        describe "App or Ipa instance" do
          it "App" do
            expect(RunLoop::DetectAUT).to receive(:detect_app).with(options).and_return(app)

            hash = RunLoop::DetectAUT.detect_app_under_test(options)

            expect(hash[:app]).to be == app
            expect(hash[:bundle_id]).to be == app_bundle_id
            expect(hash[:is_ipa]).to be == false
          end

          it "Ipa" do
            expect(RunLoop::DetectAUT).to receive(:detect_app).with(options).and_return(ipa)

            hash = RunLoop::DetectAUT.detect_app_under_test(options)

            expect(hash[:app]).to be == ipa
            expect(hash[:bundle_id]).to be == ipa_bundle_id
            expect(hash[:is_ipa]).to be == true
          end
        end

        it "bundle identifier" do
          expect(RunLoop::DetectAUT).to receive(:detect_app).with(options).and_return(app_bundle_id)

          hash = RunLoop::DetectAUT.detect_app_under_test(options)

          expect(hash[:app]).to be == nil
          expect(hash[:bundle_id]).to be == app_bundle_id
          expect(hash[:is_ipa]).to be == false
        end
      end
    end
  end
end
