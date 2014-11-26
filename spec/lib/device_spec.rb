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

  context '#simulator?' do
    subject { device.simulator? }
    context 'is a simulator' do
      let(:device) {  RunLoop::Device.new('name', '7.1.2', '77DA3AC3-EB3E-4B24-B899-4A20E315C318') }
      it { is_expected.to be == true }
    end

    context 'is not a simulator' do
      let(:device) { RunLoop::Device.new('name', '7.1.2', '30c4b52a41d0f6c64a44bd01ff2966f03105de1e') }
      it { is_expected.to be == false }
    end
  end

  context '#device?' do
    subject { device.physical_device? }
    context 'is a physical device' do
      let(:device) { RunLoop::Device.new('name', '7.1.2', '30c4b52a41d0f6c64a44bd01ff2966f03105de1e') }
      it { is_expected.to be == true }
    end

    context 'is not a physical device' do
      let(:device) {  RunLoop::Device.new('name', '7.1.2', '77DA3AC3-EB3E-4B24-B899-4A20E315C318') }
      it { is_expected.to be == false }
    end
  end
end
