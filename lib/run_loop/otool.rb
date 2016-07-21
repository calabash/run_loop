module RunLoop
  # @!visibility private
  #
  # A class for interacting with otool
  class Otool

    # @!visibility private
    attr_reader :path

    # @!visibility private
    def initialize(path)
      @path = path

      if !Otool.valid_path?(path)
        raise ArgumentError,
%Q{File:

#{path}

must exist and not be a directory.
}
      end
    end

    # @!visibility private
    def to_s
      "#<OTOOL: #{path}>"
    end

    # @!visibility private
    def inspect
      to_s
    end

    # @!visibility private
    def executable?
      !arch_info[/is not an object file/, 0]
    end

    private

    # @!visibility private
    def arch_info
      args = ["otool", "-hv", "-arch", "all", path]
      opts = { :log_cmd => false }

      hash = xcrun.run_command_in_context(args, opts)

      if hash[:exit_status] != 0
        raise RuntimeError,
%Q{Could not get arch info from file:

#{path}

#{args.join(" ")}

exited #{hash[:exit_status]} with the following output:

#{hash[:out]}
}
      end

      @arch_info = hash[:out]
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
