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

      sha = OpenSSL::Digest::SHA256.new
      self.recursive_glob_for_entries(path).each do |file|
        if File.directory?(file)
          # skip directories
        elsif !Pathname.new(file).exist?
          # skip broken symlinks
        else
          sha << File.read(file)
        end
      end
      sha.hexdigest
    end
  end
end
