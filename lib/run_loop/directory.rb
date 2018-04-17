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
    # @param options Control the behavior of the method.
    # @option options :handle_errors_by (:raising) Controls what to do when
    #   File.read causes an error.  The default behavior is to raise.  Other
    #   options are: :logging and :ignoring.  Logging will only happen if
    #   running in debug mode.
    #
    # @raise ArgumentError When `path` is not a directory or path does not exist.
    # @raise ArgumentError When options[:handle_errors_by] has n unsupported value.
    def self.directory_digest(path, options={})
      default_options = {
        :handle_errors_by => :raising
      }

      merged_options = default_options.merge(options)
      handle_errors_by = merged_options[:handle_errors_by]
      unless [:raising, :logging, :ignoring].include?(handle_errors_by)
        raise ArgumentError,
%Q{Expected :handle_errors_by to be :raising, :logging, or :ignoring;
found '#{handle_errors_by}'
}
      end

      unless File.exist?(path)
        raise ArgumentError, "Expected '#{path}' to exist"
      end

      unless File.directory?(path)
        raise ArgumentError, "Expected '#{path}' to be a directory"
      end

      entries = self.recursive_glob_for_entries(path).sort

      if entries.empty?
        raise ArgumentError, "Expected a non-empty dir at '#{path}' found '#{entries}'"
      end

      debug = RunLoop::Environment.debug?

      file_shas = []
      cumulative = OpenSSL::Digest::SHA256.new
      entries.each do |path|
        if !self.skip_file?(path, "SHA256", debug)
          begin
            file_sha = OpenSSL::Digest::SHA256.new
            contents = File.read(path, {mode: "rb"})
            file_sha << contents
            cumulative << contents
            file_shas << [file_sha.hexdigest]
          rescue => e
            case handle_errors_by
            when :logging
              message =
%Q{RunLoop::Directory.directory_digest raised an error:

         #{e}

while trying to find the SHA of this file:

         #{path}

This is not a fatal error; it can be ignored.
}
              RunLoop.log_debug(message)
            when :raising
              raise e.class, e.message
            when :ignoring
               # nop
            else
               # nop
            end
          end
        end
      end
      digest_of_digests = OpenSSL::Digest::SHA256.new
      digest_of_digests << file_shas.join("\n")
      # We have at least one example where the cumulative digest has an
      # unexpected value when computing the digest of an installed .app on an
      # iOS Simulator.  I want return the cumulative.hexdigest in case there is
      # a client (end user) who is using this method.
      return digest_of_digests.hexdigest, cumulative.hexdigest
    end

    def self.size(path, format)

      allowed_formats = [:bytes, :kb, :mb, :gb]
      unless allowed_formats.include?(format)
        raise ArgumentError, "Expected '#{format}' to be one of #{allowed_formats.join(', ')}"
      end

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

      size = self.iterate_for_size(entries)

      case format
        when :bytes
          size
        when :kb
          size/1000.0
        when :mb
          size/1000.0/1000.0
        when :gb
          size/1000.0/1000.0/1000.0
        else
          # Not expected to reach this.
          size
      end
    end

    private

    def self.skip_file?(file, task, debug)
      skip = false
      begin
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
      rescue => e
        skip = true
        RunLoop.log_debug("Directory.skip_file? rescued an ignorable error.")
        RunLoop.log_debug("#{e.class}: #{e.message}")
      end
      skip
    end

    def self.iterate_for_size(entries)
      debug = RunLoop::Environment.debug?
      size = 0
      entries.each do |file|
        unless self.skip_file?(file, "SIZE", debug)
          begin
            size = size + File.size(file)
          rescue => e
            RunLoop.log_debug("Directory.iterate_for_size? rescued an ignorable error.")
            RunLoop.log_debug("#{e.class}: #{e.message}")
          end
        end
      end
      size
    end
  end
end
