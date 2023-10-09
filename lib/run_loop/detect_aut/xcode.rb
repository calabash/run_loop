
module RunLoop
  # @!visibility private
  module DetectAUT
    # @!visibility private
    module Xcode
      require "etc"

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
      def self.find_user_state_file
        username = RunLoop::Environment.username
        xcworkspace = RunLoop::Environment.xcodeproj
        unless xcworkspace.nil?
          xcworkspace = xcworkspace.gsub("xcodeproj", "xcworkspace")
          file = Dir.glob("#{xcworkspace}/xcuserdata/#{username}.xcuserdatad/UserInterfaceState.xcuserstate")
          if !file.nil? && file.is_a?(Array)
            return file[0]
          end
        end
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

      # @!visibility private
      # @param [String] file the plist to read
      # @return [String] the UDID of device
      def self.plist_find_device(file)
        #TODO unfortunately i can use ony this solution
        file_content = `/usr/libexec/PlistBuddy -c Print "#{file}"`
            .encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
        if !file_content.nil? && !file_content.empty?
          lines = file_content.split("\n")
          lines.detect do |line|
            line[/dvtdevice.*:/, 0]
          end
        end
      end

      # @!visibility private
      def self.detect_selected_device
        file_name = find_user_state_file
        selected_device = plist_find_device(file_name)
        if selected_device != '' && !selected_device.nil?
          udid = selected_device.split(':')[1]
          selected_device = RunLoop::Device.device_with_identifier(udid)
          #TODO now only returning detected device if simulator detected
          if selected_device.simulator?
            RunLoop.log_info2("Detected simulator selected in Xcode is: #{selected_device}")
            RunLoop.log_info2("If this is not desired simulator, set the DEVICE_TARGET variable")
            selected_device

          else
            nil
          end
        end
      end
    end
  end
end

