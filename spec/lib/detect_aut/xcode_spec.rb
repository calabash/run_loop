describe RunLoop::DetectAUT::Xcode do

  let(:obj) do
    Class.new do
      include RunLoop::DetectAUT::Errors
      include RunLoop::DetectAUT::Xcode

      # defined in detect_aut/app.rb
      def candidate_apps(_)
        ;
      end
    end.new
  end

  describe "#xcode_project?" do
    it "true" do
      expect(obj).to receive(:xcodeproj).and_return("path/to/xcodeproj")

      expect(obj.xcode_project?).to be_truthy
    end

    it "false" do
      expect(obj).to receive(:xcodeproj).and_return(nil)

      expect(obj.xcode_project?).to be_falsey
    end
  end

  describe "#xcodeproj" do
    let(:path) { "path/to/MyApp.xcodeproj" }

    describe "XCODEPROJ defined" do

      before do
        expect(RunLoop::Environment).to receive(:xcodeproj).and_return(path)
      end

      it "raises error if path does not exist" do
        expect(File).to receive(:directory?).with(path).and_return(false)

        expect do
          obj.xcodeproj
        end.to raise_error RunLoop::XcodeprojMissingError
      end

      it "XCODEPROJ if defined and exists" do
        expect(File).to receive(:directory?).with(path).and_return(true)

        expect(obj.xcodeproj).to be == path
      end
    end

    describe "XCODEPROJ not defined" do

      before do
        allow(RunLoop::Environment).to receive(:xcodeproj).and_return(nil)
      end

      it "returns nil if no projects are found" do
        expect(obj).to receive(:find_xcodeproj).and_return([])

        expect(obj.xcodeproj).to be == nil
      end

      it "returns the .xcodeproj if exactly 1 is found" do
        expect(obj).to receive(:find_xcodeproj).and_return([path])

        expect(obj.xcodeproj).to be == path
      end

      it "raises error if more than 1 xcodeproj is detected" do
        expect(obj).to receive(:find_xcodeproj).and_return([path, path])

        expect do
          obj.xcodeproj
        end.to raise_error RunLoop::MultipleXcodeprojError
      end
    end
  end

  it "#find_xcodeproj" do
    glob = "#{Dir.pwd}/**/*.xcodeproj"

    glob_result = [
      "path/to/ProjectA.xcodeproj",
      "path/to/ProjectB.xcodeproj",
      "path/to/ProjectC.xcodeproj"
    ]

    expect(Dir).to receive(:glob).with(glob).and_return(glob_result)

    expect(obj).to receive(:ignore_xcodeproj?).with(glob_result[0]).and_return(true)
    expect(obj).to receive(:ignore_xcodeproj?).with(glob_result[1]).and_return(false)
    expect(obj).to receive(:ignore_xcodeproj?).with(glob_result[2]).and_return(true)

    expect(obj.find_xcodeproj).to be == ["path/to/ProjectB.xcodeproj"]
  end

  describe "#ignore_xcodeproj?" do
    it "ignores CordovaLib" do
      path = "path/CordovaLib/Cordova.xcodeproj"
      expect(obj.ignore_xcodeproj?(path)).to be_truthy
    end

    it "ignores Pods" do
      path = "path/Pods/Pods.xcodeproj"
      expect(obj.ignore_xcodeproj?(path)).to be_truthy
    end

    it "ignores Carthage" do
      path = "path/Carthage/AFNetworking/AFNetworking.xcodeproj"
      expect(obj.ignore_xcodeproj?(path)).to be_truthy
    end

    it "ignores UrbanAirship" do
      path = "path/AirshipKit.xcodeproj"
      expect(obj.ignore_xcodeproj?(path)).to be_truthy

      path = "path/AirshipKitSource.xcodeproj"
      expect(obj.ignore_xcodeproj?(path)).to be_truthy

      path = "path/AirshipLib.xcodeproj"
      expect(obj.ignore_xcodeproj?(path)).to be_truthy
    end

    it "ignores Google iOS SDK" do
      path = "path/google-plus-ios-sdk-1.7.1/SampleCode/GooglePlusSample.xcodeproj"
      expect(obj.ignore_xcodeproj?(path)).to be_truthy
    end

    it "returns false" do
      path = "path/ProjectA.xcodeproj"
      expect(obj.ignore_xcodeproj?(path)).to be_falsey
    end
  end

  describe "#detect_xcode_apps" do
    let(:derived) { ["path/a", "path/b", "path/c"] }
    let(:prefs) { "path/prefs" }

    before do
      allow(Dir).to receive(:pwd).and_return("./")
    end

    it "only derived data and local directory" do
      expect(obj).to receive(:candidate_apps).with(derived[0]).and_return(["a"])
      expect(obj).to receive(:candidate_apps).with(derived[1]).and_return(["b"])
      expect(obj).to receive(:candidate_apps).with(derived[2]).and_return(["c"])
      expect(obj).to receive(:candidate_apps).with("./").and_return(["d"])
      expect(obj).to receive(:derived_data_search_dirs).and_return(derived)
      expect(obj).to receive(:xcode_preferences_search_dir).and_return(nil)

      e_apps = ["a", "b", "c", "d"]
      e_search_dirs = derived +  ["./"]

      a_apps, a_search_dirs = obj.detect_xcode_apps
      expect(a_apps).to be == e_apps
      expect(a_search_dirs).to be == e_search_dirs
    end

    it "only xcode preferences dir and local directory" do
      expect(obj).to receive(:derived_data_search_dirs).and_return([])
      expect(obj).to receive(:xcode_preferences_search_dir).and_return(prefs)
      expect(obj).to receive(:candidate_apps).with(prefs).and_return(["d"])
      expect(obj).to receive(:candidate_apps).with("./").and_return(["e"])

      e_apps = ["d", "e"]
      e_search_dirs = [prefs] + ["./"]

      a_apps, a_search_dirs = obj.detect_xcode_apps
      expect(a_apps).to be == e_apps
      expect(a_search_dirs).to be == e_search_dirs
    end

    it "both" do
      expect(obj).to receive(:derived_data_search_dirs).and_return(derived)
      expect(obj).to receive(:xcode_preferences_search_dir).and_return(prefs)
      expect(obj).to receive(:candidate_apps).with(derived[0]).and_return(["a"])
      expect(obj).to receive(:candidate_apps).with(derived[1]).and_return(["b"])
      expect(obj).to receive(:candidate_apps).with(derived[2]).and_return(["c"])
      expect(obj).to receive(:candidate_apps).with(prefs).and_return(["d"])
      expect(obj).to receive(:candidate_apps).with("./").and_return(["e"])

      e_apps = ["a", "b", "c", "d", "e"]
      e_search_dirs = derived.dup + [prefs] + ["./"]

      a_apps, a_search_dirs = obj.detect_xcode_apps
      expect(a_apps).to be == e_apps
      expect(a_search_dirs).to be == e_search_dirs
    end
  end

  describe "searching for DerivedData directories" do
    let(:xcodeproj) { "path/to/MyApp.xcodeproj" }
    let(:derived_data) { "path/to/derived_data" }
    let(:plist) { "path/to/some.plist" }
    let(:pbuddy) { RunLoop::PlistBuddy.new }
    let(:shared) { RunLoop::DetectAUT::Xcode::PLIST_KEYS[:shared_build] }
    let(:custom) { RunLoop::DetectAUT::Xcode::PLIST_KEYS[:custom_build] }
    let(:workspace) { RunLoop::DetectAUT::Xcode::PLIST_KEYS[:workspace] }

    before do
      allow(obj).to receive(:xcode_preferences_plist).and_return(plist)
      allow(obj).to receive(:pbuddy).and_return(pbuddy)
      allow(obj).to receive(:derived_data).and_return(derived_data)
    end

    describe "#xcode_preferences_search_dir" do
      it "shared build" do
        expect(pbuddy).to receive(:plist_read).with(shared, plist).once.and_return("shared")
        expect(pbuddy).to receive(:plist_read).with(custom, plist).once.and_return("custom")

        expected = File.join(derived_data, "shared", "Products")
        expect(obj.xcode_preferences_search_dir).to be == expected
      end

      it "custom build" do
        expect(obj).to receive(:xcodeproj).and_return(xcodeproj)
        expect(pbuddy).to receive(:plist_read).with(shared, plist).once.and_return(nil)
        expect(pbuddy).to receive(:plist_read).with(custom, plist).once.and_return("custom")

        expected = File.join("path/to", "custom")
        expect(obj.xcode_preferences_search_dir).to be == expected
      end

      it "neither" do
        expect(pbuddy).to receive(:plist_read).with(shared, plist).once.and_return(nil)
        expect(pbuddy).to receive(:plist_read).with(custom, plist).once.and_return(nil)

        expect(obj.xcode_preferences_search_dir).to be == nil
      end
    end

    describe "#derived_data_search_dirs" do
      let(:base_dir) { File.join("spec", "resources", "detect_aut") }
      let(:dd_path) { File.join(base_dir, "DerivedData") }
      let(:projects) { File.join(base_dir, "Projects") }
      let(:project_a) { File.join(projects, "ProjectA", "ProjectA.xcodeproj") }
      let(:project_b) { File.join(projects, "ProjectB", "ProjectB.xcodeproj") }
      let(:workspace_b) { File.join(projects, "ProjectB", "ProjectB.xcworkspace") }
      let(:project_c) { File.join(projects, "ProjectC", "ProjectC", "ProjectC.xcodeproj") }
      let(:workspace_c) { File.join(projects, "ProjectC", "ProjectC.xcworkspace") }

      before do
        allow(obj).to receive(:derived_data).and_return(dd_path)
      end

      describe "exact match" do
        it "ProjectA" do
          expect(obj).to receive(:xcodeproj).and_return(project_a)
          actual = obj.derived_data_search_dirs

          expected = [
                "spec/resources/detect_aut/DerivedData/ProjectA-00",
                "spec/resources/detect_aut/DerivedData/ProjectA-01",
                "spec/resources/detect_aut/DerivedData/ProjectA-02"
          ].sort

          expect(actual.sort).to be == expected
        end

        it "ProjectB" do
          expect(obj).to receive(:xcodeproj).and_return(project_b)
          actual = obj.derived_data_search_dirs

          expected =[
                "spec/resources/detect_aut/DerivedData/ProjectB-00-project",
                "spec/resources/detect_aut/DerivedData/ProjectB-00-workspace",
                "spec/resources/detect_aut/DerivedData/ProjectB-01-project",
                "spec/resources/detect_aut/DerivedData/ProjectB-01-workspace",
                "spec/resources/detect_aut/DerivedData/ProjectB-02-project",
                "spec/resources/detect_aut/DerivedData/ProjectB-02-workspace"
          ].sort

          expect(actual.sort).to be == expected
        end

        it "ProjectC" do
          expect(obj).to receive(:xcodeproj).and_return(project_c)
          actual = obj.derived_data_search_dirs

          expected =[
                "spec/resources/detect_aut/DerivedData/ProjectC-00-project",
                "spec/resources/detect_aut/DerivedData/ProjectC-00-workspace",
                "spec/resources/detect_aut/DerivedData/ProjectC-01-project",
                "spec/resources/detect_aut/DerivedData/ProjectC-01-workspace",
                "spec/resources/detect_aut/DerivedData/ProjectC-02-project",
                "spec/resources/detect_aut/DerivedData/ProjectC-02-workspace"
          ].sort

          expect(actual.sort).to be == expected
        end
      end
    end
  end

  describe "#derived_data" do
    it "respects DERIVED_DATA" do
      path = "path/to/derived/data"
      expect(RunLoop::Environment).to receive(:derived_data).and_return(path)

      expect(obj.derived_data).to be == path
    end

    it "returns default directory" do
      expect(RunLoop::Environment).to receive(:derived_data).and_return(nil)

      expected = File.expand_path("~/Library/Developer/Xcode/DerivedData")
      expect(obj.derived_data).to be == expected
    end
  end

  it "#pbuddy" do
    actual = obj.pbuddy
    expect(actual).to be_a_kind_of(RunLoop::PlistBuddy)
    expect(obj.instance_variable_get(:@pbuddy)).to be == actual
  end
end

