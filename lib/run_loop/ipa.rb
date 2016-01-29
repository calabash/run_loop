module RunLoop
  # A model of the an .ipa - a application binary for iOS devices.
  class Ipa


    # The path to this .ipa.
    # @!attribute [r] path
    # @return [String] A path to this .ipa.
    attr_reader :path

    # Create a new ipa instance.
    # @param [String] path_to_ipa The path the .ipa file.
    # @return [Calabash::Ipa] A new ipa instance.
    # @raise [RuntimeError] If the file does not exist.
    # @raise [RuntimeError] If the file does not end in .ipa.
    def initialize(path_to_ipa)
      unless File.exist? path_to_ipa
        raise "Expected an ipa at '#{path_to_ipa}'"
      end

      unless path_to_ipa.end_with?('.ipa')
        raise "Expected '#{path_to_ipa}' to be an .ipa"
      end
      @path = path_to_ipa
    end

    # @!visibility private
    def to_s
      "#<IPA: #{bundle_identifier}: '#{path}'>"
    end

    # @!visibility private
    def inspect
      to_s
    end

    # The bundle identifier of this ipa.
    # @return [String] A string representation of this ipa's CFBundleIdentifier
    # @raise [RuntimeError] If ipa does not expand into a Payload/<app name>.app
    #  directory.
    # @raise [RuntimeError] If an Info.plist does exist in the .app.
    def bundle_identifier
      app.bundle_identifier
    end

    # Inspects the app's Info.plist for the executable name.
    # @return [String] The value of CFBundleExecutable.
    # @raise [RuntimeError] If the plist cannot be read or the
    #   CFBundleExecutable is empty or does not exist.
    def executable_name
      app.executable_name
    end

    # Inspects the app's file for the server version
    def calabash_server_version
      app.calabash_server_version
    end

    private

    def tmpdir
      @tmpdir ||= Dir.mktmpdir
    end

    def payload_dir
      @payload_dir ||= lambda {
        FileUtils.cp(path, tmpdir)
        zip_path = File.join(tmpdir, File.basename(path))
        Dir.chdir(tmpdir) do
          system('unzip', *['-q', zip_path])
        end
        File.join(tmpdir, 'Payload')
      }.call
    end

    def bundle_dir
      @bundle_dir ||= lambda {
        Dir.glob(File.join(payload_dir, '*')).detect {|f| File.directory?(f) && f.end_with?('.app')}
      }.call
    end

    def app
      @app ||= RunLoop::App.new(bundle_dir)
    end

    def plist_buddy
      @plist_buddy ||= RunLoop::PlistBuddy.new
    end
  end
end

