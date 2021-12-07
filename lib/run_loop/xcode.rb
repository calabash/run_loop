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

    require "run_loop/regex"
    require "run_loop/shell"

    include RunLoop::Regex
    include RunLoop::Shell

    # Returns a String representation.
    def to_s
      "#<Xcode #{version.to_s}>"
    end

    # Returns debug String representation
    def inspect
      to_s
    end

    # Returns a version instance for Xcode 12.0; used to check for the
    # availability of features and paths to various items on the filesystem
    #
    # @return [RunLoop::Version] 12.0
    def v120
      fetch_version(:v120)
    end

    # Returns a version instance for Xcode 11.0; used to check for the
    # availability of features and paths to various items on the filesystem
    #
    # @return [RunLoop::Version] 11.0
    def v110
      fetch_version(:v110)
    end

  # Returns a version instance for Xcode 10.3; used to check for the
    # availability of features and paths to various items on the filesystem
    #
    # @return [RunLoop::Version] 10.3
    def v103
      fetch_version(:v103)
    end

    # Returns a version instance for Xcode 10.2; used to check for the
    # availability of features and paths to various items on the filesystem
    #
    # @return [RunLoop::Version] 10.2
    def v102
      fetch_version(:v102)
    end

    # Returns a version instance for Xcode 10.0; used to check for the
    # availability of features and paths to various items on the filesystem
    #
    # @return [RunLoop::Version] 10.0
    def v100
      fetch_version(:v100)
    end

    # Returns a version instance for Xcode 9.4; used to check for the
    # availability of features and paths to various items on the filesystem
    #
    # @return [RunLoop::Version] 9.4
    def v94
      fetch_version(:v94)
    end

    # Returns a version instance for Xcode 9.3; used to check for the
    # availability of features and paths to various items on the filesystem
    #
    # @return [RunLoop::Version] 9.3
    def v93
      fetch_version(:v93)
    end

    # Returns a version instance for Xcode 9.2; used to check for the
    # availability of features and paths to various items on the filesystem
    #
    # @return [RunLoop::Version] 9.2
    def v92
      fetch_version(:v92)
    end

    # Returns a version instance for Xcode 9.1; used to check for the
    # availability of features and paths to various items on the filesystem
    #
    # @return [RunLoop::Version] 9.1
    def v91
      fetch_version(:v91)
    end

    # Returns a version instance for Xcode 9.0; used to check for the
    # availability of features and paths to various items on the filesystem
    #
    # @return [RunLoop::Version] 9.0
    def v90
      fetch_version(:v90)
    end

    # Returns a version instance for Xcode 8.3; used to check for the
    # availability of features and paths to various items on the filesystem
    #
    # @return [RunLoop::Version] 8.3
    def v83
      fetch_version(:v83)
    end

    # Returns a version instance for Xcode 8.2; used to check for the
    # availability of features and paths to various items on the filesystem
    #
    # @return [RunLoop::Version] 8.2
    def v82
      fetch_version(:v82)
    end

    # Returns a version instance for `Xcode 8.1`; used to check for the
    # availability of features and paths to various items on the filesystem.
    #
    # @return [RunLoop::Version] 8.1
    def v81
      fetch_version(:v81)
    end

    # Returns a version instance for `Xcode 8.0`; used to check for the
    # availability of features and paths to various items on the filesystem.
    #
    # @return [RunLoop::Version] 8.0
    def v80
      fetch_version(:v80)
    end

    # Is the active Xcode version 12.0 or above?
    #
    # @return [Boolean] `true` if the current Xcode version is >= 12.0
    def version_gte_120?
      version >= v120
    end

    # Is the active Xcode version 11.0 or above?
    #
    # @return [Boolean] `true` if the current Xcode version is >= 11.0
    def version_gte_110?
      version >= v110
    end

    # Is the active Xcode version 10.3 or above?
    #
    # @return [Boolean] `true` if the current Xcode version is >= 10.3
    def version_gte_103?
      version >= v103
    end

    # Is the active Xcode version 10.2 or above?
    #
    # @return [Boolean] `true` if the current Xcode version is >= 10.2
    def version_gte_102?
      version >= v102
    end

    # Is the active Xcode version 10.0 or above?
    #
    # @return [Boolean] `true` if the current Xcode version is >= 10.0
    def version_gte_100?
      version >= v100
    end

    # Is the active Xcode version 9.4 or above?
    #
    # @return [Boolean] `true` if the current Xcode version is >= 9.4
    def version_gte_94?
      version >= v94
    end

    # Is the active Xcode version 9.3 or above?
    #
    # @return [Boolean] `true` if the current Xcode version is >= 9.3
    def version_gte_93?
      version >= v93
    end

    # Is the active Xcode version 9.2 or above?
    #
    # @return [Boolean] `true` if the current Xcode version is >= 9.2
    def version_gte_92?
      version >= v92
    end

    # Is the active Xcode version 9.1 or above?
    #
    # @return [Boolean] `true` if the current Xcode version is >= 9.1
    def version_gte_91?
      version >= v91
    end

    # Is the active Xcode version 9.0 or above?
    #
    # @return [Boolean] `true` if the current Xcode version is >= 9.0
    def version_gte_90?
      version >= v90
    end

    # Is the active Xcode version 8.3 or above?
    #
    # @return [Boolean] `true` if the current Xcode version is >= 8.3
    def version_gte_83?
      version >= v83
    end

    # Is the active Xcode version 8.2 or above?
    #
    # @return [Boolean] `true` if the current Xcode version is >= 8.2
    def version_gte_82?
      version >= v82
    end

    # Is the active Xcode version 8.1 or above?
    #
    # @return [Boolean] `true` if the current Xcode version is >= 8.1
    def version_gte_81?
      version >= v81
    end

    # Is the active Xcode version 8.0 or above?
    #
    # @return [Boolean] `true` if the current Xcode version is >= 8.0
    def version_gte_8?
      version >= v80
    end

    # Returns the current version of Xcode.
    #
    # @return [RunLoop::Version] The current version of Xcode as reported by
    #  `xcrun xcodebuild -version`.
    def version
      @xcode_version ||= begin
        if RunLoop::Environment.xtc?
          RunLoop::Version.new("0.0.0")
        else
          version = RunLoop::Version.new("0.0.0")
          begin
            args = ["xcrun", "xcodebuild", "-version"]
            hash = run_shell_command(args)
            if hash[:exit_status] != 0
              RunLoop.log_error("xcrun xcodebuild -version exited non-zero")
            else
              out = hash[:out]
              version_string = out.chomp[VERSION_REGEX, 0]
              version = RunLoop::Version.new(version_string)
            end
          rescue RuntimeError => e
            RunLoop.log_error(%Q[
Could not find Xcode version:

  #{e.class}: #{e.message}
])
          end
          version
        end
      end
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
    #
    # @raise [RuntimeError] If path to Xcode.app/Contents/Developer
    #   cannot be determined.
    def developer_dir
      @xcode_developer_dir ||= begin
        if RunLoop::Environment.developer_dir
          path = RunLoop::Environment.developer_dir
        else
          path = xcode_select_path
        end

        require 'pathname'
        path = Pathname.new(path).realpath.to_s

        if !File.directory?(path)
          raise RuntimeError,
