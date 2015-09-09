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

        RunLoop.log_unix_cmd("xcrun #{args.join(' ')}")

        pid = spawn('xcrun', *args)
        Process.detach(pid)

        sim_name = sim_control.send(:sim_name)
        RunLoop::ProcessWaiter.new(sim_name, WAIT_FOR_SIMULATOR_PROCESSES_OPTS).wait_for_any
        RunLoop::ProcessWaiter.new('SimulatorBridge', WAIT_FOR_SIMULATOR_PROCESSES_OPTS).wait_for_any
        wait_for_device_state 'Booted'
        device.wait_for_simulator_log_to_stop_updating(5, 1)
        sleep(SIM_POST_LAUNCH_WAIT)
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

      # Reset app sandbox.
      def reset_app_sandbox
        return true if !app_is_installed?

        wait_for_device_state('Shutdown')

        reset_app_sandbox_internal
      end

      private

      def install_new_app

      end

      def reinstall_existing_app_and_clear_sandbox(installed_app_bundle)

      end

      def uninstall_app_and_sandbox(installed_app_bundle)

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

      # @!visibility private
      def wait_for_device_state(target_state)
        return true if device.state == target_state

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
    end
  end
end
