describe RunLoop::Lipo do

  let(:app_bundle_path) { Resources.shared.app_bundle_path }
  subject(:lipo) { RunLoop::Lipo.new(app_bundle_path) }

  describe '#bundle_path' do
    subject { lipo.bundle_path }
    it { is_expected.to match(/spec\/resources\/chou.app/) }
  end

  describe '#plist_path' do
    subject{ lipo.send(:plist_path) }
    it { is_expected.to match(/spec\/resources\/chou.app\/Info.plist/) }
  end

  describe '#binary_path' do
    subject{ lipo.send(:binary_path) }
    it { is_expected.to match(/spec\/resources\/chou.app\/chou/) }
  end

  describe '#info' do
    subject{ lipo.info }
    context 'binary is not FAT' do
      let (:app_bundle_path) { Resources.shared.app_bundle_path_i386 }
      it { is_expected.to be_a Array  }
      it { is_expected.to match_array ['i386']  }
    end

    context 'binary is FAT' do
      let(:app_bundle_path) { Resources.shared.app_bundle_path_arm_FAT }
      it { is_expected.to match_array ['armv7', 'arm64']}
    end
  end

  describe '#expect_compatible_arch' do
    describe 'raises an error' do
      it 'when device is a physical device' do
        device = RunLoop::Device.new('name', '7.1.2', 'e60ef9ae876ab4a218ee966d0525c9fb79e5606d')
        expect { lipo.expect_compatible_arch(device) }.to raise_error RuntimeError
      end

      it 'when architecture is incompatible' do
        device = RunLoop::Device.new('name', '7.1.2', '76663BB5-0B3E-4615-BC29-58C8F7F275E1')
        expect(device).to receive(:instruction_set).and_return('i386')
        expect(lipo).to receive(:info).and_return(['x86_64'])
        expect { lipo.expect_compatible_arch(device) }.to raise_error RunLoop::IncompatibleArchitecture
      end
    end
  end
end
