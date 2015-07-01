describe RunLoop::Ipa do

  let(:ipa_path) { Resources.shared.ipa_path  }

  let(:ipa) { RunLoop::Ipa.new(ipa_path) }

  describe '.new' do
    describe 'raises an exception' do
      it 'when the path does not exist' do
        expect {
          RunLoop::Ipa.new('/path/does/not/exist')
        }.to raise_error(RuntimeError)
      end

      it 'when the path does not end in .ipa' do
        expect(File).to receive(:exist?).with('/path/foo.app').and_return(true)
        expect {
          RunLoop::Ipa.new('/path/foo.app')
        }.to raise_error(RuntimeError)
      end
    end

    it 'sets the path' do
      expect(ipa.path).to be == ipa_path
    end
  end

  it '#to_s' do
    expect { ipa.to_s}.not_to raise_error
  end

  describe '#bundle_identifier' do
    it "reads the app's Info.plist" do
      expect(ipa.bundle_identifier).to be == 'sh.calaba.CalSmoke-cal'
    end

    describe 'raises an error when' do
      it 'cannot find the bundle_dir' do
        expect(ipa).to receive(:bundle_dir).and_return(nil)
        expect { ipa.bundle_identifier }.to raise_error(RuntimeError)
      end

      it 'cannot find the Info.plist' do
        expect(ipa).to receive(:bundle_dir).at_least(:once).and_return(Dir.mktmpdir)
        expect { ipa.bundle_identifier }.to raise_error(RuntimeError)
      end

      it 'Info.plist does not contain CFBundleIdentifier' do
        pbuddy = ipa.send(:plist_buddy)
        expect(pbuddy).to receive(:plist_read).and_return nil
        expect { ipa.bundle_identifier }.to raise_error(RuntimeError)
      end
    end
  end

  describe '#executable_name' do
    it "reads the app's Info.plist" do
      expect(ipa.executable_name).to be == 'CalSmoke-cal'
    end

    describe 'raises an error when' do
      it 'cannot find the bundle_dir' do
        expect(ipa).to receive(:bundle_dir).and_return(nil)
        expect { ipa.executable_name }.to raise_error(RuntimeError)
      end

      it 'cannot find the Info.plist' do
        expect(ipa).to receive(:bundle_dir).at_least(:once).and_return(Dir.mktmpdir)
        expect { ipa.executable_name }.to raise_error(RuntimeError)
      end

      it 'Info.plist does not contain key CFBundleExecutable' do
        pbuddy = ipa.send(:plist_buddy)
        expect(pbuddy).to receive(:plist_read).and_return nil
        expect { ipa.executable_name }.to raise_error(RuntimeError)
      end
    end
  end

  describe 'private' do
    it '#tmpdir' do
      tmp_dir = ipa.send(:tmpdir)

      expect(File.exist?(tmp_dir)).to be_truthy
      expect(File.directory?(tmp_dir)).to be_truthy
      expect(ipa.instance_variable_get(:@tmpdir)).to be == tmp_dir
    end

    it '#payload_dir' do
      payload_dir = ipa.send(:payload_dir)
      expect(File.exist?(payload_dir)).to be_truthy
      expect(File.directory?(payload_dir)).to be_truthy
      expect(ipa.instance_variable_get(:@payload_dir)).to be == payload_dir
    end

    it '#bundle_dir' do
      bundle_dir = ipa.send(:bundle_dir)
      expect(File.exist?(bundle_dir)).to be_truthy
      expect(File.directory?(bundle_dir)).to be_truthy
      expect(ipa.instance_variable_get(:@bundle_dir)).to be == bundle_dir
    end

    it '#plist_buddy' do
      expect(ipa.send(:plist_buddy)).to be_a_kind_of(RunLoop::PlistBuddy)
    end
  end
end
