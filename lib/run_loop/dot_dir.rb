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
    results_dir = File.join(self.directory, 'results')
    next_results_dir = self.next_timestamped_dirname(results_dir)

    FileUtils.mkdir_p(next_results_dir)

    next_results_dir
  end

  def self.logs_dir
   log_dir = File.join(self.directory, 'logs')

   if !File.exist?(log_dir)
     FileUtils.mkdir_p(log_dir)
   end

   log_dir
  end

  def self.logfile_for_rotate_results
    logfile = File.join(self.logs_dir, 'rotate-results.log')

    if !File.exist?(logfile)
      FileUtils.touch(logfile)
    end

    logfile
  end

  def self.rotate_result_directories
    start = Time.now

    glob = "#{self.directory}/results/*"

    RunLoop.log_debug("Searching for run-loop results with glob: #{glob}")

    directories = Dir.glob(glob).select do |path|
      File.directory?(path)
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
    RunLoop.log_error("While rotating previous results, encounterd: #{e}")
  end

  private

  def self.timestamped_dirname
    now = Time.now.to_s
    tokens = now.split(' ')[0...-1]
    timestamp = tokens.join('_')
    timestamp.gsub!(':', '-')
  end

  def self.next_timestamped_dirname(base_dir)
    dir = File.join(base_dir, self.timestamped_dirname)

    # Rather than wait, just increment the second.  Per-second accuracy
    # is not important; uniqueness is.
    counter = 0
    loop do
      break if !File.exist?(dir)
      break if counter == 3
      next_second = dir[-1].to_i + 1
      dir = "#{dir[0...-1]}#{next_second}"
      counter = counter + 1
    end

    # If all else fails, just return a unique UUID
    if File.exist?(dir)
      dir = File.join(base_dir, SecureRandom.uuid)
    end
    dir
  end

  def self.log_to_file(file, message)

    timestamp = Time.now
    dated = "#{timestamp} #{message}"

    File.open(file, "a") do |log|
      begin
        log.write("#{dated}\n")
        log.flush
      rescue StandardError => e
        RunLoop.log_error("Writing to #{file} generated this error: #{e}")
      end
    end
  end
end

