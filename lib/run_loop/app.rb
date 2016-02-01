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
        raise ArgumentError,
%Q{App does not exist at path or is not an app bundle.

#{app_bundle_path}

Bundle must:

1. be a directory that exists,
2. have a .app extension,
3. and contain an Info.plist.
}
      end
    end

    # @!visibility private
    def to_s
      "#<APP: #{path}>"
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

      File.exist?(app_bundle_path) &&
        File.directory?(app_bundle_path) &&
        File.extname(app_bundle_path) == '.app' &&
        File.exist?(File.join(app_bundle_path, "Info.plist"))
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
      identifier = plist_buddy.plist_read('CFBundleIdentifier', info_plist_path)
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
      identifier = plist_buddy.plist_read('CFBundleExecutable', info_plist_path)
      unless identifier
        raise "Expected key 'CFBundleExecutable' in '#{info_plist_path}'"
      end
      identifier
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
    # Collects the paths to executables in the bundle.
    def executables
      executables = []
      Dir.glob("#{path}/**/*") do |file|
        next if File.directory?(file)
        next if skip_executable_check?(file)
        if otool(file).executable?
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
    def plist_buddy
      @plist_buddy ||= RunLoop::PlistBuddy.new
    end

    # @!visibility private
    # An otool factory.
    def otool(file)
      RunLoop::Otool.new(file)
    end

    # @!visibility private
    # A strings factory
    def strings(file)
      RunLoop::Strings.new(file)
    end

    # @!visibility private
    def skip_executable_check?(file)
      image?(file) ||
        plist?(file) ||
        lproj_asset?(file) ||
        code_signing_asset?(file)
    end
    # @!visibility private
    def image?(file)
      file[/jpeg|jpg|gif|png|tiff|svg|pdf|car/, 0]
    end

    # @!visibility private
    def plist?(file)
      File.extname(file) == ".plist"
    end

    # @!visibility private
    def lproj_asset?(file)
      extension = File.extname(file)

      file[/lproj/, 0] ||
        file[/storyboard/, 0] ||
        extension == ".strings" ||
        extension == ".xib" ||
        extension == ".nib"
    end

    # @!visibility private
    def code_signing_asset?(file)
      name = File.basename(file)
      extension = File.extname(file)

      name == "PkgInfo" ||
        name == "embedded" ||
        extension == ".mobileprovision" ||
        extension == ".xcent" ||
        file[/_CodeSignature/, 0]
    end
  end
end

