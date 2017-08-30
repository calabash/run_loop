describe RunLoop::PlistBuddy do

  let(:pbuddy) { RunLoop::PlistBuddy.new }
  let(:path) { Resources.shared.plist_for_testing }

  describe '#plist_buddy' do
    it 'path to plist_buddy binary' do
      expect(pbuddy.send(:plist_buddy)).to be == '/usr/libexec/PlistBuddy'
    end
  end

  it '#create_plist' do
    path = File.join(Dir.mktmpdir, 'foo.plist')
    pbuddy.create_plist(path)
    expect(File.exist?(path)).to be_truthy
    expect(File.open(path).read).not_to be == ''
  end

  describe '#build_plist_cmd' do
    describe 'raises errors' do
      it 'if file does not exist' do
        expect {
          pbuddy.send(:build_plist_cmd, :foo, nil, '/path/does/not/exist')
        }.to raise_error(RuntimeError)
      end

      it 'if command is not valid' do
        expect {
          pbuddy.send(:build_plist_cmd, :foo, nil, path)
          }.to raise_error(ArgumentError)
      end

      it 'if args_hash is missing required key/value pairs' do
        expect {
          pbuddy.send(:build_plist_cmd, *[:print, {:foo => 'bar'}, path])
         }.to raise_error(ArgumentError)
      end
    end

    describe 'composing commands' do
      it 'print' do
        cmd = pbuddy.send(:build_plist_cmd, *[:print, {:key => 'foo'}, path])
        expect(cmd).to be == "/usr/libexec/PlistBuddy -c \"Print :foo\" \"#{path}\""
      end

      it 'set' do
        cmd =  pbuddy.send(:build_plist_cmd, *[:set,
                                               {:key => 'foo', :value => 'bar'},
                                               path])
        expect(cmd).to be == "/usr/libexec/PlistBuddy -c \"Set :foo bar\" \"#{path}\""
      end

      it 'add' do
        cmd = pbuddy.send(:build_plist_cmd, *[:add, {
                                                        :key => 'foo',
                                                        :value => 'bar',
                                                        :type => 'bool'
                                                  }, path])
        expect(cmd).to be == "/usr/libexec/PlistBuddy -c \"Add :foo bool bar\" \"#{path}\""
      end

    end

    context 'plist read/write' do

      let(:hash) { Resources.shared.accessibility_plist_hash }
      let(:opts) { {} }

      context 'read' do
        it 'returns value for keys that exist' do
          expect(
            pbuddy.plist_read(hash[:inspector_showing], path, opts)
          ).to be == 'false'
        end

        it 'returns nil when reading non-existing key' do
          expect(pbuddy.plist_read('FOO', path, opts)).to be == nil
        end
      end

      context 'write' do
        it 'sets value for existing key' do
          expect(pbuddy.plist_set(hash[:inspector_showing],
                                  'bool', 'true', path, opts)
          ).to be == true
          expect(
            pbuddy.plist_read(hash[:inspector_showing], path, opts)
          ).to be == 'true'
        end

        it 'creates value for new key' do
          expect(
            pbuddy.plist_set('FOO', 'bool', 'true', path, opts)
          ).to be == true
          expect(pbuddy.plist_read('FOO', path, opts)).to be == 'true'
        end
      end
    end
  end
end
