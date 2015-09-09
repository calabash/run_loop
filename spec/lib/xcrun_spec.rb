describe RunLoop::Xcrun do

  let(:xcrun) { RunLoop::Xcrun.new }

  describe '#exec' do
    it 'raises an error if arg is not an Array' do
       expect do
         xcrun.exec('simctl list devices')
       end.to raise_error ArgumentError, /Expected args/
    end
  end
end
