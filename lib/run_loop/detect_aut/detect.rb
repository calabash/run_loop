module RunLoop

  # @!visibility private
  module DetectAUT

    # @!visibility private
    class Detect
      include RunLoop::DetectAUT::Errors
      include RunLoop::DetectAUT::XamarinStudio
      include RunLoop::DetectAUT::Xcode

      # @!visibility private
      DEFAULTS = {
        :search_depth => 5
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
          apps = []
          search_dirs = []
        end

        # If this is a Xamarin project, we've already searched the local
        # directory tree for .app.
        if apps.empty? && !xamarin_project?
          search_dirs << File.expand_path("./")
          apps = candidate_apps(File.expand_path("./"))
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
        Dir.glob("#{base_dir}/**/*.app").each do |bundle_path|
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
  end
end
