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

  describe '#to_str' do
    it 'physical device' do
      device = RunLoop::Device.new('denis',
                                   '8.3',
                                   '893688959205dc7eb48d603c558ede919ad8dd0c')
      expect { device.to_s }.not_to raise_error
    end

    it 'simulator' do
      device = RunLoop::Device.new('iPhone 4s',
                                   '8.3',
                                   'CE5BA25E-9434-475A-8947-ECC3918E64E3 i386')
      expect { device.to_s }.not_to raise_error
    end
  end

  describe '.device_with_identifier' do
    let(:sim_control) { RunLoop::SimControl.new }
    it 'raises an error if no simulator or device with UDID or name is found' do
      expect(sim_control).to receive(:simulators).and_return([])
      expect(sim_control.xctools).to receive(:instruments).with(:devices).and_return([])
      expect {
        RunLoop::Device.device_with_identifier('a string or udid', sim_control)
      }.to raise_error ArgumentError
    end

    describe 'physical devices' do
      let(:device) { RunLoop::Device.new('denis',
                                         '8.3',
                                         '893688959205dc7eb48d603c558ede919ad8dd0c') }


      it 'find by name' do
        expect(sim_control).to receive(:simulators).and_return([])
        expect(sim_control.xctools).to receive(:instruments).with(:devices).and_return([device])
        actual = RunLoop::Device.device_with_identifier(device.name, sim_control)
        expect(actual).to be_a_kind_of RunLoop::Device
      end

      it 'find by udid' do
        expect(sim_control).to receive(:simulators).and_return([])
        expect(sim_control.xctools).to receive(:instruments).with(:devices).and_return([device])
        actual = RunLoop::Device.device_with_identifier(device.udid, sim_control)
        expect(actual).to be_a_kind_of RunLoop::Device
      end
    end

    describe 'simulators' do

      let(:device) {
        RunLoop::Device.new('iPhone 4s',
                            '8.3',
                            'CE5BA25E-9434-475A-8947-ECC3918E64E3 i386')
      }

      it 'find by name' do
        expect(sim_control).to receive(:simulators).and_return([device])
        actual = RunLoop::Device.device_with_identifier(device.instruments_identifier,
                                                        sim_control)
        expect(actual).to be_a_kind_of RunLoop::Device
      end

      it 'find by udid' do
        expect(sim_control).to receive(:simulators).and_return([device])
        actual = RunLoop::Device.device_with_identifier(device.udid, sim_control)
        expect(actual).to be_a_kind_of RunLoop::Device
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
          expect { device.instruments_identifier(xcode_tools) }.to raise_error(RuntimeError)
        end
      end
    end
  end

  describe '#instruction_set' do
    describe 'is a physical device' do
      it 'raises an error' do
        device = RunLoop::Device.new('name', '7.1.2', '30c4b52a41d0f6c64a44bd01ff2966f03105de1e', 'Shutdown')
        expect { device.send(:instruction_set) }.to raise_error(RuntimeError)
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

  describe 'simulator files' do
    let (:physical) {  RunLoop::Device.new('name',
                                           '7.1.2',
                                           '30c4b52a41d0f6c64a44bd01ff2966f03105de1e') }
    let (:simulator) { RunLoop::Device.new('iPhone 5s',
                                           '7.1.2',
                                           '77DA3AC3-EB3E-4B24-B899-4A20E315C318', 'Shutdown') }
    describe '#simulator_root_dir' do
      it 'is nil if physical device' do
        expect(physical.simulator_root_dir).to be_falsey
      end

      it 'is non nil if a simulator' do
        expect(simulator.simulator_root_dir[/#{simulator.udid}/,0]).to be_truthy
      end
    end

    describe '#simulator_accessibility_plist_path' do
      it 'is nil if physical device' do
        expect(physical.simulator_accessibility_plist_path).to be_falsey
      end

      it 'is non nil if a simulator' do
        expect(simulator.simulator_accessibility_plist_path[/#{simulator.udid}/,0]).to be_truthy
        expect(simulator.simulator_accessibility_plist_path[/com.apple.Accessibility.plist/,0]).to be_truthy
      end
    end

    describe '#simulator_preferences_plist_path' do
      it 'is nil if physical device' do
        expect(physical.simulator_preferences_plist_path).to be_falsey
      end

      it 'is non nil if a simulator' do
        expect(simulator.simulator_preferences_plist_path[/#{simulator.udid}/,0]).to be_truthy
        expect(simulator.simulator_preferences_plist_path[/com.apple.Preferences.plist/,0]).to be_truthy
      end
    end

    describe '#simulator_log_file_path' do
      it 'is nil if physical device' do
        expect(physical.simulator_log_file_path).to be_falsey
      end

      it 'is non nil if a simulator' do
        expect(simulator.simulator_log_file_path[/#{simulator.udid}/,0]).to be_truthy
        expect(simulator.simulator_log_file_path[/system.log/,0]).to be_truthy
      end
    end
  end
end
