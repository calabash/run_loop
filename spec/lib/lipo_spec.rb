require 'pry'
describe RunLoop::Lipo do

  let(:app_bundle_path) { Resources.shared.app_bundle_path }
  subject(:lipo) { RunLoop::Lipo.new(app_bundle_path) }

  describe '#bundle_path' do
    subject { lipo.bundle_path }
    it { should match(/spec\/resources\/chou.app/) }
  end

  describe '#plist_path' do
    subject{ lipo.send(:plist_path) }
    it { should match(/spec\/resources\/chou.app\/Info.plist/) }
  end

  describe '#binary_path' do
    subject{ lipo.send(:binary_path) }
    it { should match('/spec/resources/chou.app/chou') }
    it { should match(/spec\/resources\/chou.app\/chou/) }
  end

  describe '#info' do
    subject{ lipo.info }
    it 'should return a list of architectures supported by the binary' do

    end
  end

end
