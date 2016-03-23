
describe RunLoop::XCUITest do

  let(:bundle_id) { "com.apple.Preferences" }
  let(:device) { Resources.shared.default_simulator }
  let(:xcuitest) { RunLoop::XCUITest.new(bundle_id, device) }

  it ".new" do
    expect(xcuitest.instance_variable_get(:@bundle_id)).to be == bundle_id
    expect(xcuitest.instance_variable_get(:@device)).to be == device
  end

  describe ".workspace" do
    it "raises an error if CBXWS is not defined" do
      expect(RunLoop::Environment).to receive(:cbxws).and_return(nil)

      expect do
        RunLoop::XCUITest.workspace
      end.to raise_error RuntimeError, /TODO: figure out how to distribute the CBX-Runner/
    end

    it "returns the path to the CBXDriver.xcworkspace" do
      path = "path/to/CBXDriver.xcworkspace"
      expect(RunLoop::Environment).to receive(:cbxws).and_return(path)

      expect(RunLoop::XCUITest.workspace).to be == path
    end
  end

  describe "#url" do
    it "uses 127.0.0.1 for simulator targets" do
      expect(device).to receive(:simulator?).at_least(:once).and_return(true)

      actual = xcuitest.send(:url)
      expected = "http://127.0.0.1:27753"
      expect(actual).to be == expected
      expect(xcuitest.instance_variable_get(:@url)).to be == expected
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

