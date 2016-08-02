# A class to manage interactions with CoreSimulators.
class RunLoop::CoreSimulator

  require "run_loop/shell"
  include RunLoop::Shell

  # These options control various aspects of an app's life cycle on the iOS
  # Simulator.
  #
  # You can override these values if they do not work in your environment.
  #
  # For cucumber users, the best place to override would be in your
  # features/support/env.rb.
  #
  # For example:
  #
  # RunLoop::CoreSimulator::DEFAULT_OPTIONS[:install_app_timeout] = 60
  DEFAULT_OPTIONS = {
    # In most cases 30 seconds is a reasonable amount of time to wait for an
    # install.  When testing larger apps, on slow machines, or in CI, this
    # value may need to be higher.  120 is the default for CI.
    :install_app_timeout => RunLoop::Environment.ci? ? 120 : 30,
    :uninstall_app_timeout => RunLoop::Environment.ci? ? 120 : 30,
    :launch_app_timeout => RunLoop::Environment.ci? ? 120 : 30,
    :wait_for_state_timeout => RunLoop::Environment.ci? ? 120 : 30
  }

  # @!visibility private
  # This should not be overridden
  WAIT_FOR_SIMULATOR_STATE_INTERVAL = 0.1

  # @!visibility private
  @@simulator_pid = nil

  # @!visibility private
  attr_reader :app

  # @!visibility private
  attr_reader :device

  # @!visibility private
  attr_reader :pbuddy

  # @!visibility private
  attr_reader :xcode

  # @!visibility private
  attr_reader :xcrun

  # @!visibility private
  METADATA_PLIST = '.com.apple.mobile_container_manager.metadata.plist'

  # @!visibility private
  CORE_SIMULATOR_DEVICE_DIR = File.join(RunLoop::Environment.user_home_directory,
                                        "Library",
                                        "Developer",
                                        "CoreSimulator",
                                        "Devices")


  # @!visibility private
  MANAGED_PROCESSES =
        [
              # This process is a daemon, and requires 'KILL' to terminate.
              # Killing the process is fast, but it takes a long time to
              # restart.
              "com.apple.CoreSimulator.CoreSimulatorService",

              # Not yet.
              # "com.apple.CoreSimulator.SimVerificationService",

              'SimulatorBridge',
              'configd_sim',
              'CoreSimulatorBridge',

              # Xcode 7
              'ids_simd'
        ]

  # @!visibility private
  # Pattern:
  # [ '< process name >', < send term first > ]
  SIMULATOR_QUIT_PROCESSES =
        [
              # Xcode 7 start throwing this error.
              ['splashboardd', false],

              # Xcode < 5.1
              ['iPhone Simulator.app', true],

              # 7.0 < Xcode <= 6.0
              ['iOS Simulator.app', true],

              # Xcode >= 7.0
              ['Simulator.app', true],

              # Multiple launchd_sim processes have been causing problems.  This
              # is a first pass at investigating what it would mean to kill the
              # launchd_sim process.
              ['launchd_sim', false],

              # Required for XCUITest termination; the simulator hangs otherwise.
              ["xpcproxy", false],

              # Causes crash reports on Xcode < 7.0
              ["apsd", true],

              # assetsd instances clobber each other and are not properly
              # killed when quiting the simulator.
              ['assetsd', false],

              # iproxy is started by UITest.
              ['iproxy', false],

              # Started by Xamarin Studio, this is the parent process of the
              # processes launched by Xamarin's interaction with
              # CoreSimulatorBridge.
              ['csproxy', false],
        ]

  # @!visibility private
  #
  # Terminate CoreSimulator related processes.  This processes can accumulate
  # as testing proceeds and can cause instability.
  def self.terminate_core_simulator_processes

    self.quit_simulator

    MANAGED_PROCESSES.each do |process_name|
      send_term_first = false
      self.term_or_kill(process_name, send_term_first)
    end
  end

  # @!visibility private
  # Quit any Simulator.app or iOS Simulator.app
  def self.quit_simulator
    SIMULATOR_QUIT_PROCESSES.each do |process_details|
      process_name = process_details[0]
      send_term_first = process_details[1]
      self.term_or_kill(process_name, send_term_first)
    end

    self.simulator_pid = nil
  end

  # @!visibility private
  #
  # Some operations, like erase, require that the simulator be
  # 'Shutdown'.
  #
  # @param [RunLoop::Device] simulator the sim to wait for
  # @param [String] target_state the state to wait for
  def self.wait_for_simulator_state(simulator, target_state)
    now = Time.now
    timeout = DEFAULT_OPTIONS[:wait_for_state_timeout]
    poll_until = now + timeout
    delay = WAIT_FOR_SIMULATOR_STATE_INTERVAL
    in_state = false
    while Time.now < poll_until
      in_state = simulator.update_simulator_state == target_state
      break if in_state
      sleep delay if delay != 0
    end

    elapsed = Time.now - now
    RunLoop.log_debug("Waited for #{elapsed} seconds for device to have state: '#{target_state}'.")

    unless in_state
      raise "Expected '#{target_state} but found '#{simulator.state}' after waiting."
    end
    in_state
  end

  # @!visibility private
  # Erase a simulator.  This is the same as touching the Simulator
  # "Reset Content & Settings" menu item.
  #
  # @param [RunLoop::Device] simulator The simulator to erase
  # @param [Hash] options Control the behavior of the method.
  # @option options [Numeric] :timeout (180) How long tow wait for simctl to
  #   shutdown and erase the simulator.  The timeout is apply separately to
  #   each command.
  #
  # @raise RuntimeError If the simulator cannot be shutdown
  # @raise RuntimeError If the simulator cannot be erased
  # @raise ArgumentError If the simulator is a physical device
  def self.erase(simulator, options={})
    if simulator.physical_device?
      raise ArgumentError,
        "#{simulator} is a physical device.  This method is only for Simulators"
    end

    default_options = {
      :timeout => 60*3
    }

    merged_options = default_options.merge(options)

    self.quit_simulator

    xcrun = merged_options[:xcrun] || RunLoop::Xcrun.new
    timeout = merged_options[:timeout]
    xcrun_opts = {
      :log_cmd => true,
      :timeout => timeout
    }

    if simulator.update_simulator_state != "Shutdown"
      args = ["simctl", "shutdown", simulator.udid]
      xcrun.run_command_in_context(args, xcrun_opts)
      begin
        self.wait_for_simulator_state(simulator, "Shutdown")
      rescue RuntimeError => _
        raise RuntimeError, %Q{
Could not erase simulator because it could not be Shutdown.

This usually means your CoreSimulator processes need to be restarted.

You can restart the CoreSimulator processes with this command:

$ bundle exec run-loop simctl manage-processes

}

      end
    end

    args = ["simctl", "erase", simulator.udid]
    hash = xcrun.run_command_in_context(args, xcrun_opts)

    if hash[:exit_status] != 0
      raise RuntimeError, %Q{
Could not erase simulator because simctl returned this error:

#{hash[:out]}

This usually means your CoreSimulator processes need to be restarted.

You can restart the CoreSimulator processes with this command:

$ bundle exec run-loop simctl manage-processes

}

    end

    hash
  end

  # @!visibility private
  #
  # @param [RunLoop::Device, String] device a simulator UDID, instruments-ready
  #  name, or a RunLoop::Device.
  #
  # @param [String] locale_code a locale code
  #
  # @raise [ArgumentError] if no device can be found matching the UDID or
  #   instruments-ready name
  # @raise [ArgumentError] if device is not a simulator
  # @raise [ArgumentError] if locale_code is invalid
  def self.set_locale(device, locale_code)
    if device.is_a?(RunLoop::Device)
      simulator = device
    else
      simulator = RunLoop::Device.device_with_identifier(device)
    end

    if simulator.physical_device?
      raise ArgumentError,
        "The locale cannot be set on physical devices"
    end

    self.quit_simulator
    RunLoop.log_debug("Setting locale to '#{locale_code}'")
    simulator.simulator_set_locale(locale_code)
  end

  # @!visibility private
  #
  # @param [RunLoop::Device, String] device a simulator UDID, instruments-ready
  #   name, or a RunLoop::Device
  # @param [String] lang_code a language code
  #
  # @raise [ArgumentError] if no device can be found matching the UDID or
  #   instruments-ready name
  # @raise [ArgumentError] if device is not a simulator
  # @raise [ArgumentError] if language_code is invalid
  def self.set_language(device, lang_code)
    if device.is_a?(RunLoop::Device)
      simulator = device
    else
      simulator = RunLoop::Device.device_with_identifier(device)
    end

    if simulator.physical_device?
      raise ArgumentError,
        "The language cannot be set on physical devices"
    end

    self.quit_simulator
    RunLoop.log_debug("Setting preferred language to '#{lang_code}'")
    simulator.simulator_set_language(lang_code)
  end

  # @!visibility private
  def self.simulator_pid
    @@simulator_pid
  end

  # @!visibility private
  def self.simulator_pid=(pid)
    @@simulator_pid = pid
  end

  # @param [RunLoop::Device] device The device.
  # @param [RunLoop::App] app The application.
  # @param [Hash] options Controls the behavior of this class.
  # @option options :quit_sim_on_init (true) If true, quit any running
  # @option options :xcode An instance of Xcode to use
  #  simulators in the initialize method.
  def initialize(device, app, options={})
    defaults = { :quit_sim_on_init => true }
    merged = defaults.merge(options)

    @app = app
    @device = device

    @xcode = merged[:xcode]

    if merged[:quit_sim_on_init]
      RunLoop::CoreSimulator.quit_simulator
    end

    # stdio.pipe - can cause problems finding the SHA of a simulator
    rm_instruments_pipe
  end

  # @!visibility private
  def pbuddy
    @pbuddy ||= RunLoop::PlistBuddy.new
  end

  # @!visibility private
  def xcode
    @xcode ||= RunLoop::Xcode.new
  end

  # @!visibility private
  def xcrun
    @xcrun ||= RunLoop::Xcrun.new
  end

  # Launch the simulator indicated by device.
  def launch_simulator

    if running_simulator_pid != nil
      # There is a running simulator.

      # Did we launch it?
      if running_simulator_pid == RunLoop::CoreSimulator.simulator_pid
        # Nothing to do, we already launched the simulator.
        return
      else
        # We did not launch this simulator; quit it.
        RunLoop::CoreSimulator.quit_simulator
      end
    end

    args = ['open', '-g', '-a', sim_app_path, '--args', '-CurrentDeviceUDID', device.udid]

    RunLoop.log_debug("Launching #{device} with:")
    RunLoop.log_unix_cmd("xcrun #{args.join(' ')}")

    start_time = Time.now

    pid = Process.spawn('xcrun', *args)
    Process.detach(pid)

    options = { :timeout => 5, :raise_on_timeout => true }
    RunLoop::ProcessWaiter.new(sim_name, options).wait_for_any

    device.simulator_wait_for_stable_state

    elapsed = Time.now - start_time
    RunLoop.log_debug("Took #{elapsed} seconds to launch the simulator")

    # Keep track of the pid so we can know if we have already launched this sim.
    RunLoop::CoreSimulator.simulator_pid = running_simulator_pid

    true
  end

  # Launch the app on the simulator.
  #
  # 1. If the app is not installed, it is installed.
  # 2. If the app is different from the app that is installed, it is installed.
  def launch
    install

    # If the app is the same, install will not launch the simulator.
    # In order to launch the app, the simulator needs to be running.
    # launch_simulator ensures that the sim is launched and will not
    # relaunch it.
    launch_simulator

    tries = RunLoop::Environment.ci? ? 5 : 3
    last_error = nil

    RunLoop.log_debug("Trying #{tries} times to launch #{app.bundle_identifier} on #{device}")

    tries.times do |try|
      # Terminates CoreSimulatorService on failures.
      hash = attempt_to_launch_app_with_simctl

      exit_status = hash[:exit_status]
      if exit_status != 0
        # Last argument is how long to sleep after an error.
        last_error = handle_failed_app_launch(hash, try, tries, 0.5)
      else
        last_error = nil
        break
      end
    end

    if last_error
      raise RuntimeError, %Q[Could not launch #{app.bundle_identifier} on #{device}

#{last_error}

]
    end

    wait_for_app_launch
  end

  # @!visibility private
  def wait_for_app_launch
    options = {
      :timeout => 10,
      :raise_on_timeout => true
    }
    RunLoop::ProcessWaiter.new(app.executable_name, options).wait_for_any
    device.simulator_wait_for_stable_state
    true
  end

  # Install the app.
  #
  # 1. If the app is not installed, it is installed.
  # 2. Does nothing, if the app is the same as the one that is installed.
  # 3. Installs the app if it is different from the installed app.
  #
  # The app sandbox is not touched.
  def install
    installed_app_bundle = installed_app_bundle_dir

    # App is not installed. Use simctl interface to install.
    if !installed_app_bundle
      installed_app_bundle = install_app_with_simctl
    else
      ensure_app_same
    end

    installed_app_bundle
  end

  # Is this app installed?
  def app_is_installed?
    !installed_app_bundle_dir.nil?
  end

  # Resets the app sandbox.
  #
  # Does nothing if the app is not installed.
  def reset_app_sandbox
    return true if !app_is_installed?

    RunLoop::CoreSimulator.wait_for_simulator_state(device, "Shutdown")

    reset_app_sandbox_internal
  end

  # Uninstalls the app and clears the sandbox.
  def uninstall_app_and_sandbox
    return true if !app_is_installed?

    launch_simulator

    args = ["simctl", 'uninstall', device.udid, app.bundle_identifier]

    timeout = DEFAULT_OPTIONS[:uninstall_app_timeout]
    xcrun.run_command_in_context(args, log_cmd: true, timeout: timeout)

    device.simulator_wait_for_stable_state
    true
  end

  private

  # @!visibility private
  #
  # This stdio.pipe file causes problems when checking the size and taking the
  # checksum of the core simulator directory.
  def rm_instruments_pipe
    device_tmp_dir = File.join(device_data_dir, 'tmp')
    Dir.glob("#{device_tmp_dir}/instruments_*/stdio.pipe") do |file|
      if File.exist?(file)
        RunLoop.log_debug("Deleting #{file}")
        FileUtils.rm_rf(file)
      end
    end
  end

  # Send 'TERM' then 'KILL' to allow processes to quit cleanly.
  def self.term_or_kill(process_name, send_term_first)
    term_options = { :timeout => 0.5 }
    kill_options = { :timeout => 0.5 }

    RunLoop::ProcessWaiter.new(process_name).pids.each do |pid|
      killed = false

      if send_term_first
        term = RunLoop::ProcessTerminator.new(pid, 'TERM', process_name, term_options)
        killed = term.kill_process
      end

      unless killed
        RunLoop::ProcessTerminator.new(pid, 'KILL', process_name, kill_options)
      end
    end
  end

  # Returns the current simulator name.
  #
  # @return [String] A String suitable for searching for a pid, quitting, or
  #  launching the current simulator.
  def sim_name
    @sim_name ||= lambda {
      if xcode.version_gte_7?
        "Simulator"
      else
        "iOS Simulator"
      end
    }.call
  end

  # @!visibility private
  # Returns the path to the current simulator.
  #
  # @return [String] The path to the simulator app for the current version of
  #  Xcode.
  def sim_app_path
    @sim_app_path ||= lambda {
      dev_dir = xcode.developer_dir
      if xcode.version_gte_7?
        "#{dev_dir}/Applications/Simulator.app"
      else
        "#{dev_dir}/Applications/iOS Simulator.app"
      end
    }.call
  end

  # @!visibility private
  # Returns the current Simulator pid.
  #
  # @note Will only search for the current Xcode simulator.
  #
  # @return [Integer, nil] The pid as a String or nil if no process is found.
  def running_simulator_pid
    process_name = "MacOS/#{sim_name}"

    args = ["ps", "x", "-o", "pid,command"]
    hash = run_shell_command(args)

    exit_status = hash[:exit_status]
    if exit_status != 0
      raise RuntimeError,
