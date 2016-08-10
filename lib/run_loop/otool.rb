module RunLoop
  # @!visibility private
  #
  # A class for interacting with otool
  class Otool

    # @!visibility private
    # @param [RunLoop::Xcode] xcode An instance of Xcode
    def initialize(xcode)
      @xcode = xcode
    end

    # @!visibility private
    def to_s
      "#<OTOOL: Xcode #{xcode.version.to_s}>"
    end

    # @!visibility private
    def inspect
      to_s
    end

    # @!visibility private
    def executable?(path)
      expect_valid_path!(path)
      !arch_info(path)[/is not an object file/, 0]
    end

    private

    # @!visibility private
    attr_reader :xcode, :command_name

    # @!visibility private
    def arch_info(path)
      args = [command_name, "-hv", "-arch", "all", path]
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

      hash[:out]
    end

    # @!visibility private
    def expect_valid_path!(path)
      return true if File.exist?(path) && !File.directory?(path)
      raise ArgumentError, %Q[
File:

#{path}

must exist and not be a directory.

]
    end

    # @!visibility private
    def xcrun
      @xcrun ||= RunLoop::Xcrun.new
    end

    # @!visibility private
    def xcode
      @xcode
    end

    # @!visibility private
    def command_name
      @command_name ||= begin
        if xcode.version_gte_8?
          "otool-classic"
        else
          "otool"
        end
      end
    end
  end
end
