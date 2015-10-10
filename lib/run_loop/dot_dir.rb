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
    dot_dir = self.directory
    results_dir = File.join(dot_dir, 'results', self.timestamped_dirname)

    # Rather than wait, just increment the second.  Per-second accuracy is not
    # important; uniqueness is.
    if File.exist?(results_dir)
       next_second = results_dir[-1].to_i + 1
       results_dir = "#{results_dir[0...-1]}#{next_second}"
    end

    FileUtils.mkdir_p(results_dir)

    results_dir
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

  private

  def self.timestamped_dirname
    now = Time.now.to_s
    tokens = now.split(' ')[0...-1]
    timestamp = tokens.join('_')
    timestamp.gsub!(':', '-')
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

