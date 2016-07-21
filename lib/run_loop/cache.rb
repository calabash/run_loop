require 'fileutils'
require 'digest/sha1'

module RunLoop

  # @!visibility private
  # A class for managing an on-disk hash table that represents the current
  # state of the :host strategy run-loop.  It is used by Calabash iOS
  # `console_attach` method.
  # @see http://calabashapi.xamarin.com/ios/Calabash/Cucumber/Core.html#console_attach-instance_method
  #
  # Marshal is safe to use here because:
  # 1. This code is not executed on the XTC.
  # 2. Users who muck about with this cache can only hurt themselves.
  class Cache

    # The path to the cache file.
    #
    # @!attribute [r] path
    # @return [String] An expanded path to the cache file.
    attr_reader :path

    # The directory where the cache is stored.
    # @return [String] Expanded path to the default cache directory.
    # @raise [RuntimeError] When the ~/.run_loop exists, but is not a directory.
    def self.default_directory
      run_loop_dir = File.join(RunLoop::Environment.user_home_directory, ".run-loop")
      if !File.exist?(run_loop_dir)
        FileUtils.mkdir(run_loop_dir)
      elsif !File.directory?(run_loop_dir)
        raise %Q[
Expected ~/.run_loop to be a directory.

RunLoop requires this directory to cache files
]

      end
      run_loop_dir
    end

    # The default cache.
    def self.default
      RunLoop::Cache.new(self.default_directory)
    end

    # Creates a new HostCache that is ready for IO.
    #
    # @param [String] directory The directory where the cache file is located.
    #  If the directory does not exist, it will be created.
    # @options [Hash] options Options to control the state of the new object.
    # @option [String] filename (host_run_loop.hash) The cache filename.
    # @option [Boolean] clear (false) If true, the current cache will be cleared.
    # @return [RunLoop::Cache] A cache that is ready for IO.
    def initialize(directory, options = {})
      sha1 = Digest::SHA1.hexdigest 'host_run_loop.hash'
      default_opts = {:filename => sha1,
                      :clear => false}
      merged_opts = default_opts.merge(options)

      dir_expanded = File.expand_path(directory)
      unless Dir.exist?(dir_expanded)
        FileUtils.mkdir_p(dir_expanded)
      end

      @path = File.join(dir_expanded, merged_opts[:filename])

      if merged_opts[:clear] && File.exist?(@path)
        FileUtils.rm_rf @path
      end
    end

    # @!visibility private
    def to_s
      "#<HostCache #{path}>"
    end

    # @!visibility private
    def inspect
      to_s
    end

    # Reads the current cache.
    # @return [Hash] A hash representation of the current state of the run-loop.
    def read
      if File.exist? path
        File.open(path) do |file|
          Marshal.load(file)
        end
      else
        self.write({})
        self.read
      end
    end

    # @!visibility private
    #
    # Writes `hash` as a serial object.  The existing data is overwritten.
    #
    # @param [Hash] hash The hash to write.
    # @raise [ArgumentError] The `hash` parameter must not be nil and it must
    #  be a Hash.
    # @raise [TypeError] If the hash contains objects that cannot be written
    #  by Marshal.dump.
    #
    # @return [Boolean] Returns true if `hash` was successfully Marshal.dump'ed.
    def write(hash)
      if hash.nil?
        raise ArgumentError, 'Expected the hash parameter to be non-nil'
      end

      unless hash.is_a?(Hash)
        raise ArgumentError, "Expected #{hash} to a Hash, but it is a #{hash.class}"
      end

      File.open(path, 'w+') do |file|
        Marshal.dump(hash, file)
      end
      true
    end

    # @!visibility private
    # Clears the current cache.
    # @return [Boolean] Returns true if the hash was cleared.
    def clear
      self.write({})
    end
  end

  # @!visibility private
  # Required for backward compatibility.
  # The only legitimate caller is in Calabash iOS Launcher#attach.
  class HostCache < RunLoop::Cache ; end
end
