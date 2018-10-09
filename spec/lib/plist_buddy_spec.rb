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

  context "#run_command" do
    it "returns true and output if command is successful" do
      success, output = pbuddy.run_command("Print :AXInspectorEnabled", path)

      expect(success).to be_truthy
      expect(output).to be == "false"
    end
    it "raises an error if command is not successful" do
      expect do
        pbuddy.run_command("Print :NoSuchKey", path)
      end.to raise_error(RuntimeError, /Does Not Exist/)
    end
  end

  context "#unshift_array" do
    it "creates an array for key and adds the value" do
      pbuddy.unshift_array("Languages", "string", "de", path)

      value = pbuddy.plist_read("Languages", path)
      expect(value[/Array/]).to be_truthy

      expect(pbuddy.plist_read("Languages:0", path)).to be == "de"
    end

    it "raises an error if key exists, but is not of type Array" do
      pbuddy.run_command("Add :Languages dict", path)
      pbuddy.run_command("Add :Languages:0 string en", path)

      expect do
        pbuddy.unshift_array("Languages", "string", "de", path)
      end.to raise_error(RuntimeError, /Found:  had type Dict/)
    end

    it "pushes the value into the first position of the array" do
      pbuddy.run_command("Add :Languages array", path)
      pbuddy.run_command("Add :Languages:0 string en", path)

      pbuddy.unshift_array("Languages", "string", "de", path)

      value = pbuddy.plist_read("Languages", path)
      expect(value[/Array/]).to be_truthy

      expect(pbuddy.plist_read("Languages:0", path)).to be == "de"
      expect(pbuddy.plist_read("Languages:1", path)).to be == "en"
    end
  end

  context "#ensure_plist" do
    let(:base_dir) { File.join(Resources.shared.local_tmp_dir, "PlistBuddy") }
    let(:directory) { File.join(base_dir, "A", "B") }
    let(:name) { "com.example.MyApp.plist" }
    let(:plist) { File.join(directory, name) }

    before do
      FileUtils.rm_rf(base_dir)
      FileUtils.mkdir_p(base_dir)
    end

    it "returns a path to an existing plist" do
      FileUtils.mkdir_p(directory)
      FileUtils.touch(plist)

      expect(FileUtils).not_to receive(:mkdir_p).with(directory)
      expect(pbuddy).not_to receive(:create_plist)
      expect(pbuddy.ensure_plist(directory, name)).to be == plist
    end

    it "returns a path to an empty plist if one does not already exist" do
      FileUtils.mkdir_p(directory)

      expect(FileUtils).not_to receive(:mkdir_p).with(directory)
      expect(pbuddy).to receive(:create_plist).with(plist)
      expect(pbuddy.ensure_plist(directory, name)).to be == plist
    end

    it "returns a path to an empty plist after creating any necessary directories" do
      expect(FileUtils).to receive(:mkdir_p).with(directory)
      expect(pbuddy).to receive(:create_plist).with(plist)

      expect(pbuddy.ensure_plist(directory, name)).to be == plist
    end
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
        expect(cmd).to be == "Print :foo"
      end

      it 'set' do
        cmd =  pbuddy.send(:build_plist_cmd, *[:set,
                                               {:key => 'foo', :value => 'bar'},
                                               path])
        expect(cmd).to be == "Set :foo bar"
      end

      it 'set false for bool type' do
        cmd =  pbuddy.send(:build_plist_cmd, *[:set,
                                               {:key => 'foo', :value => false, :type => 'bool'},
                                               path])
        expect(cmd).to be == "Set :foo false"
      end

      it 'set false for bool type when value is nil' do
        cmd =  pbuddy.send(:build_plist_cmd, *[:set,
                                               {:key => 'foo', :value => nil, :type => 'bool'},
                                               path])
        expect(cmd).to be == "Set :foo false"
      end

      it 'set true for bool type when value is anything that is not nil or false' do
        cmd =  pbuddy.send(:build_plist_cmd, *[:set,
                                               {:key => 'foo', :value => 'smth', :type => 'bool'},
                                               path])
        expect(cmd).to be == "Set :foo true"
      end

      it 'add' do
        cmd = pbuddy.send(:build_plist_cmd, *[:add, {
                                                        :key => 'foo',
                                                        :value => 'bar',
                                                        :type => 'string'
                                                  }, path])
        expect(cmd).to be == "Add :foo string bar"
      end

      it 'add false for bool type' do
        cmd = pbuddy.send(:build_plist_cmd, *[:add, {
            :key => 'foo',
            :value => false,
            :type => 'bool'
        }, path])
        expect(cmd).to be == "Add :foo bool false"
      end

      it 'add true for bool type when value is anything that is not nil or false' do
        cmd = pbuddy.send(:build_plist_cmd, *[:add, {
            :key => 'foo',
            :value => 'something',
            :type => 'bool'
        }, path])
        expect(cmd).to be == "Add :foo bool true"
      end

      it 'add false for bool type when value is nil' do
        cmd = pbuddy.send(:build_plist_cmd, *[:add, {
            :key => 'foo',
            :value => nil,
            :type => 'bool'
        }, path])
        expect(cmd).to be == "Add :foo bool false"
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
