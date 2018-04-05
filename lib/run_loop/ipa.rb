module RunLoop
  # A model of the an .ipa - a application binary for iOS devices.
  class Ipa

    require "run_loop/shell"

    # Return true if the path_to_ipa to a zip archive
    def self.is_zip_archive?(path_to_ipa)
      hash = RunLoop::Shell.run_shell_command(["file", path_to_ipa],
                                              {log_cmd: true})
      hash[:out][/Zip archive data/]
    end

    # Return true if the path_to_ipa is probably an .ipa
    def self.is_ipa?(path_to_ipa)
      path_to_ipa.end_with?('.ipa') || RunLoop::Ipa.is_zip_archive?(path_to_ipa)
    end

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
      if !File.exist? path_to_ipa
        raise "Expected an ipa at '#{path_to_ipa}'"
      end

      if !RunLoop::Ipa.is_ipa?(path_to_ipa)
        raise "Expected '#{path_to_ipa}' have extension .ipa or be a zip archive"
      end
      @path = path_to_ipa
    end

    # @!visibility private
    def to_s
      cf_bundle_version = bundle_version
      cf_bundle_short_version = short_bundle_version

      if cf_bundle_version && cf_bundle_short_version
        version = "#{cf_bundle_version.to_s}/#{cf_bundle_short_version}"
      elsif cf_bundle_version
        version = cf_bundle_version.to_s
      elsif cf_bundle_short_version
        version = cf_bundle_short_version
      else
        version = ""
      end

      "#<IPA #{bundle_identifier} #{version} #{path}>"
    end

    # @!visibility private
    def inspect
      to_s
    end

    # The bundle identifier of this ipa.
    # @return [String] A string representation of this ipa's CFBundleIdentifier
    def bundle_identifier
      app.bundle_identifier
    end

    # Inspects the app's Info.plist for the executable name.
    # @return [String] The value of CFBundleExecutable.
    def executable_name
      app.executable_name
    end

    # Returns the arches for the binary.
    def arches
      app.arches
    end

    # Inspects the app's executables for the server version
    # @return[RunLoop::Version] a version instance
    def calabash_server_version
      app.calabash_server_version
    end

    # @!visibility private
    def codesign_info
      app.codesign_info
    end

    # @!visibility private
    def developer_signed?
      app.developer_signed?
    end

    # @!visibility private
    def distribution_signed?
      app.distribution_signed?
    end

    # @!visibility private
    def marketing_version
      app.marketing_version
    end

    # See #marketing_version
    alias_method :short_bundle_version, :marketing_version

    # @!visibility private
    def build_version
      app.build_version
    end

    # See #build_version
    alias_method :bundle_version, :build_version

    private

    # @!visibility private
    def tmpdir
      @tmpdir ||= Dir.mktmpdir
    end

    # @!visibility private
    def payload_dir
      @payload_dir ||= lambda do
        FileUtils.cp(path, tmpdir)
        zip_path = File.join(tmpdir, File.basename(path))
        Dir.chdir(tmpdir) do
          system('unzip', *['-q', zip_path])
        end
        File.join(tmpdir, 'Payload')
      end.call
    end

    # @!visibility private
    def bundle_dir
      @bundle_dir ||= lambda do
        Dir.glob(File.join(payload_dir, '*')).detect do |f|
          File.directory?(f) && f.end_with?('.app')
        end
      end.call
    end

    # @!visibility private
    def app
      @app ||= RunLoop::App.new(bundle_dir)
    end

    # @!visibility private
    def plist_buddy
      @plist_buddy ||= RunLoop::PlistBuddy.new
    end
  end
end

