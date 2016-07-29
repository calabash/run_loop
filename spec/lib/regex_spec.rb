
describe RunLoop::Regex do

  context "VERSION_REGEX" do

    let(:regex) { RunLoop::Regex::VERSION_REGEX }

    it "can detect single digit major" do
      expect("9.0"[regex]).to be == "9.0"
    end

    it "can detect double digit major" do
      expect("10.0"[regex]).to be == "10.0"
    end

    it "can detect single digit minor" do
      expect("10.9"[regex]).to be == "10.9"
    end

    it "can detect double digit minor" do
      expect("10.10"[regex]).to be == "10.10"
    end

    it "can detect single digit patch" do
      expect("10.10.0"[regex]).to be == "10.10.0"
    end

    it "can detect double digit patch" do
      expect("10.10.10"[regex]).to be == "10.10.10"
    end
  end
end
