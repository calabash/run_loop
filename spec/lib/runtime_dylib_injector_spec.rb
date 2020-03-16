
describe RunLoop::RuntimeDylibInjector do

  let(:workspace) { File.join(Resources.shared.resources_dir, "dylib-injection") }

  before do
    FileUtils.rm_rf(workspace)
    FileUtils.mkdir_p(workspace)
  end

  context ".is_calabash_dylib?" do
    it "returns true if executable name matches calabash dylib pattern" do
      actual = described_class.is_calabash_dylib?("path/to/libCalabashFAT.dylib")
      expect(actual).to be == true

      actual = described_class.is_calabash_dylib?("path/to/libCalabashSim.dylib")
      expect(actual).to be == true

      actual = described_class.is_calabash_dylib?("path/to/libCalabashARM.dylib")
      expect(actual).to be == true

      actual = described_class.is_calabash_dylib?("path/to/libCalabash.dylib")
      expect(actual).to be == true
    end

    it "returns false if executable name does not match calabash dylib pattern" do
      actual = described_class.is_calabash_dylib?("path/to/libCalabashFAT.a")
      expect(actual).to be == false

      actual = described_class.is_calabash_dylib?("path/to/another.dylib")
      expect(actual).to be == false

      actual = described_class.is_calabash_dylib?("path/to/calabash.framework")
      expect(actual).to be == false
    end
  end

  context ".dylib_from_env" do
    let(:path) { "/path/to/libCalabashARM.dylib" }

    it "returns nil if INJECT_CALABASH_DYLIB is not defined" do
      expect(RunLoop::Environment).to receive(:inject_calabash_dylib).and_return(nil)

      expect(described_class.dylib_from_env).to be == nil
    end

    it "does not raise an error if the INJECT_CALABASH_DYLIB exists" do
      expect(RunLoop::Environment).to receive(:inject_calabash_dylib).and_return(path)
      expect(File).to receive(:exist?).and_return(true)

      expect(described_class.dylib_from_env).to be == path
    end

    it "raises an error if the file indicated by INJECT_CALABASH_DYLIB does not exist" do
      expect(RunLoop::Environment).to receive(:inject_calabash_dylib).and_return(path)
      expect(File).to receive(:exist?).and_return(false)

      expect do
        described_class.dylib_from_env
      end.to raise_error(RuntimeError, /INJECT_CALABASH_DYLIB is set, but file does not exist/)
    end
  end

  context "Apps for Simulators" do
    let(:app) do
      path = File.join(workspace, "CalSmoke.app")
      FileUtils.cp_r(Resources.shared.app_bundle_path, path)
      RunLoop::App.new(path)
    end

    let(:aut_env) { {"A" => "1", "B" => "2"} }

    context ".new" do
      it "sets @app and @aut_env" do
        injector = RunLoop::RuntimeDylibInjector.new(app, aut_env)

        expect(injector.send(:app)).to be == app
        expect(injector.instance_variable_get(:@app)).to be == app

        expect(injector.send(:aut_env)).to be == aut_env
        expect(injector.instance_variable_get(:@aut_env)).to be == aut_env
      end
    end
  end

  context "Shared Behaviors" do
    let(:app) do
      path = File.join(workspace, "CalSmoke.app")
      FileUtils.cp_r(Resources.shared.app_bundle_path, path)
      RunLoop::App.new(path)
    end
    let(:aut_env) { {"A" => "1", "B" => "2"} }
    let(:injector) { RunLoop::RuntimeDylibInjector.new(app, aut_env) }

    context "#append_dylib_insert_libraries!" do
      it "destructively sets the value of DYLD_INSERT_LIBRARIES" do
        injector.append_dyld_insert_libraries!("path")

        expect(aut_env["DYLD_INSERT_LIBRARIES"]).to be == "path"
      end

      it "destructively appends the value of DYLD_INSERT_LIBRARIES" do
        aut_env["DYLD_INSERT_LIBRARIES"] = "path0"

        injector.append_dyld_insert_libraries!("path1")

        expect(aut_env["DYLD_INSERT_LIBRARIES"]).to be == "path0:path1"
      end
    end

    context "#set_skip_lpserver_token!" do
      it "destructively sets the value of XTC_SKIP_LPSERVER_TOKEN" do
        expect(app).to receive(:calabash_server_id).and_return("gitsha")

        injector.set_skip_lpserver_token!

        expect(aut_env["XTC_SKIP_LPSERVER_TOKEN"]).to be == "gitsha"
      end
    end

    context "#embedded_calabash_dylib" do
      let(:executables) do
        [
          "My.app/PlugIns/My.appex/My",
          "My.app/Embedded.framework/Versions/Current/Embedded",
          "My.app/Frameworks/libSwiftCore.dylib"
        ]
      end

      before do
        expect(app).to receive(:executables).and_return(executables)
      end

      it "returns correct @executable_path when dylib is in .app/ directory" do
        executables << "My.app/libCalabashFAT.dylib"

        expect(injector.embedded_dylib_exec_path).to be == "@executable_path/libCalabashFAT.dylib"

        # value is memoized - #executables is not called again
        expect(injector.embedded_dylib_exec_path).to be == "@executable_path/libCalabashFAT.dylib"
      end

      it "returns correct @executable_path when dylib is .app/ subdirectory" do
        executables << "My.app/Frameworks/libCalabashARM.dylib"

        expect(injector.embedded_dylib_exec_path).to be == "@executable_path/Frameworks/libCalabashARM.dylib"

        # value is memoized - #executables is not called again
        expect(injector.embedded_dylib_exec_path).to be == "@executable_path/Frameworks/libCalabashARM.dylib"
      end

      it "returns nil if the .app does not contain an embedded calabash dylib" do
        expect(injector.embedded_dylib_exec_path).to be == nil
      end

      it "raises an error if the .app contains more than 1 calabash dylib" do
        executables << "My.app/libCalabashFAT.dylib"
        executables << "My.app/Frameworks/libCalabashARM.dylib"

        expect do
          injector.embedded_dylib_exec_path
        end.to raise_error(RuntimeError, /App contains more than one Calabash dylib/)
      end
    end

    context "#import_dylib_into_app!" do
      let(:dylib_path) { Resources.shared.sim_dylib_path }
      it "copies dylib into .app, sets @embedded_dylib_exec_path, and modifies @aut_env" do
        actual = injector.import_dylib_into_app!(dylib_path)
        expected = "@executable_path/libCalabashDynSim.dylib"

        expect(actual).to be == expected
        expect(injector.send(:embedded_dylib_exec_path)).to be == expected
        expect(injector.send(:aut_env)["DYLD_INSERT_LIBRARIES"]).to be == expected
      end
    end
  end
end