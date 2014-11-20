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

  describe '#instruments_identifier' do
    subject { device.instruments_identifier }
    context 'physical device' do
      let(:device) { RunLoop::Device.new('name', '8.1.1', 'e60ef9ae876ab4a218ee966d0525c9fb79e5606d') }
      it { is_expected.to be == 'e60ef9ae876ab4a218ee966d0525c9fb79e5606d' }
    end

    describe 'simulator' do
      context 'with Major.Minor SDK version' do
        let(:device) { RunLoop::Device.new('Form Factor', '8.1.1', 'not a device udid') }
        it { is_expected.to be == 'Form Factor (8.1 Simulator)' }
      end

      context 'with Major.Minor.Patch SDK version' do
        let(:device) { RunLoop::Device.new('Form Factor', '7.0.3', 'not a device udid') }
        it { is_expected.to be == 'Form Factor (7.0.3 Simulator)' }
      end

      describe 'Xcode < 6' do
        let(:device) { RunLoop::Device.new('Form Factor', '7.0.3', 'not a device udid') }
        let(:xcode_tools) { RunLoop::XCTools.new }
        it 'raises an error' do
          expect(xcode_tools).to receive(:xcode_version_gte_6?).and_return(false)
          expect { device.instruments_identifier(xcode_tools) }.to raise_error
        end
      end
    end
  end
end
