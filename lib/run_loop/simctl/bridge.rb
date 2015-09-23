require 'fileutils'
require 'open3'
#require 'retriable'

module RunLoop::Simctl

  class SimctlError < StandardError

  end

  # @!visibility private
  # This is not a public API.  You have been warned.
  #
  # TODO Some code is duplicated from sim_control.rb
  # TODO Reinstall if checksum does not match.
  # TODO Analyze terminate_core_simulator_processes.
  # TODO Figure out when CoreSimulator appears and does not appear.
  class Bridge < RunLoop::LifeCycle::CoreSimulator

    attr_reader :device
    attr_reader :app
    attr_reader :sim_control
    attr_reader :pbuddy

    def initialize(device, app_bundle_path)

      @pbuddy = RunLoop::PlistBuddy.new

      @sim_control = RunLoop::SimControl.new
      @path_to_ios_sim_app_bundle = @sim_control.send(:sim_app_path)

      @app = RunLoop::App.new(app_bundle_path)

      unless @app.valid?
        raise "Could not recreate a valid app from '#{app_bundle_path}'"
      end

      @device = device

      # It may seem weird to do this in the initialize, but you cannot make
      # simctl calls successfully unless the simulator is:
      # 1. closed
      # 2. the device you are trying to operate on is Shutdown
      # 3. the CoreSimulator processes are terminated
      RunLoop::SimControl.terminate_all_sims
      shutdown
      terminate_core_simulator_processes
    end

    # The sha1 of the installed app.
    def installed_app_sha1
      installed_bundle = fetch_app_dir
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
    def is_sdk_8?
      @is_sdk_8 ||= device.version >= RunLoop::Version.new('8.0')
    end

    def device_data_dir
      @device_data_dir ||= File.join(CORE_SIMULATOR_DEVICE_DIR, device.udid, 'data')
    end

    def device_applications_dir
      @simulator_app_dir ||= lambda {
        if is_sdk_8?
          File.join(device_data_dir, 'Containers', 'Bundle', 'Application')
        else
          File.join(device_data_dir, 'Applications')
        end
      }.call
    end

    def app_data_dir
      app_install_dir = fetch_app_dir
      return nil if app_install_dir.nil?
      if is_sdk_8?
        containers_data_dir = File.join(device_data_dir, 'Containers', 'Data', 'Application')
        apps = Dir.glob("#{containers_data_dir}/**/#{METADATA_PLIST}")
        match = apps.detect do |metadata_plist|
          pbuddy.plist_read('MCMMetadataIdentifier', metadata_plist) == app.bundle_identifier
        end
        if match
          File.dirname(match)
        else
          nil
        end
      else
        app_install_dir
      end
    end

    def app_library_dir
      base_dir = app_data_dir
      if base_dir.nil?
        nil
      else
        File.join(base_dir, 'Library')
      end
    end

    def app_library_preferences_dir
      base_dir = app_library_dir
      if base_dir.nil?
        nil
      else
        File.join(base_dir, 'Preferences')
      end
    end

    def app_documents_dir
      base_dir = app_data_dir
      if base_dir.nil?
        nil
      else
        File.join(base_dir, 'Documents')
      end
    end

    def app_tmp_dir
      base_dir = app_data_dir
      if base_dir.nil?
        nil
      else
        File.join(base_dir, 'tmp')
      end
    end

    def reset_app_sandbox
      return true if !app_is_installed?

      shutdown

      reset_app_sandbox_internal
    end

    def update_device_state(options={})
      merged_options = UPDATE_DEVICE_STATE_OPTS.merge(options)

      interval = merged_options[:interval]
      tries = merged_options[:tries]

      debug_logging = RunLoop::Environment.debug?

      on_retry = Proc.new do |_, try, elapsed_time, next_interval|
        if debug_logging
          # Retriable 2.0
          if elapsed_time && next_interval
            puts "Updating device state attempt #{try} failed in '#{elapsed_time}'; will retry in '#{next_interval}'"
          else
            puts "Updating device state attempt #{try} failed; will retry in #{interval}"
          end
        end
      end

      retry_opts = RunLoop::RetryOpts.tries_and_interval(tries, interval,
                                                         {:on_retry => on_retry,
                                                          :on => [SimctlError]
                                                         })
      matching_device = nil

      Retriable.retriable(retry_opts) do
        matching_device = fetch_matching_device

        unless matching_device
          raise "simctl could not find device with '#{device.udid}'"
        end

        if matching_device.state == nil || matching_device.state == ''
          raise SimctlError, "Could not find the state of the device with #{device.udid}"
        end
      end

      # Device#state is immutable
      @device = matching_device
      @device.state
    end

    def wait_for_device_state(target_state)
      return true if update_device_state == target_state

      now = Time.now
      timeout = WAIT_FOR_DEVICE_STATE_OPTS[:timeout]
      poll_until = now + WAIT_FOR_DEVICE_STATE_OPTS[:timeout]
      delay = WAIT_FOR_DEVICE_STATE_OPTS[:interval]
      in_state = false
      while Time.now < poll_until
        in_state = update_device_state == target_state
        break if in_state
        sleep delay
      end

      if RunLoop::Environment.debug?
        puts "Waited for #{timeout} seconds for device to have state: '#{target_state}'."
      end

      unless in_state
        raise "Expected '#{target_state} but found '#{device.state}' after waiting."
      end
      in_state
    end

    def app_is_installed?
      !fetch_app_dir.nil?
    end

    # @!visibility private
    def fetch_app_dir
      sim_app_dir = device_applications_dir
      return nil if !File.exist?(sim_app_dir)
      Dir.glob("#{sim_app_dir}/**/*.app").detect(nil) do |path|
        RunLoop::App.new(path).bundle_identifier == app.bundle_identifier
      end
    end

    def wait_for_app_install
      return true if app_is_installed?

      now = Time.now
      timeout = WAIT_FOR_APP_INSTALL_OPTS[:timeout]
      poll_until = now + timeout
      delay = WAIT_FOR_APP_INSTALL_OPTS[:interval]
      is_installed = false
      while Time.now < poll_until
        is_installed = app_is_installed?
        break if is_installed
        sleep delay
      end

      if RunLoop::Environment.debug?
        puts "Waited for #{timeout} seconds for '#{app.bundle_identifier}' to install."
      end

      unless is_installed
        raise "Expected app to be installed on #{device.instruments_identifier}"
      end

      true
    end

    def wait_for_app_uninstall
      return true unless app_is_installed?

      now = Time.now
      timeout = WAIT_FOR_APP_INSTALL_OPTS[:timeout]
      poll_until = now + timeout
      delay = WAIT_FOR_APP_INSTALL_OPTS[:interval]
      not_installed = false
      while Time.now < poll_until
        not_installed = !app_is_installed?
        break if not_installed
        sleep delay
      end

      if RunLoop::Environment.debug?
        puts "Waited for #{timeout} seconds for '#{app.bundle_identifier}' to uninstall."
      end

      unless not_installed
        raise "Expected app to be installed on #{device.instruments_identifier}"
      end

      true
    end

    def shutdown
      return true if update_device_state == 'Shutdown'

      if device.state != 'Booted'
        raise "Cannot handle state '#{device.state}' for #{device.instruments_identifier}"
      end

      args = "simctl shutdown #{device.udid}".split(' ')
      Open3.popen3('xcrun', *args) do |_, _, stderr, status|
        err = stderr.read.strip
        exit_status = status.value.exitstatus
        if exit_status != 0
          raise "Could not shutdown #{device.instruments_identifier}: #{exit_status} => '#{err}'"
        end
      end
      wait_for_device_state('Shutdown')
    end

    def boot
      return true if update_device_state == 'Booted'

      if device.state != 'Shutdown'
        raise "Cannot handle state '#{device.state}' for #{device.instruments_identifier}"
      end

      args = "simctl boot #{device.udid}".split(' ')
      Open3.popen3('xcrun', *args) do |_, _, stderr, status|
        err = stderr.read.strip
        exit_status = status.value.exitstatus
        if exit_status != 0
          raise "Could not boot #{device.instruments_identifier}: #{exit_status} => '#{err}'"
        end
      end
      wait_for_device_state('Booted')
    end

    def install
      return true if app_is_installed?

      boot

      args = "simctl install #{device.udid} #{app.path}".split(' ')
      Open3.popen3('xcrun', *args) do |_, _, stderr, process_status|
        err = stderr.read.strip
        exit_status = process_status.value.exitstatus
        if exit_status != 0
          raise "Could not install '#{app.bundle_identifier}': #{exit_status} => '#{err}'."
        end
      end

      wait_for_app_install
      shutdown
    end

    def uninstall
      return true unless app_is_installed?

      boot

      args = "simctl uninstall #{device.udid} #{app.bundle_identifier}".split(' ')
      Open3.popen3('xcrun', *args) do |_, _, stderr, process_status|
        err = stderr.read.strip
        exit_status = process_status.value.exitstatus
        if exit_status != 0
          raise "Could not uninstall '#{app.bundle_identifier}': #{exit_status} => '#{err}'."
        end
      end

      wait_for_app_uninstall
      shutdown
    end

    def launch_simulator
      args = ['open', '-g', '-a', @path_to_ios_sim_app_bundle, '--args', '-CurrentDeviceUDID', device.udid]
      pid = spawn('xcrun', *args)
      Process.detach(pid)

      # @todo Does not always appear?
      # RunLoop::ProcessWaiter.new('CoreSimulatorBridge', WAIT_FOR_APP_LAUNCH_OPTS).wait_for_any
      sim_name = @sim_control.send(:sim_name)
      RunLoop::ProcessWaiter.new(sim_name, WAIT_FOR_APP_LAUNCH_OPTS).wait_for_any
      RunLoop::ProcessWaiter.new('SimulatorBridge', WAIT_FOR_APP_LAUNCH_OPTS).wait_for_any
      wait_for_device_state 'Booted'
      sleep(SIM_POST_LAUNCH_WAIT)
    end

    def launch

      install
      launch_simulator

      args = "simctl launch #{device.udid} #{app.bundle_identifier}".split(' ')
      Open3.popen3('xcrun', *args) do |_, _, stderr, process_status|
        err = stderr.read.strip
        exit_status = process_status.value.exitstatus
        unless exit_status == 0
          raise "Could not simctl launch '#{app.bundle_identifier}' on '#{device.instruments_identifier}': #{exit_status} => '#{err}'"
        end
      end

      RunLoop::ProcessWaiter.new(app.executable_name, WAIT_FOR_APP_LAUNCH_OPTS).wait_for_any
      true
    end

    private

    WAIT_FOR_DEVICE_STATE_OPTS =
          {
                interval: 0.1,
                timeout: 5
          }

    WAIT_FOR_APP_INSTALL_OPTS =
          {
                interval: 0.1,
                timeout: 20
          }

    WAIT_FOR_APP_LAUNCH_OPTS =
          {
                timeout: 10,
                raise_on_timeout: true
          }

    UPDATE_DEVICE_STATE_OPTS =
          {
                :tries => 100,
                :interval => 0.1
          }

    SIM_POST_LAUNCH_WAIT = RunLoop::Environment.sim_post_launch_wait || 1.0

    METADATA_PLIST = '.com.apple.mobile_container_manager.metadata.plist'
    CORE_SIMULATOR_DEVICE_DIR = File.expand_path('~/Library/Developer/CoreSimulator/Devices')

    # @!visibility private
    def fetch_matching_device
      sim_control.simulators.detect do |sim|
        sim.udid == device.udid
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
      device_prefs_dir = File.join(app_data_dir, 'Library', 'Preferences')
      app_prefs_plist = File.join(device_prefs_dir, "#{app.bundle_identifier}.plist")
      if File.exist?(app_prefs_plist)
        FileUtils.rm_rf(app_prefs_plist)
      end
    end

    # @!visibility private
    def reset_app_sandbox_internal
      reset_app_sandbox_internal_shared

      if is_sdk_8?
        reset_app_sandbox_internal_sdk_gte_8
      else
        reset_app_sandbox_internal_sdk_lt_8
      end
    end

    # @!visibility private
    def app_uia_crash_logs
      base_dir = app_data_dir
      if base_dir.nil?
        nil
      else
        dir = File.join(base_dir, 'Library', 'CrashReporter', 'UIALogs')
        if Dir.exist?(dir)
          Dir.glob("#{dir}/*.plist")
        else
          nil
        end
      end
    end
  end
end
