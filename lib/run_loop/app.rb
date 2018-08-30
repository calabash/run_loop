module RunLoop
  # A class for interacting with .app bundles.
  class App

    # @!attribute [r] path
    # @return [String] The path to the app bundle .app
    attr_reader :path

    # Creates a new App instance.
    #
    # @note The `app_bundle_path` is expanded during initialization.
    #
    # @param [String] app_bundle_path A path to a .app
    # @return [RunLoop::App] A instance of App with a path.
    def initialize(app_bundle_path)
      @path = File.expand_path(app_bundle_path)

      if !App.valid?(app_bundle_path)
        if App.cached_app_on_simulator?(app_bundle_path)
          raise RuntimeError, %Q{
App is "cached" on the simulator.

#{app_bundle_path}

This can happen if there was an incomplete install or uninstall.

Try manually deleting the application data container and relaunching the simulator.

$ rm -r #{File.dirname(app_bundle_path)}
$ run-loop simctl manage-processes
}
        else
          raise ArgumentError,
%Q{App does not exist at path or is not an app bundle.

#{app_bundle_path}

Bundle must:

1. be a directory that exists,
2. have a .app extension,
3. contain an Info.plist,
4. and the app binary (CFBundleExecutable) must exist
}
        end
      end
    end

    # @!visibility private
    def to_s
      cf_bundle_version = bundle_version
      cf_bundle_short_version = short_bundle_version

      if cf_bundle_version && cf_bundle_short_version
        version = "#{cf_bundle_version.to_s} / #{cf_bundle_short_version}"
      elsif cf_bundle_version
        version = cf_bundle_version.to_s
      elsif cf_bundle_short_version
        version = cf_bundle_short_version
      else
        version = ""
      end

      "#<APP #{bundle_identifier} #{version} #{path}>"
    end

    # @!visibility private
    def inspect
      to_s
    end

    # Is this a valid app?
    def valid?
      App.valid?(path)
    end

    # @!visibility private
    def self.valid?(app_bundle_path)
      return false if app_bundle_path.nil?

      return false if !File.directory?(app_bundle_path)
      return false if !File.extname(app_bundle_path) == ".app"

      return false if !self.info_plist_exist?(app_bundle_path)
      return false if !self.executable_file_exist?(app_bundle_path)
      true
    end

    # @!visibility private
    #
    # Starting in Xcode 10 betas, this can happen if there was an incomplete
    # install or uninstall.
    def self.cached_app_on_simulator?(app_bundle_path)
      return false if Dir[File.join(app_bundle_path, "**/*")].length != 2
      return false if !app_bundle_path[RunLoop::Regex::CORE_SIMULATOR_UDID_REGEX]
      [File.join(app_bundle_path, "Info.plist"),
       File.join(app_bundle_path, "Icon.png")].all? do |file|
        File.exist?(file)
      end
    end

    # Returns the Info.plist path.
    # @raise [RuntimeError] If there is no Info.plist.
    def info_plist_path
      @info_plist_path ||= File.join(path, 'Info.plist')
    end

    # Inspects the app's Info.plist for the bundle identifier.
    # @return [String] The value of CFBundleIdentifier.
    # @raise [RuntimeError] If the plist cannot be read or the
    #   CFBundleIdentifier is empty or does not exist.
    def bundle_identifier
      identifier = plist_buddy.plist_read("CFBundleIdentifier", info_plist_path)
      unless identifier
        raise "Expected key 'CFBundleIdentifier' in '#{info_plist_path}'"
      end
      identifier
    end

    # Inspects the app's Info.plist for the executable name.
    # @return [String] The value of CFBundleExecutable.
    # @raise [RuntimeError] If the plist cannot be read or the
    #   CFBundleExecutable is empty or does not exist.
    def executable_name
      name = plist_buddy.plist_read("CFBundleExecutable", info_plist_path)
      unless name
        raise "Expected key 'CFBundleExecutable' in '#{info_plist_path}'"
      end
      name
    end

    # Returns the arches for the binary.
    def arches
      @arches ||= lipo.info
    end

    # True if the app has been built for the simulator
    def simulator?
      arches.include?("i386") || arches.include?("x86_64")
    end

    # True if the app has been built for physical devices
    def physical_device?
      arches.any? do |arch|
        arch[/arm/, 0]
      end
    end

    # Inspects the app's file for the server version
    def calabash_server_version
      version = nil
      executables.each do |executable|
        version = strings(executable).server_version
        break if version
      end
      version
    end

    # @!visibility private
    # Return the fingerprint of the linked server
    def calabash_server_id
      name = plist_buddy.plist_read("CFBundleExecutable", info_plist_path)
      app_executable = File.join(self.path, name)
      strings(app_executable).server_id
    end

    # @!visibility private
    def codesign_info
      RunLoop::Codesign.info(path)
    end

    # @!visibility private
    def developer_signed?
      RunLoop::Codesign.developer?(path)
    end

    # @!visibility private
    def distribution_signed?
      RunLoop::Codesign.distribution?(path)
    end

    # Returns the CFBundleShortVersionString of the app as Version instance.
    #
    # Apple docs:
    #
    # CFBundleShortVersionString specifies the release version number of the
    # bundle, which identifies a released iteration of the app. The release
    # version number is a string comprised of three period-separated integers.
    #
    # The first integer represents major revisions to the app, such as revisions
    # that implement new features or major changes. The second integer denotes
    # revisions that implement less prominent features. The third integer
    # represents maintenance releases.
    #
    # The value for this key differs from the value for CFBundleVersion, which
    # identifies an iteration (released or unreleased) of the app. This key can
    # be localized by including it in your InfoPlist.strings files.
    #
    # @return [RunLoop::Version, nil] Returns a Version instance if the
    #  CFBundleShortVersion string is well formed and nil if not.
    def marketing_version
      string = plist_buddy.plist_read("CFBundleShortVersionString", info_plist_path)
      begin
        version = RunLoop::Version.new(string)
      rescue
        if string && string != ""
          RunLoop.log_debug("CFBundleShortVersionString: '#{string}' is not a well formed version string")
        else
          RunLoop.log_debug("CFBundleShortVersionString is not defined in Info.plist")
        end
        version = nil
      end
      version
    end

    # See #marketing_version
    alias_method :short_bundle_version, :marketing_version

    # Returns the CFBundleVersion of the app as Version instance.
    #
    # Apple docs:
    #
    # CFBundleVersion specifies the build version number of the bundle, which
    # identifies an iteration (released or unreleased) of the bundle. The build
    # version number should be a string comprised of three non-negative,
    # period-separated integers with the first integer being greater than zero.
    # The string should only contain numeric (0-9) and period (.) characters.
    # Leading zeros are truncated from each integer and will be ignored (that
    # is, 1.02.3 is equivalent to 1.2.3).
    #
    # @return [RunLoop::Version, nil] Returns a Version instance if the
    #  CFBundleVersion string is well formed and nil if not.
    def build_version
      string = plist_buddy.plist_read("CFBundleVersion", info_plist_path)
      begin
        version = RunLoop::Version.new(string)
      rescue
        if string && string != ""
          RunLoop.log_debug("CFBundleVersion: '#{string}' is not a well formed version string")
        else
          RunLoop.log_debug("CFBundleVersion is not defined in Info.plist")
        end
        version = nil
      end
      version
    end

    # See #build_version
    alias_method :bundle_version, :build_version

    # @!visibility private
    # Collects the paths to executables in the bundle.
    def executables
      executables = []
      Dir.glob("#{path}/**/*") do |file|
        next if skip_executable_check?(file)
        if otool.executable?(file)
          executables << file
        end
      end
      executables
    end

    # Returns the sha1 of the application.
    def sha1
      RunLoop::Directory.directory_digest(path)
    end

    private

    # @!visibility private
    def self.info_plist_exist?(app_bundle_path)
      info_plist = File.join(app_bundle_path, "Info.plist")
      File.exist?(info_plist)
    end

    # @!visibility private
    def self.executable_file_exist?(app_bundle_path)
      return false if !self.info_plist_exist?(app_bundle_path)
      info_plist = File.join(app_bundle_path, "Info.plist")
      pbuddy = RunLoop::PlistBuddy.new
      name = pbuddy.plist_read("CFBundleExecutable", info_plist)
      if name
        File.exist?(File.join(app_bundle_path, name))
      else
        false
      end
    end

    # @!visibility private
    def lipo
      @lipo ||= RunLoop::Lipo.new(path)
    end

    # @!visibility private
    def plist_buddy
      @plist_buddy ||= RunLoop::PlistBuddy.new
    end

    # @!visibility private
    def otool
      @otool ||= RunLoop::Otool.new(xcode)
    end

    # @!visibility private
    def xcode
      @xcode ||= RunLoop::Xcode.new
    end

    # @!visibility private
    # A strings factory
    def strings(file)
      RunLoop::Strings.new(file)
    end

    # @!visibility private
    def skip_executable_check?(file)
      File.directory?(file) ||
        image?(file) ||
        text?(file) ||
        plist?(file) ||
        lproj_asset?(file) ||
        code_signing_asset?(file) ||
        core_data_asset?(file) ||
        font?(file) ||
        build_artifact?(file)
    end

    # @!visibility private
    def text?(file)
       extension = File.extname(file)
       filename = File.basename(file)

       extension == ".txt" ||
         extension == ".md" ||
         extension == ".html" ||
         extension == ".xml" ||
         extension == ".json" ||
         extension == ".yaml" ||
         extension == ".yml" ||
         extension == ".rtf" ||

         ["NOTICE", "LICENSE", "README", "ABOUT"].any? do |elm|
           filename[/#{elm}/]
         end
    end

    # @!visibility private
    def image?(file)
      extension = File.extname(file)

      extension == ".jpeg" ||
      extension == ".jpg" ||
      extension == ".gif" ||
      extension == ".png" ||
      extension == ".tiff" ||
      extension == ".svg" ||
      extension == ".pdf" ||
      extension == ".car" ||
      file[/iTunesArtwork/, 0]
    end

    # @!visibility private
    def plist?(file)
      File.extname(file) == ".plist"
    end

    # @!visibility private
    def lproj_asset?(file)
      extension = File.extname(file)
      dir_extension = File.extname(File.dirname(file))

      dir_extension == ".lproj" ||
        dir_extension == ".storyboard" ||
        dir_extension == ".storyboardc" ||
        extension == ".strings" ||
        extension == ".xib" ||
        extension == ".nib"
    end

    # @!visibility private
    def code_signing_asset?(file)
      name = File.basename(file)
      extension = File.extname(file)
      dirname = File.basename(File.dirname(file))

      name == "PkgInfo" ||
        name == "embedded" ||
        extension == ".mobileprovision" ||
        extension == ".xcent" ||
        dirname == "_CodeSignature"
    end

    # @!visibility private
    def core_data_asset?(file)
      extension = File.extname(file)
      dir_extension = File.extname(File.dirname(file))

      dir_extension == ".momd" ||
        extension == ".mom" ||
        extension == ".db" ||
        extension == ".omo"
    end

    # @!visibility private
    def font?(file)
      extension = File.extname(file)

      extension == ".ttf" || extension == ".otf"
    end

    # @!visibility private
    def build_artifact?(file)
      File.extname(file) == ".xcconfig"
    end
  end
end

