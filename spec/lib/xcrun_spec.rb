describe RunLoop::Xcrun do

  let(:xcrun) { RunLoop::Xcrun.new }

  describe '#exec' do
    it 'raises an error if arg is not an Array' do
       expect do
         xcrun.exec('simctl list devices')
       end.to raise_error ArgumentError, /Expected args/
    end

    it 're-raises Timeout::Errors' do
      expect(Open3).to receive(:popen3).with('xcrun', 'instruments').and_raise TimeoutError

      expect do
        xcrun.exec(['instruments'])
      end.to raise_error RunLoop::Xcrun::XcrunError, /'xcrun instruments'/
    end

    it 're-raises StandardError' do
      expect(Open3).to receive(:popen3).and_raise StandardError, 'Raised again!'

      expect do
        xcrun.exec([])
      end.to raise_error RunLoop::Xcrun::XcrunError, /Raised again!/
    end
  end
end
