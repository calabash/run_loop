describe RunLoop::Device do

  subject!(:version) { RunLoop::Version.new('7.1.2') }
  subject(:device) { RunLoop::Device.new('name', version , 'udid') }

  describe '.new' do
    it 'has attr name' do
      expect(device.name).to be == 'name'
    end

    it 'has attr udid' do
      expect(device.udid).to be == 'udid'
    end

    describe 'version attr' do
      it 'has attr version' do
        expect(device.version).to be == version
      end

      it 'can accept a version str' do
        local_device = RunLoop::Device.new('name', '7.1.2', 'udid')
        expect(local_device.version).to be_a RunLoop::Version
        expect(local_device.version).to be == RunLoop::Version.new('7.1.2')
      end
    end
  end
end