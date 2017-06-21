
describe RunLoop::Codesign do
  let(:distribution) { Resources.shared.wetap_bundle }
  let(:developer) do
    ipa = RunLoop::Ipa.new(Resources.shared.ipa_path)
    ipa.send(:app).send(:path)
  end

  let(:unsigned) { Resources.shared.unsigned_app_bundle_path }

  describe ".distribution?" do
    it "true" do
      expect(RunLoop::Codesign.distribution?(distribution)).to be_truthy
    end

    it "false" do
      expect(RunLoop::Codesign.distribution?(developer)).to be_falsey
    end
  end

  describe ".developer?" do
    it "true" do
      expect(RunLoop::Codesign.developer?(developer)).to be_truthy
    end

    it "false" do
      expect(RunLoop::Codesign.developer?(distribution)).to be_falsey
    end
  end

  describe ".signed?" do
    it "true" do
      expect(RunLoop::Codesign.signed?(developer)).to be_truthy
      expect(RunLoop::Codesign.signed?(distribution)).to be_truthy
    end

    it "false" do
      expect(RunLoop::Codesign.signed?(unsigned)).to be_falsey
    end
  end
end

