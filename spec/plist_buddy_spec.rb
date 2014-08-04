require 'fileutils'

describe RunLoop::PlistBuddy do

  subject(:pbuddy) { RunLoop::PlistBuddy.new }

  describe '#plist_buddy' do
    it 'path to plist_buddy binary' do
      expect(pbuddy.instance_eval{ plist_buddy }).to be == '/usr/libexec/PlistBuddy'
    end
  end

  describe '#build_plist_cmd' do

    before(:each) do
      FileUtils.rm_rf Resources.shared.plist_for_testing
      FileUtils.cp Resources.shared.plist_template, Resources.shared.plist_for_testing
    end

    describe 'raises errors' do
      it 'if file does not exist' do
        expect {
          pbuddy.instance_eval {
            build_plist_cmd(:foo, nil, '/path/does/not/exist')
          }
        }.to raise_error(RuntimeError)
      end

      it 'if command is not valid' do
        expect {
          pbuddy.instance_eval {
            build_plist_cmd(:foo, nil, Resources.shared.plist_for_testing)
          }
        }.to raise_error(ArgumentError)
      end

      it 'if args_hash is missing required key/value pairs' do
        expect {
          pbuddy.instance_eval {
            build_plist_cmd(:print, {:foo => 'bar'}, Resources.shared.plist_for_testing)
          }
        }.to raise_error(ArgumentError)
      end
    end

    context 'composing commands' do

      it 'print' do
        path = Resources.shared.plist_for_testing
        cmd = nil
        pbuddy.instance_eval {
          cmd = build_plist_cmd(:print, {:key => 'foo'}, path)
        }
        expect(cmd).to be == "/usr/libexec/PlistBuddy -c \"Print :foo\" \"#{path}\""
      end

      it 'set' do
        path = Resources.shared.plist_for_testing
        cmd = nil
        pbuddy.instance_eval {
          cmd =  build_plist_cmd(:set, {:key => 'foo', :value => 'bar'}, path)
        }
        expect(cmd).to be == "/usr/libexec/PlistBuddy -c \"Set :foo bar\" \"#{path}\""
      end

      it 'add' do
        path = Resources.shared.plist_for_testing
        cmd = nil
        pbuddy.instance_eval {
          cmd = build_plist_cmd(:add, {:key => 'foo', :value => 'bar', :type => 'bool'}, path)
        }
        expect(cmd).to be == "/usr/libexec/PlistBuddy -c \"Add :foo bool bar\" \"#{path}\""
      end

    end

    context 'plist read/write' do

      before(:each) {
        @hash = Resources.shared.accessibility_plist_hash
        @path = Resources.shared.plist_for_testing
        @opts = {}
      }

      context 'read' do
        it 'returns value for keys that exist' do
          expect(pbuddy.plist_read(@hash[:inspector_showing], @path, @opts)).to be == 'false'
        end

        it 'returns nil when reading non-existing key' do
          expect(pbuddy.plist_read('FOO', @path, @opts)).to be == nil
        end
      end

      context 'write' do
        it 'sets value for existing key' do
          expect(pbuddy.plist_set(@hash[:inspector_showing], 'bool', 'true', @path, @opts)).to be == true
          expect(pbuddy.plist_read(@hash[:inspector_showing], @path, @opts)).to be == 'true'
        end

        it 'creates value for new key' do
          expect(pbuddy.plist_set('FOO', 'bool', 'true', @path, @opts)).to be == true
          expect(pbuddy.plist_read('FOO', @path, @opts)).to be == 'true'
        end
      end
    end
  end
end
