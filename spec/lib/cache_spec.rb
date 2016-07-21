describe RunLoop::Cache do

  let(:directory) { Dir.mktmpdir }
  let(:cache_filename) { '2780e6479cc2bfcd0a007bd08bdf36de11b397bd' }

  describe "RunLoop::HostCache" do
    it "exists for backward compatibility" do
      # Can be removed once Calabash iOS Launcher#attach removes reference.
      cache = RunLoop::HostCache.default
      expect(cache).to be_a_kind_of(RunLoop::Cache)
    end
  end

  describe '.new' do

    after(:each) { FileUtils.rm_rf(File.expand_path('./host_cache.db')) }

    it 'when directory exists' do
      cache = RunLoop::Cache.new(directory)
      expect(cache.path).to be == File.join(directory, cache_filename)
    end

    it 'when directory does not exist' do
      new_dir = File.join(directory, '.calabash')
      cache = RunLoop::Cache.new(new_dir)
      expect(cache.path).to be == File.join(new_dir, cache_filename)
      expect(Dir.exist?(new_dir))
    end

    it 'respects :filename option' do
      filename = 'host_cache.db'
      cache = RunLoop::Cache.new(directory, {filename:filename})
      expect(cache.path).to be == File.join(directory, filename)
    end

    it 'respects :clear option' do
      filename = 'host_cache.db'
      expected_path = File.join(directory, filename)
      FileUtils.touch(filename)
      cache = RunLoop::Cache.new(directory, {filename:filename, clear:true})
      expect(cache.path).to be == expected_path
      expect(File.exist?(expected_path)).to be == false
    end
  end

  describe '.default_directory' do

    let(:tmp_dir) { Dir.mktmpdir }
    let(:dot_run_loop) { File.join(tmp_dir, ".run-loop" ) }

    before do
      allow(RunLoop::Environment).to receive(:user_home_directory).and_return(tmp_dir)
    end

    it 'returns directory if it exists' do
      expect(RunLoop::Cache.default_directory).to be == dot_run_loop
    end

    it 'creates a directory if it does not exist' do
      FileUtils.rm_rf(tmp_dir)
      FileUtils.mkdir_p(tmp_dir)
      expect(FileUtils).to receive(:mkdir).with(dot_run_loop).and_call_original

      expect(RunLoop::Cache.default_directory).to be == dot_run_loop
    end

    it 'raises error if directory is actually a file' do
      FileUtils.rm_rf(tmp_dir)
      FileUtils.mkdir_p(tmp_dir)
      FileUtils.touch(dot_run_loop)

      expect do
        RunLoop::Cache.default_directory
      end.to raise_error(RuntimeError,
                         /RunLoop requires this directory to cache files/)
    end
  end

  context '.default' do
    subject { RunLoop::Cache.default }
    it {
      is_expected.not_to be nil
      is_expected.to be_a RunLoop::Cache
    }
  end

  describe 'io' do
    let(:hash) { { :number => 1, :word => 'word', :symbol => :symbol } }
    describe '#read' do
      it 'returns an empty Hash if cache file does not exist' do
        cache = RunLoop::Cache.new(directory)
        result = cache.read
        expect(result).to be_a Hash
        expect(result).to be == {}
      end
    end

    describe '#write' do
      let(:cache) { RunLoop::Cache.new(directory) }
      describe 'raises error when' do
        it 'argument is nil' do
          expect { cache.write(nil) }.to raise_error ArgumentError
        end

        it 'argument is not a Hash' do
          expect { cache.write([]) }.to raise_error ArgumentError
        end

        it "argument cannot be Marshal.dump'ed" do
          hash = {:dir => StringIO.new('fifo') }
          expect { cache.write( hash ) }.to raise_error TypeError
        end
      end

      it "what it writes can be Marshal.load'ed" do
        expect(cache.write(hash)).to be == true

        actual = nil
        File.open(cache.path) do |file|
          actual = Marshal.load(file)
        end

        expect(actual).to be == hash
      end
    end

    describe '#clear' do
      it 'can clear the cache' do
        cache = RunLoop::Cache.new(directory)
        expect(cache.write(hash)).to be == true
        expect(cache.read).to be == hash
        expect(cache.clear).to be == true
        expect(cache.read).to be == {}
      end
    end
  end
end
