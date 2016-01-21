require 'open3'

module RunLoop

  # A model of the active Xcode version.
  #
  # @note All command line tools are run in the context of `xcrun`.
  #
  # Throughout this class's documentation, there are references to the
  # _active version of Xcode_.  The active Xcode version is the one returned
  # by `xcrun xcodebuild`.  The current Xcode version can be set using
  # `xcode-select` or overridden using the `DEVELOPER_DIR`.
  class Xcode

    include RunLoop::Regex

    # Returns a String representation.
    def to_s
      "#<Xcode #{version.to_s}>"
    end

    # Returns debug String representation
    def inspect
      to_s
    end

    # Returns a version instance for `Xcode 7.3`; used to check for the
    # availability of features and paths to various items on the filesystem.
    #
    # @return [RunLoop::Version] 7.3
    def v73
      fetch_version(:v73)
    end

    # Returns a version instance for `Xcode 7.2`; used to check for the
    # availability of features and paths to various items on the filesystem.
    #
    # @return [RunLoop::Version] 7.2
    def v72
      fetch_version(:v72)
    end

    # Returns a version instance for `Xcode 7.1`; used to check for the
    # availability of features and paths to various items on the filesystem.
    #
    # @return [RunLoop::Version] 7.1
    def v71
      fetch_version(:v71)
    end

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

    # Is the active Xcode version 7.3 or above?
    #
    # @return [Boolean] `true` if the current Xcode version is >= 7.3
    def version_gte_73?
      version >= v73
    end

    # Is the active Xcode version 7.2 or above?
    #
    # @return [Boolean] `true` if the current Xcode version is >= 7.2
    def version_gte_72?
      version >= v72
    end

    # Is the active Xcode version 7.1 or above?
    #
    # @return [Boolean] `true` if the current Xcode version is >= 7.1
    def version_gte_71?
      version >= v71
    end

    # Is the active Xcode version 7 or above?
    #
    # @return [Boolean] `true` if the current Xcode version is >= 7.0
    def version_gte_7?
      version >= v70
    end

    # Is the active Xcode version 6.4 or above?
    #
    # @return [Boolean] `true` if the current Xcode version is >= 6.4
    def version_gte_64?
      version >= v64
    end

    # Is the active Xcode version 6.3 or above?
    #
    # @return [Boolean] `true` if the current Xcode version is >= 6.3
    def version_gte_63?
      version >= v63
    end

    # Is the active Xcode version 6.2 or above?
    #
    # @return [Boolean] `true` if the current Xcode version is >= 6.2
    def version_gte_62?
      version >= v62
    end

    # Is the active Xcode version 6.1 or above?
    #
    # @return [Boolean] `true` if the current Xcode version is >= 6.1
    def version_gte_61?
      version >= v61
    end

    # Is the active Xcode version 6 or above?
    #
    # @return [Boolean] `true` if the current Xcode version is >= 6.0
    def version_gte_6?
      version >= v60
    end

    # Is the active Xcode version 5.1 or above?
    #
    # @return [Boolean] `true` if the current Xcode version is >= 5.1
    def version_gte_51?
      version >= v51
    end

    # Returns the current version of Xcode.
    #
    # @return [RunLoop::Version] The current version of Xcode as reported by
    #  `xcrun xcodebuild -version`.
    def version
      @xcode_version ||= lambda do
        execute_command(['-version']) do |stdout, _, _|
          version_string = stdout.read.chomp[VERSION_REGEX, 0]
          RunLoop::Version.new(version_string)
        end
      end.call
    end

    # Is this a beta version of Xcode?
    #
    # @note Relies on Xcode beta versions having and app bundle named Xcode-Beta.app
    # @return [Boolean] True if the Xcode version is beta.
    def beta?
      developer_dir[/Xcode-[Bb]eta.app/, 0]
    end

    # Returns the path to the current developer directory.
    #
    # From the man pages:
    #
    # ```
    # $ man xcode-select
    # DEVELOPER_DIR
    # Overrides the active developer directory. When DEVELOPER_DIR is set,
    # its value will be used instead of the system-wide active developer
    # directory.
    #```
    #
    # @return [String] path to current developer directory
    def developer_dir
      @xcode_developer_dir ||=
            if RunLoop::Environment.developer_dir
              RunLoop::Environment.developer_dir
            else
              xcode_select_path
            end
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

    def xcode_select_path
      Open3.popen3('xcode-select', '--print-path') do |_, stdout, _, _|
        stdout.read.chomp
      end
    end
  end
end
