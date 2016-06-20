module RunLoop
  # @!visibility private
  # A wrapper around codesign command line tool
  class Codesign

    # @!visibility private
    DEV_REGEX = /Authority=iPhone Developer:/

    # @!visibility private
    APP_STORE_REGEX = /Authority=Apple iPhone OS Application Signing/

    # @!visibility private
    DISTR_REGEX = /Authority=iPhone Distribution:/

    # @!visibility private
    NOT_SIGNED_REGEX = /code object is not signed at all/

    # @!visibility private
    def self.info(path)
      self.expect_path_exists(path)
      self.run_codesign_command(["--display", "--verbose=4", path])
    end

    # @!visibility private
    #
    # True if the asset is signed.
    def self.signed?(path)
      info = self.info(path)
      info[NOT_SIGNED_REGEX, 0] == nil
    end

    # @!visibility private
    #
    # True if the asset is signed with anything other than a dev cert.
    def self.distribution?(path)
      info = self.info(path)

      info[NOT_SIGNED_REGEX, 0] == nil &&
        info[DEV_REGEX, 0] == nil
    end

    # @!visibility private
    #
    # True if the asset is signed with a dev cert
    def self.developer?(path)
      info = self.info(path)
      info[DEV_REGEX, 0] != nil
    end

    private

    def self.expect_path_exists(path)
      if !File.exist?(path)
        raise ArgumentError,
%Q{There is no file or directory at path:

#{path}
}
      end
    end

    def self.run_codesign_command(args)
      if !args.is_a?(Array)
        raise ArgumentError, "Expected args: '#{args}' to be an Array"
      end

      xcrun = RunLoop::Xcrun.new
      cmd = ["codesign"] + args
      options = {:log_cmd => true}
      hash = xcrun.run_command_in_context(cmd, options)

      hash[:out]
    end
  end
end

