module RunLoop
  module LifeCycle

    class CoreSimulator

      # @!visibility private
      METADATA_PLIST = '.com.apple.mobile_container_manager.metadata.plist'

      # @!visibility private
      CORE_SIMULATOR_DEVICE_DIR = File.expand_path('~/Library/Developer/CoreSimulator/Devices')

      # @!visibility private
      # Pattern.
      # [ '< process name >', < send term first > ]
      MANAGED_PROCESSES =
            [
                  # This process is a daemon, and requires 'KILL' to terminate.
                  # Killing the process is fast, but it takes a long time to
                  # restart.
                  # ['com.apple.CoreSimulator.CoreSimulatorService', false],

                  # Probably do not need to quit this, but it is tempting to do so.
                  #['com.apple.CoreSimulator.SimVerificationService', false],

                  # Started by Xamarin Studio, this is the parent process of the
                  # processes launched by Xamarin's interaction with
                  # CoreSimulatorBridge.
                  ['csproxy', true],

                  # Yes.
                  ['SimulatorBridge', true],
                  ['configd_sim', true],
                  ['launchd_sim', true],

                  # Does not always appear.
                  ['CoreSimulatorBridge', true],

                  # Xcode 7
                  ['ids_simd', true]
            ]

      attr_reader :app
      attr_reader :device
      attr_reader :pbuddy

      # @param [RunLoop::App] app The application.
      # @param [RunLoop::Device] device The device.
      def initialize(app, device)
        @app = app
        @device = device

        # In order to manage the app on the device, we need to manage the
        # CoreSimulator processes.
        terminate_core_simulator_processes
      end

      # @!visibility private
      def pbuddy
        @pbuddy ||= RunLoop::PlistBuddy.new
      end

      # @!visibility private
      def sdk_gte_8?
        device.version >= RunLoop::Version.new('8.0')
      end

      # The data directory for the the device.
      #
      # ~/Library/Developer/CoreSimulator/Devices/<UDID>/data
      def device_data_dir
        @device_data_dir ||= File.join(CORE_SIMULATOR_DEVICE_DIR, device.udid, 'data')
      end

      # The applications directory for the device.
      #
      # ~/Library/Developer/CoreSimulator/Devices/<UDID>/Containers/Bundle/Application
      def device_applications_dir
        @device_app_dir ||= lambda do
          if sdk_gte_8?
            File.join(device_data_dir, 'Containers', 'Bundle', 'Application')
          else
            File.join(device_data_dir, 'Applications')
          end
        end.call
      end

      # The sandbox directory for the app.
      #
      # ~/Library/Developer/CoreSimulator/Devices/<UDID>/Containers/Data/Application
      #
      # Contains Library, Documents, and tmp directories.
      def app_sandbox_dir
        app_install_dir = installed_app_bundle_dir
        return nil if app_install_dir.nil?
        if sdk_gte_8?
          app_sandbox_dir_sdk_gte_8
        else
          app_install_dir
        end
      end

      # The Library directory in the sandbox.
      def app_library_dir
        base_dir = app_sandbox_dir
        if base_dir.nil?
          nil
        else
          File.join(base_dir, 'Library')
        end
      end

      # The Library/Preferences directory in the sandbox.
      def app_library_preferences_dir
        base_dir = app_library_dir
        if base_dir.nil?
          nil
        else
          File.join(base_dir, 'Preferences')
        end
      end

      # The Documents directory in the sandbox.
      def app_documents_dir
        base_dir = app_sandbox_dir
        if base_dir.nil?
          nil
        else
          File.join(base_dir, 'Documents')
        end
      end

      # The tmp directory in the sandbox.
      def app_tmp_dir
        base_dir = app_sandbox_dir
        if base_dir.nil?
          nil
        else
          File.join(base_dir, 'tmp')
        end
      end

      # Is this app installed?
      def app_is_installed?
        !installed_app_bundle_dir.nil?
      end

      # The sha1 of the installed app.
      def installed_app_sha1
        installed_bundle = installed_app_bundle_dir
        if installed_bundle
          RunLoop::Directory.directory_digest(installed_bundle)
        else
          nil
        end
      end

      # Is the app that is install the same as the one we have in hand?
      def same_sha1_as_installed?
        app.sha1 == installed_app_sha1
      end

      # @!visibility private
      #
      # Returns the path to the installed app bundle directory (.app).
      #
      # If this method returns nil, the app is not installed.
      def installed_app_bundle_dir
        sim_app_dir = device_applications_dir
        return nil if !File.exist?(sim_app_dir)
        Dir.glob("#{sim_app_dir}/**/*.app").find do |path|
          RunLoop::App.new(path).bundle_identifier == app.bundle_identifier
        end
      end

      private

      # @!visibility private
      def app_sandbox_dir_sdk_gte_8
        containers_data_dir = File.join(device_data_dir, 'Containers', 'Data', 'Application')
        apps = Dir.glob("#{containers_data_dir}/**/#{METADATA_PLIST}")
        match = apps.find do |metadata_plist|
          pbuddy.plist_read('MCMMetadataIdentifier', metadata_plist) == app.bundle_identifier
        end
        if match
          File.dirname(match)
        else
          nil
        end
      end

      # @!visibility private
      def terminate_core_simulator_processes
        MANAGED_PROCESSES.each do |pair|
          name = pair[0]
          send_term = pair[1]
          pids = RunLoop::ProcessWaiter.new(name).pids
          pids.each do |pid|

            if send_term
              term = RunLoop::ProcessTerminator.new(pid, 'TERM', name)
              killed = term.kill_process
            else
              killed = false
            end

            unless killed
              term = RunLoop::ProcessTerminator.new(pid, 'KILL', name)
              term.kill_process
            end
          end
        end
      end
    end
  end
end
