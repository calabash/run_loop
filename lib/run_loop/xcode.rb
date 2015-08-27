require 'open3'

module RunLoop

  # A model of the active Xcode version.
  class Xcode


    # Returns a version instance for `Xcode 7.0`; used to check for the
    # availability of features and paths to various items on the filesystem.
    #
    # @return [RunLoop::Version] 7.0
    def v70
      fetch_version(:v70)
    end

    # Returns a version instance for `Xcode 6.4`; used to check for the
    # availability of features and paths to various items on the filesystem.
    #
    # @return [RunLoop::Version] 6.4
    def v64
      fetch_version(:v64)
    end

    # Returns a version instance for `Xcode 6.3`; used to check for the
    # availability of features and paths to various items on the filesystem.
    #
    # @return [RunLoop::Version] 6.3
    def v63
      fetch_version(:v63)
    end

    # Returns a version instance for `Xcode 6.2`; used to check for the
    # availability of features and paths to various items on the filesystem.
    #
    # @return [RunLoop::Version] 6.2
    def v62
      fetch_version(:v62)
    end

    # Returns a version instance for `Xcode 6.1`; used to check for the
    # availability of features and paths to various items on the filesystem.
    #
    # @return [RunLoop::Version] 6.1
    def v61
      fetch_version(:v61)
    end

    # Returns a version instance for `Xcode 6.0`; used to check for the
    # availability of features and paths to various items on the filesystem.
    #
    # @return [RunLoop::Version] 6.0
    def v60
      fetch_version(:v60)
    end

    # Returns a version instance for `Xcode 5.1`; used to check for the
    # availability of features and paths to various items on the filesystem.
    #
    # @return [RunLoop::Version] 5.1
    def v51
      fetch_version(:v51)
    end

    # Returns a version instance for `Xcode 5.0`; used to check for the
    # availability of features and paths to various items on the filesystem.
    #
    # @return [RunLoop::Version] 5.0
    def v50
      fetch_version(:v50)
    end

    # Are we running Xcode 6.4 or above?
    #
    # @return [Boolean] `true` if the current Xcode version is >= 6.4
    def xcode_version_gte_64?
      @xcode_gte_64 ||= version >= v64
    end

    # Are we running Xcode 6.3 or above?
    #
    # @return [Boolean] `true` if the current Xcode version is >= 6.3
    def xcode_version_gte_63?
      @xcode_gte_63 ||= version >= v63
    end

    # Are we running Xcode 6.2 or above?
    #
    # @return [Boolean] `true` if the current Xcode version is >= 6.2
    def xcode_version_gte_62?
      @xcode_gte_62 ||= version >= v62
    end

    # Are we running Xcode 6.1 or above?
    #
    # @return [Boolean] `true` if the current Xcode version is >= 6.1
    def xcode_version_gte_61?
      @xcode_gte_61 ||= version >= v61
    end

    # Are we running Xcode 6 or above?
    #
    # @return [Boolean] `true` if the current Xcode version is >= 6.0
    def xcode_version_gte_6?
      @xcode_gte_6 ||= version >= v60
    end

    # Are we running Xcode 7 or above?
    #
    # @return [Boolean] `true` if the current Xcode version is >= 7.0
    def xcode_version_gte_7?
      @xcode_gte_7 ||= version >= v70
    end

    # Are we running Xcode 5.1 or above?
    #
    # @return [Boolean] `true` if the current Xcode version is >= 5.1
    def xcode_version_gte_51?
      @xcode_gte_51 ||= version >= v51
    end

    # Returns the current version of Xcode.
    #
    # @return [RunLoop::Version] The current version of Xcode as reported by
    #  `xcrun xcodebuild -version`.
    def version
      @xcode_version ||= lambda do
        execute_command(['-version']) do |stdout, _, _|
          version_string = stdout.read.chomp[/(\d.\d)(.\d)?/, 0]
          RunLoop::Version.new(version_string)
        end
      end.call
    end

    private

    attr_reader :xcode_versions

    def xcode_versions
      @xcode_versions ||= {}
    end

    def fetch_version(key)
      ensure_valid_version_key key
      value = xcode_versions[key]

      return value if value

      string = key.to_s
      string[0] = ''
      version_string = string.split(/(?!^)/).join('.')
      version = RunLoop::Version.new(version_string)
      xcode_versions[key] = version
      version
    end

    def ensure_valid_version_key(key)
      string = key.to_s
      if string.length != 3
        raise "Expected version key '#{key}' to have exactly 3 characters"
      end

      unless string[/v\d{2}/, 0]
        raise "Expected version key '#{key}' to match vXX pattern"
      end
    end

    def execute_command(args)
      Open3.popen3('xcrun', 'xcodebuild', *args) do |_, stdout, stderr, wait_thr|
        yield stdout, stderr, wait_thr
      end
    end
  end
end
