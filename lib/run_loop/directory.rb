module RunLoop

  # Class for performing operations on directories.
  class Directory
    require 'digest'
    require 'openssl'
    require 'pathname'

    # Dir.glob ignores files that start with '.', but we often need to find
    # dotted files and directories.
    #
    # Ruby 2.* does the right thing by ignoring '..' and '.'.
    #
    # Ruby < 2.0 includes '..' and '.' in results which causes problems for some
    # of run-loop's internal methods.  In particular `reset_app_sandbox`.
    def self.recursive_glob_for_entries(base_dir)
      Dir.glob("#{base_dir}/{**/.*,**/*}").select do |entry|
        !(entry.end_with?('..') || entry.end_with?('.'))
      end
    end

    # Computes the digest of directory.
    #
    # @param path A path to a directory.
    # @raise ArgumentError When `path` is not a directory or path does not exist.
    def self.directory_digest(path)

      unless File.exist?(path)
        raise ArgumentError, "Expected '#{path}' to exist"
      end

      unless File.directory?(path)
        raise ArgumentError, "Expected '#{path}' to be a directory"
      end

      entries = self.recursive_glob_for_entries(path)

      if entries.empty?
        raise ArgumentError, "Expected a non-empty dir at '#{path}' found '#{entries}'"
      end

      debug = RunLoop::Environment.debug?

      sha = OpenSSL::Digest::SHA256.new
      entries.each do |file|
        unless self.skip_file?(file, 'SHA1', debug)
          sha << File.read(file)
        end
      end
      sha.hexdigest
    end

    private

    def self.skip_file?(file, task, debug)
      skip = false
      if File.directory?(file)
        # Skip directories
        skip = true
      elsif !Pathname.new(file).exist?
        # Skip broken symlinks
        skip = true
      elsif !File.exist?(file)
        # Skip files that don't exist
        skip = true
      else
        case File.ftype(file)
          when 'fifo'
            RunLoop.log_warn("#{task} IS SKIPPING FIFO #{file}") if debug
            skip = true
          when 'socket'
            RunLoop.log_warn("#{task} IS SKIPPING SOCKET #{file}") if debug
            skip = true
          when 'characterSpecial'
            RunLoop.log_warn("#{task} IS SKIPPING CHAR SPECIAL #{file}") if debug
            skip = true
          when 'blockSpecial'
            skip = true
            RunLoop.log_warn("#{task} SKIPPING BLOCK SPECIAL #{file}") if debug
          else

        end
      end
      skip
    end
  end
end
