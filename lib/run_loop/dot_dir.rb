# A module for managing the ~/.run-loop directory.
module RunLoop::DotDir

  def self.directory
    home = RunLoop::Environment.user_home_directory
    dir = File.join(home, ".run-loop")
    if !File.exist?(dir)
      FileUtils.mkdir_p(dir)
    end
    dir
  end

  def self.make_results_dir
    if RunLoop::Environment.xtc?
      next_results_dir = Dir.mktmpdir("run_loop")
    else
      results_dir = File.join(self.directory, 'results')
      next_results_dir = self.next_timestamped_dirname(results_dir)
      FileUtils.mkdir_p(next_results_dir)

      current = File.join(self.directory, "results", "current")
      FileUtils.rm_rf(current)
      FileUtils.ln_s(next_results_dir, current)
    end

    next_results_dir
  end

  def self.rotate_result_directories
    return :xtc if RunLoop::Environment.xtc?

    start = Time.now

    glob = "#{self.directory}/results/*"

    RunLoop.log_debug("Searching for run-loop results with glob: #{glob}")

    directories = Dir.glob(glob).select do |path|
      File.directory?(path) && !File.symlink?(path)
    end

    oldest_first = directories.sort_by { |f| File.mtime(f) }

    RunLoop.log_debug("Found #{oldest_first.count} previous run-loop results")
    oldest_first.pop(5)

    RunLoop.log_debug("Will delete #{oldest_first.count} previous run-loop results")

    oldest_first.each do |path|
      FileUtils.rm_rf(path)
    end

    elapsed = Time.now - start

    RunLoop.log_debug("Deleted #{oldest_first.count} previous results in #{elapsed} seconds")
  rescue StandardError => e
    RunLoop.log_error("While rotating previous results, encountered: #{e}")
  end

  private

  def self.timestamped_dirname(plus_seconds = 0)
    (Time.now + plus_seconds).strftime("%Y-%m-%d_%H-%M-%S")
  end

  def self.next_timestamped_dirname(base_dir)
    dir = File.join(base_dir, self.timestamped_dirname)
    return dir if !File.exist?(dir)

    # Rather than wait, just increment the second.  Per-second accuracy
    # is not important; uniqueness is.
    counter = 0
    loop do
      break if !File.exist?(dir)
      break if counter == 4
      counter = counter + 1
      dir = File.join(base_dir, self.timestamped_dirname(counter))
    end

    # If all else fails, just return a unique UUID
    if File.exist?(dir)
      dir = File.join(base_dir, SecureRandom.uuid)
    end
    dir
  end
end

