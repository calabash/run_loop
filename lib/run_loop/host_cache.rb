require 'fileutils'

module RunLoop

  # A class for managing an on-disk hash table that represents the current
  # state of the :host strategy run-loop.  It is used by Calabash iOS
  # `console_attach` method.
  # @see http://calabashapi.xamarin.com/ios/Calabash/Cucumber/Core.html#console_attach-instance_method
  #
  # Marshal is safe to use here because:
  # 1. This code is not executed on the XTC.
  # 2. Users who muck about with this cache can only hurt themselves.
  class HostCache

    # The path to the cache file.
    #
    # @!attribute [r] path
    # @return [String] An expanded path to the cache file.
    attr_reader :path

    # The directory where the cache is stored.
    # @return [String] Expanded path to the default cache directory.
    def self.default_directory
      File.expand_path('/tmp/run-loop-host-cache')
    end

    # The default cache.
    def self.default
      RunLoop::HostCache.new(self.default_directory)
    end

    # Creates a new HostCache that is ready for IO.
    #
    # @param [String] directory The directory where the cache file is located.
    #  If the directory does not exist, it will be created.
    # @options [Hash] options Options to control the state of the new object.
    # @option [String] filename (host_run_loop.hash) The cache filename.
    # @option [Boolean] clear (false) If true, the current cache will be cleared.
    # @return [RunLoop::HostCache] A cache that is ready for IO.
    def initialize(directory, options = {})
      default_opts = {:filename => 'host_run_loop.hash',
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

    # Reads the current cache.
    # @return [Hash] A hash representation of the current state of the run-loop.
    def read
      if File.exist? @path
        File.open(@path) do |file|
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

      File.open(@path, 'w+') do |file|
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
end
