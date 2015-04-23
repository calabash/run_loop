describe RunLoop::Directory do

  it '.recursive_glob_for_entries' do
    base_dir = Dir.mktmpdir
    dotfile_path = File.join(base_dir, '.a-dot-file')
    FileUtils.touch(dotfile_path)
    dotfile_dir = File.join(base_dir, '.a-dot-dir')
    FileUtils.mkdir_p(dotfile_dir)
    expected = ['.a-dot-file', '.a-dot-dir']
    expect(RunLoop::Directory.recursive_glob_for_entries(base_dir)) == expected
  end

  describe '#directory_digest' do
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
  end
end
