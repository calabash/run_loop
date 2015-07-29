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
  #
  # @todo Refactor instruments related code to instruments class.
  class XCTools

    # Returns a version instance for `Xcode 7.0`; used to check for the
    # availability of features and paths to various items on the filesystem.
    #
    # @return [RunLoop::Version] 7.0
    def v70
      @xc70 ||= RunLoop::Version.new('7.0')
    end

    # Returns a version instance for `Xcode 6.4`; used to check for the
    # availability of features and paths to various items on the filesystem.
    #
    # @return [RunLoop::Version] 6.3
    def v64
      @xc64 ||= RunLoop::Version.new('6.4')
    end

    # Returns a version instance for `Xcode 6.3`; used to check for the
    # availability of features and paths to various items on the filesystem.
    #
    # @return [RunLoop::Version] 6.3
    def v63
      @xc63 ||= RunLoop::Version.new('6.3')
    end

    # Returns a version instance for `Xcode 6.2`; used to check for the
    # availability of features and paths to various items on the filesystem.
    #
    # @return [RunLoop::Version] 6.2
    def v62
      @xc62 ||= RunLoop::Version.new('6.2')
    end

    # Returns a version instance for `Xcode 6.1`; used to check for the
    # availability of features and paths to various items on the filesystem.
    #
    # @return [RunLoop::Version] 6.1
    def v61
      @xc61 ||= RunLoop::Version.new('6.1')
    end

    # Returns a version instance for `Xcode 6.0`; used to check for the
    # availability of features and paths to various items on the filesystem.
    #
    # @return [RunLoop::Version] 6.0
    def v60
      @xc60 ||= RunLoop::Version.new('6.0')
    end

    # Returns a version instance for `Xcode 5.1`; used to check for the
    # availability of features and paths to various items on the filesystem.
    #
    # @return [RunLoop::Version] 5.1
    def v51
      @xc51 ||= RunLoop::Version.new('5.1')
    end

    # Returns a version instance for `Xcode 5.0`; ; used to check for the
    # availability of features and paths to various items on the filesystem.
    #
    # @return [RunLoop::Version] 5.0
    def v50
      @xc50 ||= RunLoop::Version.new('5.0')
    end

    # Are we running Xcode 6.4 or above?
    #
    # @return [Boolean] `true` if the current Xcode version is >= 6.4
    def xcode_version_gte_64?
      @xcode_gte_64 ||= xcode_version >= v64
    end

    # Are we running Xcode 6.3 or above?
    #
    # @return [Boolean] `true` if the current Xcode version is >= 6.3
    def xcode_version_gte_63?
      @xcode_gte_63 ||= xcode_version >= v63
    end

    # Are we running Xcode 6.2 or above?
    #
    # @return [Boolean] `true` if the current Xcode version is >= 6.2
    def xcode_version_gte_62?
      @xcode_gte_62 ||= xcode_version >= v62
    end

    # Are we running Xcode 6.1 or above?
    #
    # @return [Boolean] `true` if the current Xcode version is >= 6.1
    def xcode_version_gte_61?
      @xcode_gte_61 ||= xcode_version >= v61
    end

    # Are we running Xcode 6 or above?
    #
    # @return [Boolean] `true` if the current Xcode version is >= 6.0
    def xcode_version_gte_6?
      @xcode_gte_6 ||= xcode_version >= v60
    end

    # Are we running Xcode 7 or above?
    #
    # @return [Boolean] `true` if the current Xcode version is >= 7.0
    def xcode_version_gte_7?
      @xcode_gte_7 ||= xcode_version >= v70
    end

    # Are we running Xcode 5.1 or above?
    #
    # @return [Boolean] `true` if the current Xcode version is >= 5.1
    def xcode_version_gte_51?
      @xcode_gte_51 ||= xcode_version >= v51
    end

    # Returns the current version of Xcode.
    #
    # @return [RunLoop::Version] The current version of Xcode as reported by
    #  `xcrun xcodebuild -version`.
    def xcode_version
      @xcode_version ||= lambda {
        xcode_build_output = `xcrun xcodebuild -version`.split(/\s/)[1]
        RunLoop::Version.new(xcode_build_output)
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
            if RunLoop::Environment.developer_dir
              RunLoop::Environment.developer_dir
            else
              # fall back to xcode-select
              `xcode-select --print-path`.chomp
            end
    end

    # Find the localized name for a given key_code
    #
    # @example
    #  lookup_localization_name('delete.key', 'da') => 'Slet'
    #
    # @param [String] key_code the localization signifier, e.g. 'delete.key'
    # @param [String] localized_lang an iso language code returned by calabash ios server
    #
    # @return [String] the localized name
    def lookup_localization_name(key_code, localized_lang)

      l10n_path = uikit_bundle_l10n_path

      lang_dir_name = "#{localized_lang}.lproj".sub('-','_')

      if(File.exists?(File.join(l10n_path, lang_dir_name)))
        return key_name_lookup_table(lang_dir_name)[key_code]
      end

      two_char_country_code = localized_lang.split('-')[0]
      lang_dir_name = "#{two_char_country_code}.lproj"
      if(File.exists?(File.join(l10n_path, lang_dir_name)))
        return key_name_lookup_table(lang_dir_name)[key_code]
      end

      if is_full_name?(two_char_country_code)
        return key_name_lookup_table("#{@@full_name_lookup[two_char_country_code]}.lproj")[key_code]
      end

      return nil
    end


    # Is this a beta version of Xcode?
    #
    # @note Relies on Xcode beta versions having and app bundle named Xcode-Beta.app
    # @return [Boolean] True if the Xcode version is beta.
    def xcode_is_beta?
      @xcode_is_beta ||= lambda {
        (xcode_developer_dir =~ /Xcode-[Bb]eta.app/) != nil
      }.call
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
    # @example Getting list of physical devices.
    #  instruments(:devices) #> < list of physical devices >
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

      # Xcode 6 GM is spamming "WebKit Threading Violations"
      stderr_filter = lambda { |stderr|
        stderr.read.strip.split("\n").each do |line|
          unless line[/WebKit Threading Violation/, 0]
            $stderr.puts line
          end
        end
      }
      case cmd
        when :version
          @instruments_version ||= lambda {
            # Xcode 6 can print out some very strange output, so we have to retry.
            Retriable.retriable({:tries => 5}) do
              Open3.popen3("#{instruments}") do |_, _, stderr, _|
                version_str = stderr.read.chomp.split(/\s/)[2]
                RunLoop::Version.new(version_str)
              end
            end
          }.call
        when :sims
          @instruments_sims ||=  lambda {
            # Instruments 6 spams a lot of error messages.  I don't like to
            # hide them, but they seem to be around to stay (Xcode 6 GM).
            cmd = "#{instruments} -s devices"
            Open3.popen3(cmd) do |_, stdout, stderr, _|
              stderr_filter.call(stderr)
              devices = stdout.read.chomp.split("\n")
              devices.select { |device| device.downcase.include?('simulator') }
            end
          }.call

        when :templates
          @instruments_templates ||= lambda {
            cmd = "#{instruments} -s templates"
            if self.xcode_version >= self.v60
              Open3.popen3(cmd) do |_, stdout, stderr, _|
                stderr_filter.call(stderr)
                stdout.read.chomp.split("\n").map { |elm| elm.strip.tr('"', '') }
              end
            elsif self.xcode_version >= self.v51
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

        when :devices
          @devices ||= lambda {
            cmd = "#{instruments} -s devices"
            Open3.popen3(cmd) do |_, stdout, stderr, _|
              stderr_filter.call(stderr)
              all = stdout.read.chomp.split("\n")
              valid = all.select { |device| device =~ /[a-f0-9]{40}/ }
              valid.map do |device|
                udid = device[/[a-f0-9]{40}/, 0]
                version = device[/(\d\.\d(\.\d)?)/, 0]
                name = device.split('(').first.strip
                RunLoop::Device.new(name, version, udid)
              end
            end
          }.call
        else
          candidates = [:version, :sims, :devices]
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
          _version = RunLoop::Version.new(version)
        else
          _version = version
        end
        _version >= RunLoop::Version.new('5.1')
      }.call
    end

  private

  def uikit_bundle_l10n_path
    if !xcode_developer_dir
      nil
    else
      uikit_bundle_path = "./Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/AccessibilityBundles/UIKit.axbundle/"
      File.join(xcode_developer_dir, uikit_bundle_path);
    end
  end

  @@full_name_lookup = {
    'en' => 'English',
    'nl' => 'Dutch',
    'fr' => 'French',
    'de' => 'German',
    'es' => 'Spanish',
    'it' => 'Italian',
    'jp' => 'Japanese'
  }

  def is_full_name?(two_letter_country_code)
    @@full_name_lookup.has_key?(two_letter_country_code)
  end

  def key_name_lookup_table(lang_dir_name)
    JSON.parse(`plutil -convert json #{File.join(uikit_bundle_l10n_path, lang_dir_name, 'Accessibility.strings')} -o -`)
  end


  end
end
