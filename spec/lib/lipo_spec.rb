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
      it { is_expected.to be_a Array  }
      it { is_expected.to match_array ['i386']  }
    end

    context 'binary is FAT' do
      let(:app_bundle_path) { Resources.shared.multi_arch_app_bundle_path }
      it { is_expected.to match_array ['armv7', 'arm64']}
    end
  end

end
