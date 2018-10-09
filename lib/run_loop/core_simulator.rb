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
    :wait_for_state_timeout => RunLoop::Environment.ci? ? 120 : 30,
    :app_launch_retries => RunLoop::Environment.ci? ? 5 : 3
  }

  # @!visibility private
  # This should not be overridden
  WAIT_FOR_SIMULATOR_STATE_INTERVAL = 0.1

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
  attr_reader :sim_keyboard

  # @!visibility private
  METADATA_PLIST = '.com.apple.mobile_container_manager.metadata.plist'

  # @!visibility private
  CORE_SIMULATOR_DEVICE_DIR = File.join(RunLoop::Environment.user_home_directory,
                                        "Library",
                                        "Developer",
                                        "CoreSimulator",
                                        "Devices")

  # @!visibility private
  PREFERENCES_PLIST = File.join(RunLoop::Environment.user_home_directory,
                                "Library", "Preferences",
                                "com.apple.iphonesimulator.plist")

  # @!visibility private
  MANAGED_PROCESSES =
        [
              # This process is a daemon, and requires 'KILL' to terminate.
              # Killing the process is fast, but it takes a long time to
              # restart.
              "com.apple.CoreSimulator.CoreSimulatorService",

              # Not yet.
              # "com.apple.CoreSimulator.SimVerificationService",

              "SimulatorBridge",
              "configd_sim",
              "CoreSimulatorBridge",

              # Xcode 7
              "ids_simd"
        ]

  # @!visibility private
  # Pattern:
  # [ '< process name >', < send term first > ]
  SIMULATOR_QUIT_PROCESSES =
        [
              # Xcode 7 start throwing this error.
              ["splashboardd", false],

              # Xcode >= 7.0
              ["Simulator", true],

              # Xcode < 7.0
              ["iOS Simulator", true],

              # Multiple launchd_sim processes have been causing problems.
              # In theory, killing the parent launchd_sim process should kill
              # child processes like assetsd, but in practice this does not
              # always happen.
              ["launchd_sim", false],

              # Required for DeviceAgent termination; the simulator hangs otherwise.
              ["xpcproxy", false],

              # assetsd instances clobber each other and are not properly
              # killed when quiting the simulator.
              ["assetsd", false],

              # iproxy is started by UITest.
              ["iproxy", false],

              # Started by Xamarin Studio, this is the parent process of the
              # processes launched by Xamarin's interaction with
              # CoreSimulatorBridge.
              ["csproxy", false],

              # Hundreds of these processes can be present in Xcode 8 and they
              # appear to influence the behavior of DeviceAgent.
              ["MobileSMSSpotlightImporter", false],
              ["UserEventAgent", false],
              ["mobileassetd", false],
              ["pkd", false],
              ["KeychainSyncingOverIDSProxy", false],
              ["CloudKeychainProxy", false],
              ["aslmanager", false],

              # Processes from Xcode 10
              ["diagnosticd", false],
              ["syslogd", false],
              ["mobiletimerd", false],
              ["carkitd", false]
        ]

  # @!visibility private
  #
  # Terminate CoreSimulator related processes.  This processes can accumulate
  # as testing proceeds and can cause instability.
  def self.terminate_core_simulator_processes

    start = Time.now

    self.quit_simulator

    MANAGED_PROCESSES.each do |process_name|
      send_term_first = false
      self.term_or_kill(process_name, send_term_first)
    end

    ps_name_fn = lambda do |pid|
      args = ["ps", "-o", "comm=", "-p", pid.to_s]
      out = RunLoop::Shell.run_shell_command(args)[:out]
      if out && out.strip != ""
        out.strip
      else
        "UNKNOWN PROCESS: #{pid}"
      end
    end

    term_options = { :timeout => 0.1 }
    kill_options = { :timeout => 0.0 }

    RunLoop::ProcessWaiter.pgrep_f("launchd_sim").each do |pid|
      process_name = ps_name_fn.call(pid)
      RunLoop::ProcessTerminator.new(pid, 'KILL', process_name, kill_options).kill_process
    end

    RunLoop::ProcessWaiter.pgrep_f("iPhoneSimulator").each do |pid|
      process_name = ps_name_fn.call(pid)
      RunLoop::ProcessTerminator.new(pid, 'KILL', process_name, kill_options).kill_process
    end

    RunLoop::ProcessWaiter.pgrep_f("CoreSimulator").each do |pid|
      args = ["ps", "-o", "uid=", pid.to_s]
      uid = RunLoop::Shell.run_shell_command(args)[:out].strip
      process_name = File.basename(ps_name_fn.call(pid))
      if uid != "0"

        term = RunLoop::ProcessTerminator.new(pid, 'TERM', process_name, term_options)
        killed = term.kill_process

        if !killed
          term = RunLoop::ProcessTerminator.new(pid, 'KILL', process_name, kill_options)
          term.kill_process
        end
      end
    end

    elapsed = Time.now - start
    RunLoop.log_debug("Took #{elapsed} to terminate CoreSimulator Services")
  end

  # @!visibility private
  # Quit any Simulator.app or iOS Simulator.app
  def self.quit_simulator
    RunLoop::DeviceAgent::Xcodebuild.terminate_simulator_tests

    SIMULATOR_QUIT_PROCESSES.each do |process_details|
      process_name = process_details[0]
      send_term_first = process_details[1]
      self.term_or_kill(process_name, send_term_first)
    end
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
  #
  # Per-user CoreSimulator preferences located in ~/Library/Preferences
  def self.simulator_preferences_plist(pbuddy)
    if !File.exist?(PREFERENCES_PLIST)
      pbuddy.create_plist(PREFERENCES_PLIST)
    end

    PREFERENCES_PLIST
  end

  # @!visibility private
  def self.hardware_keyboard_connected?(pbuddy)
    plist = self.simulator_preferences_plist(pbuddy)
    pbuddy.plist_read("ConnectHardwareKeyboard", plist)
  end

  # @!visibility private
  #
  # Connect the hardware keyboard so users can use the host machine keyboard
  # to type text during testing.
  def self.ensure_hardware_keyboard_connected(pbuddy)
    plist = self.simulator_preferences_plist(pbuddy)
    pbuddy.plist_set("ConnectHardwareKeyboard", "bool", true, plist)
  end

  # @!visibility private
  # Erase a simulator.  This is the same as touching the Simulator
  # "Reset Content & Settings" menu item.
  #
  # @param [RunLoop::Device] simulator The simulator to erase
  # @param [Hash] options Control the behavior of the method.
  # @option options [Numeric] :timeout How long to wait for simctl to
  #   shutdown the simulator. This is necessary for the erase to succeed.
  #
  # @raise RuntimeError If the simulator cannot be shutdown
  # @raise RuntimeError If the simulator cannot be erased
  # @raise ArgumentError If the simulator is a physical device
  def self.erase(simulator, options={})
    if simulator.physical_device?
      raise ArgumentError,
        "#{simulator} is a physical device.  This method is only for Simulators"
    end

    merged_options = DEFAULT_OPTIONS.merge(options)
    simctl = merged_options[:simctl] || RunLoop::Simctl.new
    timeout = merged_options[:timeout] || merged_options[:wait_for_state_timeout]

    simctl.erase(simulator,
                 timeout,
                 WAIT_FOR_SIMULATOR_STATE_INTERVAL)
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
      raise ArgumentError, "The language cannot be set on physical devices"
    end

    self.quit_simulator
    RunLoop.log_debug("Setting preferred language to '#{lang_code}'")
    simulator.simulator_set_language(lang_code)
  end

  # @!visibility private
  #
  # @param [RunLoop::Device, String] device a simulator UDID, instruments-ready
  #   name, or a RunLoop::Device
  # @param [String] bundle_identifier the app to check for
  #
  # @raise [ArgumentError] if no device can be found matching the UDID or
  #   instruments-ready name
  # @raise [ArgumentError] if device is not a simulator
  # @raise [ArgumentError] if language_code is invalid
  #
  # @return [Boolean] true if the app with the identifier is installed
  def self.app_installed?(device, bundle_identifier, options={})
    merged_options = {:xcode => RunLoop::Xcode.new}.merge(options)

    if device.is_a?(RunLoop::Device)
      simulator = device
    else
      simulator = RunLoop::Device.device_with_identifier(device, merged_options)
    end

    if simulator.physical_device?
      raise ArgumentError, "The device must be a simulator"
    end

    start = Time.now

    installed = self.send(:user_app_installed?, device, bundle_identifier) ||
      self.send(:system_app_installed?, bundle_identifier, merged_options[:xcode])

    RunLoop.log_debug("Took #{Time.now - start} seconds to check if app was installed")
    installed
  end

  # @param [RunLoop::Device] device The device.
  # @param [RunLoop::App] app The application.
  # @param [Hash] options Controls the behavior of this class.
  # @option options :quit_sim_on_init (true) If true, quit any running
  # @option options :xcode An instance of Xcode to use
  #  simulators in the initialize method.
  def initialize(device, app, options={})
    @app = app
    @device = device
    @xcode = options[:xcode]

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

  # @!visibility private
  def sim_keyboard
    @sim_keyboard ||= RunLoop::SimKeyboardSettings.new(device)
  end

  # @!visibility private
  def simctl
    @simctl ||= RunLoop::Simctl.new
  end

  # @!visibility private
  def simulator_requires_relaunch?
    [simulator_state_requires_relaunch?,
     running_apps_require_relaunch?].any?
  end

  # Launch the simulator indicated by device.
  def launch_simulator(options={})
    merged_options = {
      :wait_for_stable => true
    }.merge(options)

    if !simulator_requires_relaunch?
      RunLoop.log_debug("Simulator is running and does not require a relaunch.")
      return
    end

    RunLoop::CoreSimulator.quit_simulator
    RunLoop::CoreSimulator.ensure_hardware_keyboard_connected(pbuddy)
    sim_keyboard.ensure_soft_keyboard_will_show

    args = ['open', '-g', '-a', sim_app_path, '--args',
            '-CurrentDeviceUDID', device.udid,
            "-ConnectHardwareKeyboard", "0",
            "-DeviceBootTimeout", "120",
            # Yes, this is the argument even though it is not spelled correctly
            "-DetatchOnAppQuit", "0",
            "-DetachOnWindowClose", "0",
            "LAUNCHED_BY_RUN_LOOP"]

    RunLoop.log_debug("Launching #{device} with:")
    RunLoop.log_unix_cmd("xcrun #{args.join(' ')}")

    start_time = Time.now

    pid = Process.spawn('xcrun', *args)
    Process.detach(pid)

    options = { :timeout => 5, :raise_on_timeout => true }
    RunLoop::ProcessWaiter.new(sim_name, options).wait_for_any

    if merged_options[:wait_for_stable]
      device.simulator_wait_for_stable_state
    end

    elapsed = Time.now - start_time
    RunLoop.log_debug("Took #{elapsed} seconds to launch the simulator")

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

    tries = app_launch_retries

    RunLoop.log_debug("Trying #{tries} times to launch #{app.bundle_identifier} on #{device}")

    last_error = try_to_launch_app_n_times(tries)

    if last_error
      raise RuntimeError, %Q[
Could not launch #{app.bundle_identifier} on #{device} after trying #{tries} times:

#{last_error}:

#{last_error.message}

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
    if installed_app_bundle_dir ||
      simctl.app_container(device, app.bundle_identifier)
      true
    else
      false
    end
  end

  # Resets the app sandbox.
  #
  # Does nothing if the app is not installed.
  def reset_app_sandbox
    return true if !app_is_installed?

    RunLoop::CoreSimulator.quit_simulator
    RunLoop::CoreSimulator.wait_for_simulator_state(device, "Shutdown")

    reset_app_sandbox_internal
  end

  # Uninstalls the app and clears the sandbox.
  def uninstall_app_and_sandbox
    return true if !app_is_installed?

    uninstall_app_with_simctl
    true
  end

=begin
  PRIVATE METHODS
=end

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
    kill_options = { :timeout => 0.0 }

    RunLoop::ProcessWaiter.new(process_name).pids.each do |pid|

      # We could try to determine if terminating the process will be successful
      # by asking for the parent pid and the user id.  This adds another call
      # to `ps` and does not save any time.  It is easier to simply let the
      # ProcessTerminator fail.  The downside is that a failure will appear
      # in the debug log.
      #
      # macOS is looking more like iOS.  Process names like 'mobileassetd' are
      # found in both operating systems.

      args = ["ps", "-o", "uid=", pid.to_s]
      uid = RunLoop::Shell.run_shell_command(args)[:out].strip
      if uid != "0"
        killed = false

        if send_term_first
          term = RunLoop::ProcessTerminator.new(pid, 'TERM', process_name, term_options)
          killed = term.kill_process
        end

        if !killed
          term = RunLoop::ProcessTerminator.new(pid, 'KILL', process_name, kill_options)
          term.kill_process
        end
      end
    end
  end

  # Returns the current simulator name.
  #
  # @return [String] A String suitable for searching for a pid, quitting, or
  #  launching the current simulator.
  def sim_name
    @sim_name ||= "Simulator"
  end

  # @!visibility private
  # Returns the path to the current simulator.
  #
  # @return [String] The path to the simulator app for the current version of
  #  Xcode.
  def sim_app_path
    @sim_app_path ||= begin
      "#{xcode.developer_dir}/Applications/#{sim_name}.app"
    end
  end

  # @!visibility private
  #
  # @return [Hash] details about the running simulator.
  def running_simulator_details
    process_name = "MacOS/#{sim_name}"

    args = ["ps", "x", "-o", "pid=,command="]
    hash = run_shell_command(args)

    exit_status = hash[:exit_status]
    if exit_status != 0
      raise RuntimeError,
%Q{Could not find the process details of #{sim_name} with:

#{args.join(" ")}

Command exited with status: #{exit_status}

  '#{hash[:out]}'
}
    end

    if hash[:out].nil? || hash[:out] == ""
       raise RuntimeError,
%Q{Could not find the process details of #{sim_name} with:

#{args.join(" ")}

Command had no output.
}
    end

    lines = hash[:out].split($-0)

    match = lines.detect do |line|
      line[/#{process_name}/]
    end

    return {} if match.nil?

    hash = {}

    pid = match.split(" ").first.strip.to_i
    hash[:pid] = pid

    hash[:launched_by_run_loop] = match[/LAUNCHED_BY_RUN_LOOP/]

    hash
  end

  # @!visibility private
  def uninstall_app_with_simctl
    launch_simulator

    app_size = RunLoop::Directory.size(app.path, :mb)
    sim_size = device.simulator_size_on_disk
    target_size = sim_size - app_size + 5

    timeout = DEFAULT_OPTIONS[:install_app_timeout]
    simctl.uninstall(device, app, timeout)

    current_size = device.simulator_size_on_disk
    start = Time.now
    while current_size > target_size && Time.now < start + 5
      sleep(0.5)
      current_size = device.simulator_size_on_disk
    end

    elapsed = Time.now - start
    if current_size <= target_size
      RunLoop.log_debug("Waited for #{elapsed} seconds for app to uninstall")
    else
      RunLoop.log_debug("Timed out after #{elapsed} seconds for app to uninstall")
      RunLoop.log_debug("Expected sim size #{current_size} < #{target_size}")
    end
  end

  # @!visibility private
  def install_app_with_simctl
    launch_simulator

    app_size = RunLoop::Directory.size(app.path, :mb)
    sim_size = device.simulator_size_on_disk
    target_size = sim_size + app_size

    timeout = DEFAULT_OPTIONS[:install_app_timeout]
    simctl.install(device, app, timeout)

    current_size = device.simulator_size_on_disk
    start = Time.now
    while current_size <= target_size && Time.now < start + 5
      sleep(0.5)
      current_size = device.simulator_size_on_disk
    end

    elapsed = Time.now - start
    if current_size > target_size
      RunLoop.log_debug("Waited for #{elapsed} seconds for app to install")
    else
      RunLoop.log_debug("Timed out after #{elapsed} seconds for app to install")
      RunLoop.log_debug("Expected sim size #{current_size} >= #{target_size}")
    end

    installed_app_bundle_dir
  end

  # @!visibility private
  def launch_app_with_simctl
    timeout = DEFAULT_OPTIONS[:launch_app_timeout]
    simctl.launch(device, app, timeout)
  end

  # @!visibility private
  #
  # Returns nil if launch_app_with_simctl succeeds and the error if it fails.
  def try_to_launch_app
    begin
      launch_app_with_simctl
      nil
    rescue RuntimeError, RunLoop::Xcrun::TimeoutError  => error
      # Simulator is probably in a bad state.  Restart the service.
      RunLoop::CoreSimulator.terminate_core_simulator_processes
      Kernel.sleep(0.5)
      launch_simulator
      error
    end
  end

  # @!visibility private
  def app_launch_retries
    DEFAULT_OPTIONS[:app_launch_retries]
  end

  # @!visibility private
  #
  # Returns nil if launch_app_with_simctl succeeds and the error if it fails.
  def try_to_launch_app_n_times(tries)
    last_error = nil

    tries.times do |try|
      # Terminates CoreSimulatorService on failures and launches the simulator again.
      # Returns nil if app launched.
      # Returns rescued Runtime or Timeout errors.
      last_error = try_to_launch_app

      break if last_error.nil?
      RunLoop.log_debug("Failed to launch app on try #{try + 1} of #{tries}.")
    end

    last_error
  end

  # Required for support of iOS 7 CoreSimulators.  Can be removed when
  # Xcode support is dropped.
  def sdk_gte_8?
    device.version >= RunLoop::Version.new('8.0')
  end

  # @!visibility private
  def simulator_state_requires_relaunch?
    running_sim_details = running_simulator_details

    # Simulator is not running.
    if !running_sim_details[:pid]
      RunLoop.log_debug("Simulator relaunch required: simulator is not running.")
      return true
    end

    # Simulator is running, but run-loop did not launch it.
    if !running_sim_details[:launched_by_run_loop]
      RunLoop.log_debug("Simulator relaunch required: simulator was not launched by run_loop")
      return true
    end

    if !RunLoop::CoreSimulator.hardware_keyboard_connected?(pbuddy)
      RunLoop.log_debug("Simulator relaunch required: hardware keyboard not connected.")
      return true
    end

    if !sim_keyboard.soft_keyboard_will_show?
      RunLoop.log_debug("Simulator relaunch required:  software keyboard is minimized")
      return true
    end

    # Simulator is running, run_loop launched it, but it is not Booted.
    device.update_simulator_state
    if device.state == "Booted"
      RunLoop.log_debug("Simulator relaunch not required: simulator has state 'Booted'")
      false
    else
      RunLoop.log_debug("Simulator relaunch required: simulator does not have state 'Booted'")
      true
    end
  end

  # @!visibility private
  def device_agent_launched_by_xcode?(running_apps)
    process_info = running_apps["XCTRunner"] || running_apps["DeviceAgent-Runner"]
    return false if !process_info

    process_info[:args][/CBX_LAUNCHED_BY_XCODE/]
  end

  # @!visibility private
  def running_apps_require_relaunch?
    running_apps = device.simulator_running_app_details

    if running_apps.empty?
      RunLoop.log_debug("Simulator relaunch not required: no running apps")
      return false
    end

    # DeviceAgent is running, but it was launched by Xcode.
    if device_agent_launched_by_xcode?(running_apps)
      RunLoop.log_debug("Simulator relaunch required: XCTRunner is controlled by Xcode")
      return true
    end

    # Why?
    # No app was passed to initializer.
    if app.nil?
      RunLoop.log_debug("Simulator relaunch required: no app was passed to CoreSimulator.new")
      return true
    end

    # AUT is running, but it was not launched by DeviceAgent.
    app_name = app.executable_name
    if running_apps[app_name]
      launch_arg = RunLoop::DeviceAgent::Client::AUT_LAUNCHED_BY_RUN_LOOP_ARG
      if !running_apps[app_name][:args][/#{launch_arg}/]
        RunLoop.log_debug("Simulator relaunch required: AUT is running, but not launched by run-loop")
        return true
      end
    end

    # This is the UITest behavior.  UITest does not inspect the simulator for
    # system apps that are running - it only checks for running user apps.
    #
    # I don't think this condition is necessary, so we'll skip it for now, but
    # capture there is a difference between UITest and run-loop.
    #
    # There is some other application running on the simulator.
    # running_apps.delete("XCTRunner")
    # running_apps.delete(app_name)
    #
    # if running_apps.empty?
    #   RunLoop.log_debug("Simulator relaunch not required: only XCTRunner and AUT are running")
    #   false
    # else
    #   RunLoop.log_debug("Simulator relaunch required: other applications are running")
    #   true
    # end
    false
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

    uninstall_app_with_simctl
    install_app_with_simctl
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

  # @!visibility private
  def self.system_applications_dir(xcode=RunLoop::Xcode.new)
    base_dir = xcode.developer_dir

    if xcode.version_gte_90?
      apps_dir = File.join("Platforms", "iPhoneOS.platform", "Developer",
                           "Library", "CoreSimulator", "Profiles", "Runtimes",
                           "iOS.simruntime", "Contents", "Resources",
                           "RuntimeRoot", "Applications")
    else
      apps_dir = File.join("Platforms", "iPhoneSimulator.platform", "Developer",
                           "SDKs", "iPhoneSimulator.sdk", "Applications")
    end
    File.expand_path(File.join(base_dir, apps_dir))
  end

  # @!visibility private
  def self.system_app_installed?(bundle_identifier, xcode)
    apps_dir = self.send(:system_applications_dir, xcode)

    return false if !File.exist?(apps_dir)

    if xcode.version_gte_90?
      black_list = [
        "AirMusic.app", "AirPodcasts.app", "AppStore.app", "Calculator.app",
        "CheckerBoard.app", "CTCarrierSpaceAuth.app", "Diagnostics.app",
        "DiagnosticsService.app", "FaceTime.app", "Feedback Assistant iOS.app",
        "FindMyFriends.app", "iBooks.app", "Magnifier.app", "MobileMail.app",
        "MobileNotes.app", "Music.app", "Podcasts.app", "PreBoard.app",
        "SoftwareUpdateUIService.app", "StoreDemoViewService.app", "TV.app",
        "Videos.app"
      ]
    else
      black_list = ["Fitness.app", "Photo Booth.app", "ScreenSharingViewService.app"]
    end

    Dir.glob("#{apps_dir}/*.app").detect do |app_dir|
      basename = File.basename(app_dir)
      if black_list.include?(basename)
        false
      else
        begin
          RunLoop::App.new(app_dir).bundle_identifier == bundle_identifier
        rescue ArgumentError => _
          bundle_name = File.basename(app_dir)
          RunLoop.log_debug("Could not create an App from simulator system app: #{bundle_name}")
          nil
        end
      end
    end
  end

  # @!visibility private
  def self.user_app_installed?(device, bundle_identifier)
    core_sim = self.new(device, bundle_identifier)
    sim_apps_dir = core_sim.send(:device_applications_dir)
    Dir.glob("#{sim_apps_dir}/**/*.app").find do |path|
      RunLoop::App.new(path).bundle_identifier == bundle_identifier
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
