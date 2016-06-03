module RunLoop
  # @!visibility private
  module DetectAUT
    # @!visibility private
    module Xcode

      # @!visibility private
      def xcode_project?
        xcodeproj != nil
      end

      # @!visibility private
      def xcodeproj
        xcodeproj = RunLoop::Environment.xcodeproj

        if xcodeproj && !File.directory?(xcodeproj)
          raise_xcodeproj_missing(xcodeproj)
        end

        # XCODEPROJ defined and exists
        return xcodeproj if xcodeproj

        projects = find_xcodeproj

        return nil if projects.empty?
        return projects[0] if projects.count == 1

        raise_multiple_xcodeproj(projects)
      end

      # @!visibility private
      def find_xcodeproj
        xcode_projects = []
        Dir.glob("#{Dir.pwd}/**/*.xcodeproj").each do |path|
          next if ignore_xcodeproj?(path)
          xcode_projects << path
        end
        xcode_projects
      end

      # @!visibility private
      def ignore_xcodeproj?(path)
        path[/CordovaLib/, 0] ||
          path[/Pods/, 0] ||
          path[/Carthage/, 0] ||
          path[/Airship(Kit|Lib)/, 0] ||
          path[/google-plus-ios-sdk/, 0]
      end

      # @!visibility private
      def detect_xcode_apps
        dirs_to_search = derived_data_search_dirs

        dir_from_prefs = xcode_preferences_search_dir
        if dir_from_prefs
          dirs_to_search << dir_from_prefs
        end

        dirs_to_search << Dir.pwd
        dirs_to_search.uniq!

        apps = []
        dirs_to_search.each do |dir|
          # defined in detect_aut/apps.rb
          candidates = candidate_apps(dir)
          apps = apps.concat(candidates)
        end

        return apps, dirs_to_search
      end

      # @!visibility private
      PLIST_KEYS = {
        :workspace => "WorkspacePath",
        :shared_build => "IDESharedBuildFolderName",
        :custom_build => "IDECustomBuildProductsPath"
      }

      # @!visibility private
      # TODO Needs unit tests
      def derived_data_search_dirs
        project = xcodeproj
        project_name = File.basename(project)
        matches = []

        # WorkspacePath could be a .xcodeproj or .xcworkspace
        #
        # # Exact match.
        #     xcodeproj = path/to/MyApp/MyApp.xcodeproj
        # WorkspacePath = path/to/MyApp/MyApp.xcodeproj
        #
        # # CocoaPods projects are often configured like this.  As are legacy
        # # projects that have been added to a new workspace.
        #     xcodeproj = path/to/MyApp/MyApp.xcodeproj
        # WorkspacePath = path/to/MyApp/MyApp.xcworkspace
        #
        # # This is the Xcode default when creating new iOS project
        #     xcodeproj = path/to/MyApp/MyApp/MyApp.xcodeproj
        # WorkspacePath = path/to/MyApp/MyApp.xcworkspace
        key = PLIST_KEYS[:workspace]
        Dir.glob("#{derived_data}/*/info.plist") do |plist|
          workspace = pbuddy.plist_read(key, plist)
          if workspace == project
            matches << File.dirname(plist)
          else
            base_dir = File.dirname(workspace)
            if File.exist?(File.join(base_dir, project_name))
              matches << File.dirname(plist)
            elsif !Dir.glob("#{File.dirname(workspace)}/*/#{project_name}").empty?
              matches << File.dirname(plist)
            elsif !Dir.glob("#{File.dirname(workspace)}/**/#{project_name}").empty?
              matches << File.dirname(plist)
            end
          end
        end
        matches
      end

      # @!visibility private
      def xcode_preferences_search_dir
        plist = xcode_preferences_plist

        shared_build_folder = pbuddy.plist_read(PLIST_KEYS[:shared_build], plist)
        custom_build_folder = pbuddy.plist_read(PLIST_KEYS[:custom_build], plist)

        if shared_build_folder
          File.join(derived_data, shared_build_folder, "Products")
        elsif custom_build_folder
          File.join(File.dirname(xcodeproj), custom_build_folder)
        else
          nil
        end
      end

      # @!visibility private
      def derived_data
        RunLoop::Environment.derived_data ||
          File.join(RunLoop::Environment.user_home_directory,
                    "Library", "Developer", "Xcode", "DerivedData")
      end

      # @!visibility private
      def xcode_preferences_plist
        File.join(RunLoop::Environment.user_home_directory,
                  "Library",
                  "Preferences",
                  "com.apple.dt.Xcode.plist")
      end

      # @!visibility private
      def pbuddy
        @pbuddy ||= RunLoop::PlistBuddy.new
      end
    end
  end
end

