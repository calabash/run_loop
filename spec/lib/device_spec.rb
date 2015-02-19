describe RunLoop::Device do

  context 'creating a new instance' do
    subject!(:version) { RunLoop::Version.new('7.1.2') }
    subject(:device) { RunLoop::Device.new('name', version , 'udid', 'Shutdown') }

    describe '.new' do
      it 'has attr name' do
        expect(device.name).to be == 'name'
      end

      it 'has attr udid' do
        expect(device.udid).to be == 'udid'
      end

      it 'has attr state' do
        expect(device.state).to be == 'Shutdown'
      end

      describe 'version attr' do
        it 'has attr version' do
          expect(device.version).to be == version
        end

        it 'can accept a version str' do
          local_device = RunLoop::Device.new('name', '7.1.2', 'udid', 'Shutdown')
          expect(local_device.version).to be_a RunLoop::Version
          expect(local_device.version).to be == RunLoop::Version.new('7.1.2')
        end
      end
    end
  end

  context '#simulator?' do
    subject { device.simulator? }
    context 'is a simulator' do
      let(:device) {  RunLoop::Device.new('name', '7.1.2', '77DA3AC3-EB3E-4B24-B899-4A20E315C318', 'Shutdown') }
      it { is_expected.to be == true }
    end

    context 'is not a simulator' do
      let(:device) { RunLoop::Device.new('name', '7.1.2', '30c4b52a41d0f6c64a44bd01ff2966f03105de1e', 'Shutdown') }
      it { is_expected.to be == false }
    end
  end

  context '#device?' do
    subject { device.physical_device? }
    context 'is a physical device' do
      let(:device) { RunLoop::Device.new('name', '7.1.2', '30c4b52a41d0f6c64a44bd01ff2966f03105de1e', 'Shutdown') }
      it { is_expected.to be == true }
    end

    context 'is not a physical device' do
      let(:device) {  RunLoop::Device.new('name', '7.1.2', '77DA3AC3-EB3E-4B24-B899-4A20E315C318', 'Shutdown') }
      it { is_expected.to be == false }
    end
  end

  describe '#instruments_identifier' do
    subject { device.instruments_identifier }
    context 'physical device' do
      let(:device) { RunLoop::Device.new('name', '8.1.1', 'e60ef9ae876ab4a218ee966d0525c9fb79e5606d', 'Shutdown') }
      it { is_expected.to be == 'e60ef9ae876ab4a218ee966d0525c9fb79e5606d' }
    end

    describe 'simulator' do
      context 'with Major.Minor SDK version' do
        let(:device) { RunLoop::Device.new('Form Factor', '8.1.1', 'not a device udid', 'Shutdown') }
        it { is_expected.to be == 'Form Factor (8.1 Simulator)' }
      end

      context 'with Major.Minor.Patch SDK version' do
        let(:device) { RunLoop::Device.new('Form Factor', '7.0.3', 'not a device udid', 'Shutdown') }
        it { is_expected.to be == 'Form Factor (7.0.3 Simulator)' }
      end

      describe 'Xcode < 6' do
        let(:device) { RunLoop::Device.new('Form Factor', '7.0.3', 'not a device udid', 'Shutdown') }
        let(:xcode_tools) { RunLoop::XCTools.new }
        it 'raises an error' do
          expect(xcode_tools).to receive(:xcode_version_gte_6?).and_return(false)
          expect { device.instruments_identifier(xcode_tools) }.to raise_error
        end
      end
    end
  end

  describe '#instruction_set' do
    describe 'is a physical device' do
      it 'raises an error' do
        device = RunLoop::Device.new('name', '7.1.2', '30c4b52a41d0f6c64a44bd01ff2966f03105de1e', 'Shutdown')
        expect { device.send(:instruction_set) }.to raise_error
      end
    end

    context 'CoreSimulators' do
      let (:device) { RunLoop::Device.new(name, '7.1.2', '77DA3AC3-EB3E-4B24-B899-4A20E315C318', 'Shutdown') }
      subject { device.send(:instruction_set) }
      context 'is an i386 Simulator' do
        ['iPhone 4s', 'iPhone 5', 'iPad 2', 'iPad Retina'].each do |sim_name|
          let(:name) { sim_name }
          it { is_expected.to be == 'i386' }
        end
      end

      context 'is any other simulator' do
        let(:name) { 'iPad Air' }
        it { is_expected.to be == 'x86_64' }
      end
    end
  end
end
