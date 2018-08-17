module RunLoop
  # @!visibility private
  #
  # A class for interacting with the strings tool
  class Strings

    # @!visibility private
    attr_reader :path

    # @!visibility private
    def initialize(path)
      @path = path

      if !Strings.valid_path?(path)
        raise ArgumentError,
%Q{File:

#{path}

must exist and not be a directory.
}
      end
    end

    # @!visibility private
    def to_s
      "#<STRINGS: #{path}>"
    end

    # @!visibility private
    def inspect
      to_s
    end

    # @!visibility private
    #
    # @return [RunLoop::Version] A version instance or nil if the file
    #   at path does not contain server version information.
    def server_version
      regex = /CALABASH VERSION: (\d+\.\d+\.\d+(\.pre\d+)?)/
      match = dump[regex, 0]

      if match
        str = match.split(":")[1]
        RunLoop::Version.new(str)
      else
        nil
      end
    end

    # @!visibility private
    #
    # @return [RunLoop::Version] A version instance or nil if the file
    #   at path does not contain server version information.
    def server_id
      regex = /LPSERVERID=[a-f0-9]{40}(-dirty)?/
      match = dump[regex, 0]

      if match
        match.split("=")[1]
      else
        nil
      end
    end

    private

    # @!visibility private
    def dump
      args = ["strings", path]
      opts = { :log_cmd => true }

      hash = xcrun.run_command_in_context(args, opts)

      if hash[:exit_status] != 0
        raise RuntimeError,
%Q{Could not get strings info from file:

#{path}

#{args.join(" ")}

exited #{hash[:exit_status]} with the following output:

#{hash[:out]}
}
      end

      @dump = hash[:out]
    end

    # @!visibility private
    def self.valid_path?(path)
      File.exist?(path) && !File.directory?(path)
    end

    # @!visibility private
    def xcrun
      RunLoop::Xcrun.new
    end
  end
end