%Q{Could not find the pid of #{sim_name} with:

#{args.join(" ")}

Command exited with status #{exit_status}
Message: '#{hash[:out]}'
}
    end

    if hash[:out].nil? || hash[:out] == ""
       raise RuntimeError,
%Q{Could not find the pid of #{sim_name} with:

#{args.join(" ")}

Command had no output
}
    end

    lines = hash[:out].split("\n")

    match = lines.detect do |line|
      line[/#{process_name}/, 0]
    end

    return nil if match.nil?

    match.split(" ").first.to_i
  end

  # @!visibility private
  def install_app_with_simctl
    launch_simulator

    args = ["simctl", 'install', device.udid, app.path]
    timeout = DEFAULT_OPTIONS[:install_app_timeout]
    xcrun.run_command_in_context(args, log_cmd: true, timeout: timeout)

    device.simulator_wait_for_stable_state
    installed_app_bundle_dir
  end

  # @!visibility private
  def launch_app_with_simctl
    args = ["simctl", 'launch', device.udid, app.bundle_identifier]
    timeout = DEFAULT_OPTIONS[:launch_app_timeout]
    xcrun.run_command_in_context(args, log_cmd: true, timeout: timeout)
  end

  # @!visibility private
  def handle_failed_app_launch(hash, try, tries, wait_time)
    out = hash[:out]
    RunLoop.log_debug("Failed to launch app on try #{try + 1} of #{tries}.")
    out.split($-0).each do |line|
      RunLoop.log_debug("    #{line}")
    end
    # If we timed out on the launch, the CoreSimulator processes are quit
    # (see above).  If at all possible, we want to avoid terminating
    # CoreSimulatorService, because it takes a long time to launch.
    sleep(wait_time) if wait_time > 0

    out
  end

  # @!visibility private
  def attempt_to_launch_app_with_simctl
    begin
      hash = launch_app_with_simctl
    rescue RunLoop::Xcrun::TimeoutError => e
      hash = {
        :exit_status => 1,
        :out => e.message
      }
      # Simulator is probably in a bad state.  Terminates the
      # CoreSimulatorService.  Restarting this service is expensive!
      RunLoop::CoreSimulator.terminate_core_simulator_processes
      Kernel.sleep(0.5)
      launch_simulator
    end
    hash
  end

  # Required for support of iOS 7 CoreSimulators.  Can be removed when
  # Xcode support is dropped.
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

  # A cache of installed apps on the device.
  def device_caches_dir
    @device_caches_dir ||= File.join(device_data_dir, 'Library', 'Caches')
  end

  # Required after when installing and uninstalling.
  def clear_device_launch_csstore
    glob = File.join(device_caches_dir, "com.apple.LaunchServices-*.csstore")
    Dir.glob(glob) do | ccstore |
      FileUtils.rm_f ccstore
    end
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

  # Returns the path to the installed app bundle directory (.app).
  #
  # If this method returns nil, the app is not installed.
  def installed_app_bundle_dir
    sim_app_dir = device_applications_dir
    return nil if !File.exist?(sim_app_dir)

    app_bundle_dir = Dir.glob("#{sim_app_dir}/**/*.app").find do |path|
      RunLoop::App.new(path).bundle_identifier == app.bundle_identifier
    end

    app_bundle_dir = ensure_complete_app_installation(app_bundle_dir)

    app_bundle_dir
  end

  # Cleans up bad installations of an app.  For unknown reasons, an app bundle
  # can exist, but be unrecognized by CoreSimulator.  If we detect a case like
  # this, we need to clean up the installation.
  def ensure_complete_app_installation(app_bundle_dir)
    return nil if app_bundle_dir.nil?
    return app_bundle_dir if complete_app_install?(app_bundle_dir)

    # Remove the directory that contains the app bundle
    base_dir = File.dirname(app_bundle_dir)
    FileUtils.rm_rf(base_dir)

    # Clean up Containers/Data/Application
    remove_stale_data_containers

    nil
  end

  # Detect an incomplete app installation.
  def complete_app_install?(app_bundle_dir)
    base_dir = File.dirname(app_bundle_dir)
    plist = File.join(base_dir, METADATA_PLIST)
    File.exist?(plist)
  end

  # Remove stale data directories that might have appeared as a result of an
  # incomplete app installation.
  # See #ensure_complete_app_installation
  def remove_stale_data_containers
    containers_data_dir = File.join(device_data_dir, "Containers", "Data", "Application")
    apps = Dir.glob("#{containers_data_dir}/**/#{METADATA_PLIST}")
    apps.each do |metadata_plist|
      if pbuddy.plist_read("MCMMetadataIdentifier", metadata_plist) == app.bundle_identifier
        FileUtils.rm_rf(File.dirname(metadata_plist))
      end
    end
  end

  # 1. Does nothing if the app is not installed.
  # 2. Does nothing if the app the same as the app that is installed
  # 3. Installs app if it is different from the installed app
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

    RunLoop.log_debug("The app you are testing is not the same as the app that is installed.")
    RunLoop.log_debug("  Installed app SHA: #{installed_sha}")
    RunLoop.log_debug("  App to launch SHA: #{app_sha}")
    RunLoop.log_debug("Will install #{app}")

    FileUtils.rm_rf installed_app_bundle
    RunLoop.log_debug('Deleted the existing app')

    directory = File.expand_path(File.join(installed_app_bundle, '..'))
    bundle_name = File.basename(app.path)
    target = File.join(directory, bundle_name)

    args = ['ditto', app.path, target]
    xcrun.run_command_in_context(args, log_cmd: true)

    RunLoop.log_debug("Installed #{app} on CoreSimulator #{device.udid}")

    clear_device_launch_csstore

    true
  end

  # Shared tasks across CoreSimulators iOS 7 and > iOS 7
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

  # Not yet.  Failing on Travis and this is not a feature yet.
  #
  # There is a spec that has been commented out.
  # @!visibility private
  # TODO Command line tool
  # def app_uia_crash_logs
  #   base_dir = app_library_dir
  #   if base_dir.nil?
  #     nil
  #   else
  #     dir = File.join(base_dir, 'CrashReporter', 'UIALogs')
  #     if Dir.exist?(dir)
  #       Dir.glob("#{dir}/*.plist")
  #     else
  #       nil
  #     end
  #   end
  # end
end
