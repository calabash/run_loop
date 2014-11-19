describe RunLoop::Device do

  context 'creating a new instance' do
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

  describe '#simulator?' do
    subject { device.simulator? }
    context 'physical device' do
      let(:device) { RunLoop::Device.new('name', '8.1.1', 'e60ef9ae876ab4a218ee966d0525c9fb79e5606d') }
      it { is_expected.to be == false }
    end

    context 'simulator' do
      let(:device) { RunLoop::Device.new('name', '8.1.1', 'not a device udid') }
      it { is_expected.to be == true }
    end
  end

  describe '#physical_device?' do
    subject { device.physical_device? }
    context 'physical device' do
      let(:device) { RunLoop::Device.new('name', '8.1.1', 'e60ef9ae876ab4a218ee966d0525c9fb79e5606d') }
      it { is_expected.to be == true }
    end

    context 'simulator' do
      let(:device) { RunLoop::Device.new('name', '8.1.1', 'not a device udid') }
      it { is_expected.to be == false }
    end
  end
end
