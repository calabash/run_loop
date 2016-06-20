
describe RunLoop::Codesign do

  let(:path) { "/path/to/file" }
  let(:not_signed) { "#{path}: code object is not signed at all" }
  let(:developer) { "Authority=iPhone Developer: Karl Krukow (XXXXXXXXXX)" }
  let(:app_store) { "Authority=Apple iPhone OS Application Signing" }
  let(:distribution) { "Authority=iPhone Distribution: Permissions" }

  describe "path exists" do
    before do
      allow(RunLoop::Codesign).to receive(:expect_path_exists).with(path).and_return(true)
    end

    it ".info" do
      args = ["--display", "--verbose=4", path]
      expect(RunLoop::Codesign).to receive(:run_codesign_command).with(args).and_return("info")

      expect(RunLoop::Codesign.info(path)).to be == "info"
    end

    describe ".signed?" do
      describe "true if object is signed" do
        it "developer" do
          expect(RunLoop::Codesign).to receive(:info).and_return(developer)

          expect(RunLoop::Codesign.signed?(path)).to be_truthy
        end

        it "app store" do
          expect(RunLoop::Codesign).to receive(:info).and_return(app_store)

          expect(RunLoop::Codesign.signed?(path)).to be_truthy
        end

        it "distribution" do
          expect(RunLoop::Codesign).to receive(:info).and_return(distribution)

          expect(RunLoop::Codesign.signed?(path)).to be_truthy
        end
      end

      it "false if object is not signed" do
        expect(RunLoop::Codesign).to receive(:info).and_return(not_signed)

        expect(RunLoop::Codesign.signed?(path)).to be_falsey
      end
    end

    describe ".distribution?" do

      describe "false" do
        it "developer" do
          expect(RunLoop::Codesign).to receive(:info).and_return(developer)

          expect(RunLoop::Codesign.distribution?(path)).to be_falsey
        end

        it "not signed" do
          expect(RunLoop::Codesign).to receive(:info).and_return(not_signed)

          expect(RunLoop::Codesign.distribution?(path)).to be_falsey
        end
      end

      describe "true" do
        it "app store" do
          expect(RunLoop::Codesign).to receive(:info).and_return(app_store)

          expect(RunLoop::Codesign.distribution?(path)).to be_truthy
        end

        it "distribution" do
          expect(RunLoop::Codesign).to receive(:info).and_return(distribution)

          expect(RunLoop::Codesign.distribution?(path)).to be_truthy
        end
      end
    end

    describe ".developer?" do
      describe "false" do
        it "distribution" do
          expect(RunLoop::Codesign).to receive(:info).and_return(distribution)

          expect(RunLoop::Codesign.developer?(path)).to be_falsey
        end

        it "app store" do
          expect(RunLoop::Codesign).to receive(:info).and_return(app_store)

          expect(RunLoop::Codesign.developer?(path)).to be_falsey
        end

        it "not signed" do
          expect(RunLoop::Codesign).to receive(:info).and_return(not_signed)

          expect(RunLoop::Codesign.developer?(path)).to be_falsey
        end
      end

      it "true" do
        expect(RunLoop::Codesign).to receive(:info).and_return(developer)

        expect(RunLoop::Codesign.developer?(path)).to be_truthy
      end
    end
  end

  describe ".run_codesign_command" do
    it "expects an Array argument" do
      expect do
        RunLoop::Codesign.send(:run_codesign_command, "string")
      end.to raise_error ArgumentError, /to be an Array/
    end

    it "calls out to codesign" do
      path = File.expand_path("./tmp/file.txt")
      FileUtils.mkdir_p("./tmp")
      FileUtils.touch(path)
      args = ["--display", "--verbose=4", path]
      actual = RunLoop::Codesign.send(:run_codesign_command, args)
      expected = "tmp/file.txt: code object is not signed at all"
      expect(actual[/#{expected}/, 0]).to be_truthy
    end
  end

  describe ".expect_path_exists" do
    it "raises ArgumentError" do
      expect do
        RunLoop::Codesign.send(:expect_path_exists, path)
      end.to raise_error ArgumentError, /There is no file or directory at path/
    end

    it "does nothing" do
      expect(File).to receive(:exist?).with(path).and_return(true)

      expect do
        RunLoop::Codesign.send(:expect_path_exists, path)
      end.not_to raise_error
    end
  end
end

