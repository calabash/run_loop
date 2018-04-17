describe RunLoop::Directory do

  before do
    stub_env({'DEBUG' => '1'})
  end

  it '.recursive_glob_for_entries' do
    base_dir = Dir.mktmpdir
    dotfile_path = File.join(base_dir, '.a-dot-file')
    FileUtils.touch(dotfile_path)
    dotfile_dir = File.join(base_dir, '.a-dot-dir')
    FileUtils.mkdir_p(dotfile_dir)
    expected = ['.a-dot-file', '.a-dot-dir']
    expect(RunLoop::Directory.recursive_glob_for_entries(base_dir)) == expected
  end

  describe '.directory_digest' do
    it 'returns the same value for a copy of the same directory' do
      original_path = Resources.shared.app_bundle_path
      tmp_dir = Dir.mktmpdir
      FileUtils.cp_r(original_path, "#{tmp_dir}/")
      copied_path = File.join(tmp_dir, File.basename(original_path))

      a = RunLoop::Directory.directory_digest(original_path)
      b = RunLoop::Directory.directory_digest(copied_path)
      expect(a).to be == b
    end

    it 'returns a different value for directories that are not the same' do
      a_path = Resources.shared.app_bundle_path
      b_path = Resources.shared.cal_app_bundle_path
      a = RunLoop::Directory.directory_digest(a_path)
      b = RunLoop::Directory.directory_digest(b_path)
      expect(a).not_to be == b
    end

    describe 'raises error when path' do
      it 'is not a directory' do
        tmp_dir = Dir.mktmpdir
        file = File.join(tmp_dir, 'a-file.txt')
        FileUtils.touch(file)
        expect {
          RunLoop::Directory.directory_digest(file)
        }.to raise_error ArgumentError
      end

      it 'path does not exist' do
        tmp_dir = Dir.mktmpdir
        dir = File.join(tmp_dir, 'a-dir')
        expect {
          RunLoop::Directory.directory_digest(dir)
        }.to raise_error ArgumentError
      end

      it 'directory is empty' do
        tmp_dir = Dir.mktmpdir
        expect {
          RunLoop::Directory.directory_digest(tmp_dir)
        }.to raise_error ArgumentError
      end
    end

    describe "options" do
      let(:tmp_dir) { Dir.mktmpdir }
      let(:path) do
        path = File.join(tmp_dir, "foo.txt")
        FileUtils.touch(path)
        path
      end

      it "raises an error when :handle_errors_by is an unknown value" do
        options = { :handle_errors_by => :unknown }

        expect do
          RunLoop::Directory.directory_digest(tmp_dir, options)
        end.to raise_error ArgumentError,
        /Expected :handle_errors_by to be :raising, :logging, or :ignoring/
      end

      it "logs read errors when :handle_errors_by is :logging" do
        options = { :handle_errors_by => :logging }

        error = RuntimeError.new("My runtime error")
        expect(File).to receive(:read).with(path, {mode: "rb"}).and_raise error

        out = Kernel.capture_stdout do
          RunLoop::Directory.directory_digest(tmp_dir, options)
        end.string

        puts out

        expect(out[/directory_digest raised an error:/, 0]).to be_truthy
        expect(out[/My runtime error/, 0]).to be_truthy
        expect(out[/#{path}/, 0]).to be_truthy
        expect(out[/This is not a fatal error; it can be ignored/, 0]).to be_truthy
      end

      it "ignores read errors when :handle_errors_by is :ignoring" do
        options = { :handle_errors_by => :ignoring }

        error = RuntimeError.new("My runtime error")
        expect(File).to receive(:read).with(path, {mode: "rb"}).and_raise error

        out = Kernel.capture_stdout do
          RunLoop::Directory.directory_digest(tmp_dir, options)
        end.string

        expect(out).to be == ""
      end

      it "raises read errors when :handle_errors_by is :raising" do
        options = { :handle_errors_by => :raising }

        error = RuntimeError.new("My runtime error")
        expect(File).to receive(:read).with(path, {mode: "rb"}).and_raise error

        expect do
          RunLoop::Directory.directory_digest(tmp_dir, options)
        end.to raise_error RuntimeError, /My runtime error/
      end

      it "the default behavior is to raise" do
        error = RuntimeError.new("My runtime error")
        expect(File).to receive(:read).with(path, {mode: "rb"}).and_raise error

        expect do
          RunLoop::Directory.directory_digest(tmp_dir)
        end.to raise_error RuntimeError, /My runtime error/
      end
    end
  end

  describe '.size' do
    let(:format) { :mb }
    let(:path) { Resources.shared.app_bundle_path }

    describe 'format' do
      it ':bytes' do
        expect(RunLoop::Directory).to receive(:iterate_for_size).and_return 12

        expect(RunLoop::Directory.size(path, :bytes)).to be == 12
      end

      it ':kb' do
        expect(RunLoop::Directory).to receive(:iterate_for_size).and_return 12 * 1000
        expect(RunLoop::Directory.size(path, :kb)).to be == 12.0
      end

      it ':mb' do
        expect(RunLoop::Directory).to receive(:iterate_for_size).and_return 12 * 1000 * 1000

        expect(RunLoop::Directory.size(path, :mb)).to be == 12.0
      end

      it ':gb' do
        expect(RunLoop::Directory).to receive(:iterate_for_size).and_return 12 * 1000 * 1000 * 1000

        expect(RunLoop::Directory.size(path, :gb)).to be == 12.0
      end
    end

    it 'returns the same when run 2x' do
      first = RunLoop::Directory.size(path, :bytes)
      second = RunLoop::Directory.size(path, :bytes)
      expect(first).to be == second
    end

    describe 'raises error' do
      it 'unrecognized format arg' do
         expect do
           RunLoop::Directory.size('./', :unknown)
         end.to raise_error ArgumentError, /Expected 'unknown' to be one of/
      end

      it 'path does not exist' do
        expect do
          RunLoop::Directory.size('/does/not/exist', format)
        end.to raise_error ArgumentError, /Expected '(.*)' to exist/
      end

      it 'path not a directory' do
        path = '/is/a/file.txt'
        allow(File).to receive(:exist?).with(path).and_return true
        allow(File).to receive(:directory?).with(path).and_return false

        expect do
          RunLoop::Directory.size(path, format)
        end.to raise_error ArgumentError, /Expected '(.*)' to be a directory/
      end

      it 'directory is not empty' do
        path = '/is/a/file.txt'
        allow(File).to receive(:exist?).with(path).and_return true
        allow(File).to receive(:directory?).with(path).and_return true
        expect(RunLoop::Directory).to receive(:recursive_glob_for_entries).and_return []

        expect do
          RunLoop::Directory.size(path, format)
        end.to raise_error ArgumentError, /Expected a non-empty dir at '(.*)'/
      end
    end
  end
end
