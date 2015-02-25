describe RunLoop::Environment do

  let(:environment) { RunLoop::Environment.new }

  context '.user_id' do
  subject { RunLoop::Environment.uid }
    it {
      is_expected.not_to be nil
      is_expected.to be_a_kind_of(Integer)
    }
  end

  describe '.debug?' do
    it "returns true when DEBUG == '1'" do
      stub_env('DEBUG', '1')
      expect(RunLoop::Environment.debug?).to be == true
    end

    it "returns false when DEBUG != '1'" do
      stub_env('DEBUG', 1)
      expect(RunLoop::Environment.debug?).to be == false
    end
  end
end
