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
    end

    # Is this a valid app?
    def valid?
      [File.exist?(path),
       File.directory?(path),
       File.extname(path) == '.app'].all?
    end

    # Returns the Info.plist path.
    # @raise [RuntimeError] If there is no Info.plist.
    def info_plist_path
      info_plist = File.join(path, 'Info.plist')
      unless File.exist?(info_plist)
        raise "Expected an Info.plist at '#{path}'"
      end
      info_plist
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
    # @return [String] The value of CFBundleIdentifier.
    # @raise [RuntimeError] If the plist cannot be read or the
    #   CFBundleExecutable is empty or does not exist.
    def executable_name
      identifier = plist_buddy.plist_read('CFBundleExecutable', info_plist_path)
      unless identifier
        raise "Expected key 'CFBundleExecutable' in '#{info_plist_path}'"
      end
      identifier
    end

    private

    def plist_buddy
      @plist_buddy ||= RunLoop::PlistBuddy.new
    end

  end
end
