module RunLoop

  # @!visibility private
  # A class for managing an on-disk cache.
  class Cache

    require 'fileutils'

    def initialize(path)
      @path = path
    end

    def clear
      raise NotImplementedError, 'Subclasses must implement #clear'
    end

    def refresh
      raise NotImplementedError, 'Subclasses must implement #refresh'
    end

    # Reads the current cache.
    # @return [Hash] A hash representation of the cache on disk.
    def read
      if File.exist? path
        File.open(path) do |file|
          Marshal.load(file)
        end
      else
        write({})
      end
    end

    private

    attr_reader :path

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
    # @return [Hash] Returns the `hash` argument.
    def write(hash)
      if hash.nil?
        raise ArgumentError, 'Expected the hash parameter to be non-nil'
      end

      unless hash.is_a?(Hash)
        raise ArgumentError, "Expected #{hash} to a Hash, but it is a #{hash.class}"
      end

      directory = File.dirname(path)
      unless File.exist?(directory)
        FileUtils.mkdir_p(directory)
      end

      File.open(path, 'w') do |file|
        Marshal.dump(hash, file)
      end
      hash
    end
  end
end
