describe RunLoop::Environment do

  let(:environment) { RunLoop::Environment.new }

  context '.user_id' do
  subject { RunLoop::Environment.uid }
    it {
      is_expected.not_to be nil
      is_expected.to be_a_kind_of(Integer)
    }

  end
end
