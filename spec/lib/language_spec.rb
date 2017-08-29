
describe RunLoop::Language do

  let(:device) { RunLoop::Device.new("name", "7.0", "udid") }
  let(:v110) { RunLoop::Version.new("11.0") }
  let(:v100) { RunLoop::Version.new("10.0") }
  let(:v90) { RunLoop::Version.new("9.0") }
  let(:v91) { RunLoop::Version.new("9.1") }
  let(:v80) { RunLoop::Version.new("8.0") }
  let(:v70) { RunLoop::Version.new("7.0") }

  describe ".valid_code_for_device?" do
    it "returns true if code is valid" do
      expect(device).to receive(:version).and_return(v90)

      actual = RunLoop::Language.valid_code_for_device?("en", device)
      expect(actual).to be_truthy
    end

    describe "returns false" do
      it "device iOS is not supported" do
        expect(device).to receive(:version).and_return(v70)

        actual = RunLoop::Language.valid_code_for_device?("en", device)
        expect(actual).to be_falsey
      end

      it "code is not found" do
        expect(device).to receive(:version).and_return(v90)

        actual = RunLoop::Language.valid_code_for_device?("unknown code", device)
        expect(actual).to be_falsey
      end
    end
  end

  describe ".codes_for_device" do

    it "returns an array of lang codes based on the iOS version" do
      expect(device).to receive(:version).and_return(v90)

      langs = RunLoop::Language.codes_for_device(device)
      expect(langs.count).to be == 715
    end

    it "uses the major version" do
      expect(device).to receive(:version).and_return(v90, v91)

      langs90 = RunLoop::Language.codes_for_device(device)
      langs91 = RunLoop::Language.codes_for_device(device)
      expect(langs90.count).to be == langs91.count
    end

    it "supports iOS 11" do
      expect(device).to receive(:version).and_return(v110)

      langs = RunLoop::Language.codes_for_device(device)
      expect(langs.count).to be == 782
    end

    it "supports iOS 10" do
      expect(device).to receive(:version).and_return(v100)

      langs = RunLoop::Language.codes_for_device(device)
      expect(langs.count).to be == 732
    end

    it "supports iOS 9" do
      expect(device).to receive(:version).and_return(v90)

      langs = RunLoop::Language.codes_for_device(device)
      expect(langs.count).to be == 715
    end

    it "supports iOS 8" do
      expect(device).to receive(:version).and_return(v80)

      langs = RunLoop::Language.codes_for_device(device)
      expect(langs.count).to be == 674
    end

    it "returns nil for any other iOS version" do
      allow(device).to receive(:version).and_return(v70)

      expect(RunLoop::Language.codes_for_device(device)).to be_falsey
    end
  end
end

