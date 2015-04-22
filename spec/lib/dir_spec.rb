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
end
