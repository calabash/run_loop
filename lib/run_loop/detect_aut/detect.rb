module RunLoop

  # @!visibility private
  module DetectAUT

    # @!visibility private
    def self.detect_app_under_test(options)
      app = self.detect_app(options)
      if app.is_a?(RunLoop::App) || app.is_a?(RunLoop::Ipa)
        {
          :app => app,
          :bundle_id => app.bundle_identifier,
          :is_ipa => app.is_a?(RunLoop::Ipa)
        }
      else
        {
          :app => nil,
          :bundle_id => app,
          :is_ipa => false
        }
      end
    end

    # @!visibility private
    class Detect
      include RunLoop::DetectAUT::Errors
      include RunLoop::DetectAUT::XamarinStudio
      include RunLoop::DetectAUT::Xcode

      # @!visibility private
      DEFAULTS = {
        :search_depth => 10
      }

      # @!visibility private
      def app_for_simulator
        path = RunLoop::Environment.path_to_app_bundle
        return RunLoop::App.new(path) if path

        if xcode_project?
          apps, search_dirs = detect_xcode_apps
        elsif xamarin_project?
          search_dirs = [solution_directory]
          apps = candidate_apps(search_dirs.first)
        else
          search_dirs = [Dir.pwd]
          apps = candidate_apps(search_dirs.first)
        end

        if apps.empty?
          raise_no_simulator_app_found(search_dirs, DEFAULTS[:search_depth])
        end

        app = select_most_recent_app(apps)

        RunLoop.log_info2("Detected app at path:")
        RunLoop.log_info2("#{app.path}")
        time_str = mtime(app).strftime("%a %d %b %Y %H:%M:%S %Z")
        RunLoop.log_info2("Modification time of app: #{time_str}")
        RunLoop.log_info2("If this is incorrect, set the APP variable and/or rebuild your app")
        RunLoop.log_info2("It is your responsibility to ensure you are testing the right app.")

        app
      end

      # @!visibility private
      # @param [Array<RunLoop::Detect>] apps
      def select_most_recent_app(apps)
        apps.max do |a, b|
          mtime(a).to_i <=> mtime(b).to_i
        end
      end

      # @!visibility private
      # @param [String] bundle_path
      def app_with_bundle(bundle_path)
        RunLoop::App.new(bundle_path)
      end

      # @!visibility private
      # @param [String] base_dir where to start the recursive search
      def candidate_apps(base_dir)
        candidates = []

        globs = globs_for_app_search(base_dir)
        Dir.glob(globs).each do |bundle_path|
          # Gems, like run-loop, can contain *.app if the user is building
          # from :git =>, :github =>, or :path => sources.
          next if bundle_path[/vendor\/cache/, 0] != nil
          app = app_or_nil(bundle_path)
          candidates << app if app
        end
        candidates
      end

      # @!visibility private
      # @param [String] bundle_path path to .app
      def app_or_nil(bundle_path)
        return nil if !RunLoop::App.valid?(bundle_path)

        app = app_with_bundle(bundle_path)
        if app.simulator? && app.calabash_server_version
          app
        else
          nil
        end
      end

      # @!visibility private
      # @param [RunLoop::Detect] app
      def mtime(app)
        path = File.join(app.path, app.executable_name)
        File.mtime(path)
      end

      # @!visibility private
      def globs_for_app_search(base_dir)
        search_depth = DEFAULTS[:search_depth]
        Array.new(search_depth) do |depth|
          File.join(base_dir, *Array.new(depth) { |_| "*"}, "*.app")
        end
      end
    end

    private

    # @!visibility private
    def self.app_from_options(options)
      options[:app] || options[:bundle_id]
    end

    # @!visibility private
    def self.app_from_environment
      app_bundle_path = RunLoop::Environment.path_to_app_bundle

      candidate = app_bundle_path
      if app_bundle_path && !File.exist?(app_bundle_path)
        candidate = File.basename(app_bundle_path)
      end

      candidate || RunLoop::Environment.bundle_id
    end

    # @!visibility private
    def self.app_from_constant
      (defined?(APP_BUNDLE_PATH) && APP_BUNDLE_PATH) ||
        (defined?(APP) && APP)
    end

    # @!visibility private
    def self.app_from_opts_or_env_or_constant(options)
       self.app_from_options(options) ||
         self.app_from_environment ||
         self.app_from_constant
    end

    # @!visibility private
    def self.detector
      RunLoop::DetectAUT::Detect.new
    end

    # @!visibility private
    def self.detect_app(options)
      app = self.app_from_opts_or_env_or_constant(options)

      # Options or constant defined an instance of App or Ipa
      return app if app && (app.is_a?(RunLoop::App) || app.is_a?(RunLoop::Ipa))

      # User provided no information, so we attempt to auto detect
      if app.nil? || app == ""
        return self.detector.app_for_simulator
      end

      extension = File.extname(app)
      if extension == ".ipa" && File.exist?(app)
        RunLoop::Ipa.new(app)
      elsif extension == ".app" && File.exist?(app)
        RunLoop::App.new(app)
      else
        # Probably a bundle identifier.
        app
      end
    end
  end
end
