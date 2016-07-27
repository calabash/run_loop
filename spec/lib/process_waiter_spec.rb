describe RunLoop::ProcessWaiter do

  before(:each) do
    allow(RunLoop::Environment).to receive(:debug?).and_return true
  end

  context '.new' do
    describe 'sets the process name' do
      subject { RunLoop::ProcessWaiter.new('process').process_name }
      it { is_expected.to be ==  'process' }
    end

    describe '@options' do
      subject {
        RunLoop::ProcessWaiter.new('process', options).instance_variable_get(:@options)
      }

      describe 'defaults when no options are passed' do
        let(:options) { {} }
        it { is_expected.to be == RunLoop::ProcessWaiter::DEFAULT_OPTIONS }
      end

      describe 'merges when options are passed' do
        let(:options) { {:timeout => 5} }
        let(:expected) { RunLoop::ProcessWaiter::DEFAULT_OPTIONS.merge(options) }
        it { is_expected.to be == expected }
      end
    end
  end

  context '#pids' do
    subject { RunLoop::ProcessWaiter.new(name).pids }

    describe 'returns empty array when no process exists' do
      let(:name) { 'no-such-process' }
      it { is_expected.to be == [] }
    end

    describe 'returns non-empty arry of Integers' do
      let(:name) { "Finder" }
      it {
        is_expected.not_to be_empty
        expect(subject.first).to be_a Integer
      }
    end
  end

  context '#running_process?' do
    subject { RunLoop::ProcessWaiter.new(name).running_process? }
    describe 'false when no processes are found' do
      let(:name) { 'no-such-process' }
      it { is_expected.to be_falsey }
    end

    describe 'returns non-empty arry of Integers' do
      let(:name) { "Finder" }
      it { is_expected.to be_truthy }
    end
  end
end
