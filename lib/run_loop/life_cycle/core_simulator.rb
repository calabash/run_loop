module RunLoop
  module LifeCycle

    class CoreSimulator < Simulator

      require 'securerandom'

      # @!visibility private
      METADATA_PLIST = '.com.apple.mobile_container_manager.metadata.plist'

      # @!visibility private
      CORE_SIMULATOR_DEVICE_DIR = File.expand_path('~/Library/Developer/CoreSimulator/Devices')

      # @!visibility private
      # How long to wait after the simulator has launched.
      SIM_POST_LAUNCH_WAIT = RunLoop::Environment.sim_post_launch_wait || 1.0

      # @!visibility private
      # How long to wait for for a device to reach a state.
      WAIT_FOR_DEVICE_STATE_OPTS =
            {
                  interval: 0.1,
                  timeout: 5
            }

      # @!visibility private
      # How long to wait for the CoreSimulator processes to start.
      WAIT_FOR_SIMULATOR_PROCESSES_OPTS =
            {
                  timeout: 5,
                  raise_on_timeout: true
            }

      attr_reader :app
      attr_reader :device
      attr_reader :sim_control
      attr_reader :pbuddy

      # @param [RunLoop::App] app The application.
      # @param [RunLoop::Device] device The device.
      def initialize(app, device, sim_control=RunLoop::SimControl.new)
        @app = app
        @device = device
        @sim_control = sim_control

        # In order to manage the app on the device, we need to manage the
        # CoreSimulator processes.
        RunLoop::SimControl.terminate_all_sims
        terminate_core_simulator_processes
      end

      # Launch simulator without specifying an app.
      def launch_simulator
        sim_path = sim_control.send(:sim_app_path)
        args = ['open', '-g', '-a', sim_path, '--args', '-CurrentDeviceUDID', device.udid]

        RunLoop.log_debug("Launching #{device} with:")
        RunLoop.log_unix_cmd("xcrun #{args.join(' ')}")

        start_time = Time.now

        pid = spawn('xcrun', *args)
        Process.detach(pid)

        sim_name = sim_control.send(:sim_name)

        RunLoop::ProcessWaiter.new(sim_name, WAIT_FOR_SIMULATOR_PROCESSES_OPTS).wait_for_any

        device.simulator_wait_for_stable_state

        elapsed = Time.now - start_time
        RunLoop.log_debug("Took #{elapsed} seconds to launch the simulator")

        true
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

      # Uninstall the app on the device.
      def uninstall
        installed_app_bundle = installed_app_bundle_dir
        if installed_app_bundle
          uninstall_app_and_sandbox(installed_app_bundle)
          :uninstalled
        else
          RunLoop.log_debug('App was not installed.  Nothing to do')
          :not_installed
        end
      end

      # Install the app on the device.
      def install
        installed_app_bundle = installed_app_bundle_dir

        # App is not installed.
        return install_new_app if installed_app_bundle.nil?

        # App is installed but sha1 is different.
        if !same_sha1_as_installed?
          return reinstall_existing_app_and_clear_sandbox(installed_app_bundle)
        end

        RunLoop.log_debug('The installed app is the same as the app we are trying to install; skipping installation')
        installed_app_bundle
      end

      # @!visibility private
      #
      # 1. Does nothing if the app is not installed.
      # 2. Does nothing if the app the same as the app that is installed
      # 3. Installs app if it is different from the installed app
      #
      # TODO needs unit tests and a better name?
      def ensure_app_same
        installed_app_bundle = installed_app_bundle_dir

        if !installed_app_bundle
          RunLoop.log_debug("App: #{app} is not installed")
          return true
        end

        installed_sha = installed_app_sha1
        app_sha = app.sha1

        if installed_sha == app_sha
          RunLoop.log_debug("Installed app is the same as #{app}")
          return true
        end

        RunLoop.log_debug("The app you are trying to launch is not the same as the app that is installed.")
        RunLoop.log_debug("  Installed app SHA: #{installed_sha}")
        RunLoop.log_debug("  App to launch SHA: #{app_sha}")
        RunLoop.log_debug("Will install #{app}")


        FileUtils.rm_rf installed_app_bundle
        RunLoop.log_debug('Deleted the existing app')

        directory = File.expand_path(File.join(installed_app_bundle, '..'))
        bundle_name = File.basename(app.path)
        target = File.join(directory, bundle_name)

        args = ['ditto', app.path, target]
        RunLoop::Xcrun.new.exec(args, log_cmd: true)

        RunLoop.log_debug("Installed #{app} on CoreSimulator #{device.udid}")

        clear_device_launch_csstore

        true
      end

      # Reset app sandbox.
      def reset_app_sandbox
        return true if !app_is_installed?

        wait_for_device_state('Shutdown')

        reset_app_sandbox_internal
      end

      private

      def generate_uuid
        SecureRandom.uuid.upcase!
      end

      def existing_app_container_uuids
        if File.exist?(device_applications_dir)
          Dir.entries(device_applications_dir)
        else
          []
        end
      end

      def generate_unique_uuid(existing, timeout=1.0)
        begin
          Timeout::timeout(timeout, Timeout::Error) do
          uuid = generate_uuid
          loop do
            break if !existing.include?(uuid)
            uuid = generate_uuid
          end
          uuid
          end
        rescue Timeout::Error => _
          raise RuntimeError,
                "Expected to be able to generate a unique uuid in #{timeout} seconds"
        end
      end

      def install_new_app
        wait_for_device_state('Shutdown')

        existing = existing_app_container_uuids
        udid = generate_unique_uuid(existing)
        directory = File.join(device_applications_dir, udid)

        bundle_name = File.basename(app.path)
        target = File.join(directory, bundle_name)

        args = ['ditto', app.path, target]
        RunLoop::Xcrun.new.exec(args, log_cmd: true)
        target
      end

      def reinstall_existing_app_and_clear_sandbox(installed_app_bundle)
        wait_for_device_state('Shutdown')

        reset_app_sandbox_internal

        if File.exist?(installed_app_bundle)
          FileUtils.rm_rf(installed_app_bundle)
          RunLoop.log_debug("Deleted app bundle: #{installed_app_bundle}")
        end

        directory = File.dirname(installed_app_bundle)
        bundle_name = File.basename(app.path)
        target = File.join(directory, bundle_name)

        args = ['ditto', app.path, target]
        RunLoop::Xcrun.new.exec(args, log_cmd: true)
        installed_app_bundle
      end

      def uninstall_app_and_sandbox(installed_app_bundle)
        wait_for_device_state('Shutdown')

        if sdk_gte_8?
          # Must delete the sandbox first.
          directory = app_sandbox_dir
          if File.exist?(directory)
            FileUtils.rm_rf(directory)
            RunLoop.log_debug("Deleted app sandbox: #{directory}")
          end

          directory = File.dirname(installed_app_bundle)
          if File.exist?(directory)
            FileUtils.rm_rf(directory)
            RunLoop.log_debug("Deleted app container: #{directory}")
          end
        else
          # Sandbox _is_ in the container.
          directory = File.dirname(installed_app_bundle)
          if File.exist?(directory)
            FileUtils.rm_rf(directory)
            RunLoop.log_debug("Deleted app container: #{directory}")
          end
        end
      end

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
      def wait_for_device_state(target_state)
        now = Time.now
        timeout = WAIT_FOR_DEVICE_STATE_OPTS[:timeout]
        poll_until = now + timeout
        delay = WAIT_FOR_DEVICE_STATE_OPTS[:interval]
        in_state = false
        while Time.now < poll_until
          in_state = device.update_simulator_state == target_state
          break if in_state
          sleep delay
        end

        elapsed = Time.now - now
        RunLoop.log_debug("Waited for #{elapsed} seconds for device to have state: '#{target_state}'.")

        unless in_state
          raise "Expected '#{target_state} but found '#{device.state}' after waiting."
        end
        in_state
      end

      # @!visibility private
      def device_caches_dir
        @device_caches_dir ||= File.join(device_data_dir, 'Library', 'Caches')
      end

      # @!visibility private
      def clear_device_launch_csstore
        glob = File.join(device_caches_dir, "com.apple.LaunchServices-*.csstore")
        Dir.glob(glob) do | ccstore |
          FileUtils.rm_f ccstore
        end
      end

      # @!visibility private
      def reset_app_sandbox_internal_shared
        [app_documents_dir, app_tmp_dir].each do |dir|
          FileUtils.rm_rf dir
          FileUtils.mkdir dir
        end
      end

      # @!visibility private
      def reset_app_sandbox_internal_sdk_gte_8
        lib_dir = app_library_dir
        RunLoop::Directory.recursive_glob_for_entries(lib_dir).each do |entry|
          if entry.include?('Preferences')
            # nop
          else
            if File.exist?(entry)
              FileUtils.rm_rf(entry)
            end
          end
        end

        prefs_dir = app_library_preferences_dir
        protected = ['com.apple.UIAutomation.plist',
                     'com.apple.UIAutomationPlugIn.plist']
        RunLoop::Directory.recursive_glob_for_entries(prefs_dir).each do |entry|
          unless protected.include?(File.basename(entry))
            if File.exist?(entry)
              FileUtils.rm_rf entry
            end
          end
        end
      end

      # @!visibility private
      def reset_app_sandbox_internal_sdk_lt_8
        prefs_dir = app_library_preferences_dir
        RunLoop::Directory.recursive_glob_for_entries(prefs_dir).each do |entry|
          if entry.end_with?('.GlobalPreferences.plist') ||
                entry.end_with?('com.apple.PeoplePicker.plist')
            # nop
          else
            if File.exist?(entry)
              FileUtils.rm_rf entry
            end
          end
        end

        # app preferences lives in device Library/Preferences
        device_prefs_dir = File.join(app_sandbox_dir, 'Library', 'Preferences')
        app_prefs_plist = File.join(device_prefs_dir, "#{app.bundle_identifier}.plist")
        if File.exist?(app_prefs_plist)
          FileUtils.rm_rf(app_prefs_plist)
        end
      end

      # @!visibility private
      def reset_app_sandbox_internal
        reset_app_sandbox_internal_shared

        if sdk_gte_8?
          reset_app_sandbox_internal_sdk_gte_8
        else
          reset_app_sandbox_internal_sdk_lt_8
        end
      end

      # @!visibility private
      # For testing.
      def launch

        launch_simulator

        args = ['simctl', 'install', device.udid, app.path]
        RunLoop::Xcrun.new.exec(args, log_cmd: true, timeout: 10)

        device.simulator_wait_for_stable_state

        args = ['simctl', 'launch', device.udid, app.bundle_identifier]
        hash = RunLoop::Xcrun.new.exec(args, log_cmd: true, timeout: 20)

        exit_status = hash[:exit_status]

        if exit_status != 0
          err = hash[:err]
          RunLoop.log_error(err)
          raise RuntimeError, "Could not launch #{app.bundle_identifier} on #{device}"
        end

        RunLoop::ProcessWaiter.new(app.executable_name, {:timeout => 10,
                                                         :raise_on_timeout => true}).wait_for_any


        device.simulator_wait_for_stable_state

        true
      end
    end
  end
end