%Q{Cannot determine the active Xcode.  Expected an Xcode here:

#{path}

Check the value of xcode-select:

# Does this resolve to a valid Xcode.app/Contents/Developer path?
$ xcode-select --print-path

Is the DEVELOPER_DIR variable set in your environment?  You would
only use this if you have multiple Xcode's installed.

$ echo $DEVELOPER_DIR

See the man pages for xcrun and xcode-select for details.

$ man xcrun
$ man xcode-select
}
        end
        path
      end
    end

    def core_simulator_dir
      if version_gte_110?
        core_simulator_dir = File.join(developer_dir,
                                      'Platforms', 'iPhoneOS.platform', 'Library',
                                      'Developer', 'CoreSimulator')
      else
        core_simulator_dir = File.join(developer_dir,
                                      'Platforms', 'iPhoneOS.platform', 'Developer',
                                      'Library', 'CoreSimulator')
      end
      File.expand_path(core_simulator_dir)
    end

    def ios_version
      xcode_version = version
      sim_major = xcode_version.major + 2
      sim_minor = xcode_version.minor
      if xcode_version.major == 13
        sim_minor = 0
      end
      if xcode_version == v103
        sim_minor = 4
      end

      return RunLoop::Version.new("#{sim_major}.#{sim_minor}")
    end

    def default_device
      xcode_version = version

      # Xcode 13.
      if xcode_version.major == 13
        return "iPhone 13"
      end

      # Xcode 12.
      if xcode_version.major == 12 && xcode_version.minor >= 2
        return "iPhone 12"
      elsif xcode_version.major == 12 && xcode_version.minor < 2
        return "iPhone 11"
      end

      # Xcode 11.
      if xcode_version.major == 11
        return "iPhone 11"
      end

      # Xcode 10.
      if xcode_version.major == 10
        if xcode_version.minor >= 2
          return "iPhone Xs"
        else
          return "iPhone XS"
        end
      end

      # Xcode < 10.
      return "iPhone #{xcode_version.major - 1}"
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
      version_string = string.split(/^(10|11)*|(?!^)/).reject(&:empty?).join('.')
      version = RunLoop::Version.new(version_string)
      xcode_versions[key] = version
      version
    end

    def ensure_valid_version_key(key)
      string = key.to_s

      if !string.start_with?("v")
        raise "Expected version key to start with 'v'"
      end

      if string.start_with?("v10") || string.start_with?("v11") || string.start_with?("v12")
        expected_length = 4
        regex = /v\d{3}/
      else
        expected_length = 3
        regex = /v\d{2}/
      end

      if string.length != expected_length
        raise "Expected version key '#{key}' to be exactly #{expected_length} chars long"
      end

      if !string[regex]
        raise "Expected version key '#{key}' to match this pattern: #{regex}"
      end
    end

    def xcode_select_path
      hash = run_shell_command(["xcode-select", "--print-path"], {log_cmd: true})
      hash[:out].chomp
    end
  end
end
