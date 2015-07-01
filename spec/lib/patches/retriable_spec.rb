describe RunLoop::RetryOpts do

  describe '.tries_and_intervals' do
    it 'when version < 2.0' do
      stub_const('Retriable::VERSION', '1.3.3.1')
      actual = RunLoop::RetryOpts.tries_and_interval(3, 4)
      expect(actual).to be == {:tries => 3,
                               :interval => 4}
    end

    it 'when version >= 2.0' do
      stub_const('Retriable::VERSION', '2.0.2')
      actual = RunLoop::RetryOpts.tries_and_interval(3, 4)
      expect(actual.count).to be == 1
      expect(actual[:intervals].count).to be == 3
      expect(actual[:intervals].all? { |elm| elm == 4 }).to be == true
    end

    describe 'does not all some options' do
      let(:retry_module) { RunLoop::RetryOpts }
      it ':tries is not allowed' do
        expect {
          retry_module.tries_and_interval(3, 4, {:tries => 3})
        }.to raise_error(RuntimeError)
      end

      it ':interval is not allowed' do
        expect {
          retry_module.tries_and_interval(3, 4, {:interval => 3})
        }.to raise_error(RuntimeError)
      end

      it ':intervals is not allowed' do
        expect {
          retry_module.tries_and_interval(3, 4, {:intervals => 3})
        }.to raise_error(RuntimeError)
      end
    end

    it 'other options are allowed' do
      stub_const('Retriable::VERSION', '1.3.3.1')
      other_options = {:some_other_key => 'a'}
      actual = RunLoop::RetryOpts.tries_and_interval(3, 4, other_options)
      expect(actual).to be == {:tries => 3,
                               :interval => 4,
                               :some_other_key => 'a'}

    end
  end
end
