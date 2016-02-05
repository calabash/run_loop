
describe RunLoop::XCUITest do

  let(:bundle_id) { "com.apple.Preferences" }
  let(:xcuitest) { RunLoop::XCUITest.new(bundle_id) }

  it ".new" do
    expect(xcuitest.instance_variable_get(:@bundle_id)).to be == bundle_id
  end

  describe ".project" do
    describe "return nil" do
      it "XCUITEST_PROJ is not defined" do
        stub_env({"XCUITEST_PROJ" => nil})

        expect(RunLoop::XCUITest.project).to be == nil
      end

      it "XCUITEST_PROJ is ''" do
        stub_env({"XCUITEST_PROJ" => ""})

        expect(RunLoop::XCUITest.project).to be == nil
      end
    end

    it "returns the path to the xcproj" do
      path = "path/to/xcodeproj"
      stub_env({"XCUITEST_PROJ" => path})

      expect(RunLoop::XCUITest.project).to be == path
    end
  end

  describe "#url" do
    let(:device) { RunLoop::Device.new("denis", "9.0", "udid") }

    it "uses 127.0.0.1 for simulator targets" do
      expect(device).to receive(:simulator?).at_least(:once).and_return(true)
      expect(xcuitest).to receive(:target).and_return(device)

      actual = xcuitest.url
      expected = "http://127.0.0.1:27753"
      expect(actual).to be == expected
    end
  end

  describe "#target" do
    it "raises an error if no device can be found" do
      expect(RunLoop::Device).to receive(:device_with_identifier).and_return(nil)

      expect do
        xcuitest.target
      end.to raise_error RuntimeError, /Could not find a device/
    end

    it "uses the default simulator if DEVICE_TARGET is undefined" do
      expect(RunLoop::Environment).to receive(:device_target).and_return(nil)

      actual = xcuitest.target
      default = RunLoop::Core.default_simulator

      expect(default[/#{actual.name}/, 0]).to be_truthy
    end
  end

  describe "file system" do
    let(:dot_dir) { File.expand_path(File.join("tmp", ".run-loop-xcuitest")) }
    let(:xcuitest_dir) { File.join(dot_dir, "xcuitest") }

    before do
      FileUtils.mkdir_p(dot_dir)
      allow(RunLoop::DotDir).to receive(:directory).and_return(dot_dir)
    end

    describe ".dot_dir" do
      it "creates a directory" do
        FileUtils.rm_rf(dot_dir)

        actual = RunLoop::XCUITest.send(:dot_dir)
        expect(actual).to be == xcuitest_dir
        expect(File.directory?(actual)).to be_truthy
      end

      it "returns a path" do
        FileUtils.mkdir_p(xcuitest_dir)

        actual = RunLoop::XCUITest.send(:dot_dir)
        expect(actual).to be == xcuitest_dir
      end
    end

    describe ".log_file" do
      before do
        FileUtils.mkdir_p(xcuitest_dir)
      end

      let(:path) { File.join(xcuitest_dir, "xcuitest.log") }

      it "creates a file" do
        FileUtils.rm_rf(path)

        expect(RunLoop::XCUITest.log_file).to be == path
        expect(File.exist?(path)).to be_truthy
      end

      it "returns existing file path" do
        FileUtils.touch(path)
        expect(RunLoop::XCUITest.log_file).to be == path
      end
    end
  end
end

