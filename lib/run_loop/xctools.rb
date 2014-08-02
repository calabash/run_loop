require 'open3'
require 'retriable'

module RunLoop

  # A class for interacting with the Xcode tools.
  #
  # @note All command line tools are run in the context of `xcrun`.
  #
  # Throughout this class's documentation, there are references to the
  # _current version of Xcode_.  The current Xcode version is the one returned
  # by `xcrun xcodebuild`.  The current Xcode version can be set using
  # `xcode-select` or overridden using the `DEVELOPER_DIR`.
  class XCTools

    # Returns a version instance for `Xcode 6.0`; used to check for the
    # availability of features and paths to various items on the filesystem.
    #
    # @return [RunLoop::Version] 6.0
    def v60
      @xc60 ||= Version.new('6.0')
    end

    # Returns a version instance for `Xcode 5.1`; used to check for the
    # availability of features and paths to various items on the filesystem.
    #
    # @return [RunLoop::Version] 5.1
    def v51
      @xc51 ||= Version.new('5.1')
    end

    # Returns a version instance for `Xcode 5.0`; ; used to check for the
    # availability of features and paths to various items on the filesystem.
    #
    # @return [RunLoop::Version] 5.0
    def v50
      @xc50 ||= Version.new('5.0')
    end

    # Returns the current version of Xcode.
    #
    # @return [RunLoop::Version] The current version of Xcode as reported by
    #  `xcrun xcodebuild -version`.
    def xcode_version
      @xcode_version ||= lambda {
        xcode_build_output = `xcrun xcodebuild -version`.split(/\s/)[1]
        Version.new(xcode_build_output)
      }.call
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
    def xcode_developer_dir
      @xcode_developer_dir ||=
            if ENV['DEVELOPER_DIR']
              ENV['DEVELOPER_DIR']
            else
              # fall back to xcode-select
              `xcode-select --print-path`.chomp
            end
    end

    # Method for interacting with instruments.
    #
    # @example Getting a runnable command for instruments
    #  instruments #=> 'xcrun instruments'
    #
    # @example Getting a the version of instruments.
    #  instruments(:version) #=> 5.1.1 - a Version object
    #
    # @example Getting list of known simulators.
    #  instruments(:sims) #=> < list of known simulators >
    #
    # @param [Version] cmd controls the return value.  currently accepts `nil`,
    #   `:sims`, `:templates`, and `:version` as valid parameters
    # @return [String,Array,Version] based on the value of `cmd` version, a list known
    #   simulators, the version of current instruments tool, or the path to the
    #   instruments binary.
    # @raise [ArgumentError] if invalid `cmd` is passed
    def instruments(cmd=nil)
      instruments = 'xcrun instruments'
      return instruments if cmd == nil

      case cmd
        when :version
          @instruments_version ||= lambda {
            # Xcode 6 can print out some very strange output, so we have to retry.
            Retriable.retriable({:tries => 5}) do
              Open3.popen3("#{instruments}") do |_, _, stderr, _|
                version_str = stderr.read.chomp.split(/\s/)[2]
                Version.new(version_str)
              end
            end
          }.call
        when :sims
          @instruments_sims ||=  lambda {
            devices = `#{instruments} -s devices`.chomp.split("\n")
            devices.select { |device| device.downcase.include?('simulator') }
          }.call

        when :templates
          @instruments_templates ||= lambda {
            cmd = "#{instruments} -s templates"
            if self.xcode_version >= self.v51
              `#{cmd}`.split("\n").delete_if do |path|
                not path =~ /tracetemplate/
              end.map { |elm| elm.strip }
            else
              # prints to $stderr (>_>) - seriously?
              Open3.popen3(cmd) do |_, _, stderr, _|
                stderr.read.chomp.split(/(,|\(|")/).map do |elm|
                   elm.strip
                end.delete_if { |path| not path =~ /tracetemplate/ }
              end
            end
          }.call
        else
          candidates = [:version, :sims]
          raise(ArgumentError, "expected '#{cmd}' to be one of '#{candidates}'")
      end
    end

    # Does the instruments `version` accept the -s flag?
    #
    # @example
    #  instruments_supports_hyphen_s?('4.6.3') => false
    #  instruments_supports_hyphen_s?('5.0.2') => true
    #  instruments_supports_hyphen_s?('5.1')   => true
    #
    # @param [String, Version] version (instruments(:version))
    #   a major.minor[.patch] version string or a Version object
    #
    # @return [Boolean] true if the version is >= 5.*
    def instruments_supports_hyphen_s?(version=instruments(:version))
      @instruments_supports_hyphen_s ||= lambda {
        if version.is_a? String
          _version = Version.new(version)
        else
          _version = version
        end
        _version >= Version.new('5.1')
      }.call
    end
  end
end
