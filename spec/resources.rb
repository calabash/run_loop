require 'singleton'

class Resources

  include RunLoop::Regex
  include Singleton

  attr_reader :xcode

  attr_accessor :fake_instruments_pids

  def self.shared
    Resources.instance
  end

  def travis_ci?
    @travis_ci ||= ENV['TRAVIS'].to_s == 'true'
  end

  def whoami
    @whoami ||= ENV['USER'].strip
  end

  def launch_retries
    travis_ci? ? 8 : 2
  end

  def xcode
    @xcode ||= RunLoop::Xcode.new
  end

  def core_simulator_env?
    xcode.version_gte_6?
  end

  def instruments
    @instruments ||= RunLoop::Instruments.new
  end

  def sim_control
    @sim_control ||= RunLoop::SimControl.new
  end

  def with_debugging(&block)
    original_value = ENV['DEBUG']
    ENV['DEBUG'] = '1'
    begin
      block.call
    ensure
      ENV['DEBUG'] = original_value
    end
  end

  def current_xcode_version
    xcode.version
  end

  def resources_dir
    @resources_dir = File.expand_path(File.join(File.dirname(__FILE__),  'resources'))
  end

  def infinite_run_loop_script
    @infinite_run_loop_script = File.expand_path(File.join(resources_dir, 'infinite_run_loop.js'))
  end

  def cal_app_bundle_path
    @cal_app_bundle_path ||= File.expand_path(File.join(resources_dir, 'CalSmoke-cal.app'))
  end

  def app_bundle_path
    @app_bundle_path ||= File.expand_path(File.join(resources_dir, 'CalSmoke.app'))
  end

  def ipa_path
    @ipa_path ||= File.expand_path(File.join(resources_dir, 'CalSmoke-cal.ipa'))
  end

  def sim_dylib_path
    @sim_dylib_path ||= File.expand_path(File.join(resources_dir, 'dylibs', 'libCalabashDynSim.dylib'))
  end

  def app_bundle_path_arm_FAT
    @app_bundle_path_arm_FAT ||= File.expand_path(File.join(resources_dir, 'lipo', 'arm-FAT', 'Payload', 'CalSmoke-cal.app'))
  end

  def app_bundle_path_i386
    @app_bundle_path_i386 ||= File.expand_path(File.join(resources_dir, 'lipo', 'i386', 'CalSmoke.app'))
  end

  def app_bundle_path_x86_64
    @app_bundle_path_x86_64 ||= File.expand_path(File.join(resources_dir, 'lipo', 'x86_64', 'CalSmoke.app'))
  end

  def bundle_id
    @bundle_id = 'com.xamarin.CalSmoke-cal'
  end

  def launch_with_options(options, tries=self.launch_retries, &block)
    hash = nil
    Retriable.retriable({:tries => tries}) do
      hash = RunLoop.run(options)
    end

    begin
      if block_given?
        block.call(hash)
      end
    ensure
      # An attempt to suppress "assetsd crashes on Xcode 6.3", did not work.
      # Crash occurs after the app has launched.  Possibly the result of
      # resetting the simulator.
      # Terminate the app.
      # Open3.popen3('curl', *['http://localhost:37265/exit']) {}
      # sleep(1)
    end
    hash
  end

  def core_simulator_home_dir
    @core_simulator_home_dir = File.expand_path('~/Library/Developer/CoreSimulator')
  end

  def core_simulator_device_dir(sim_udid=nil)
    if sim_udid.nil?
      @core_simulator_device_dir = File.expand_path(File.join(core_simulator_home_dir, 'Devices'))
    else
      File.expand_path(File.join(core_simulator_device_dir, sim_udid))
    end
  end

  def core_simulator_device_containers_dir(sim_udid)
    File.expand_path(File.join(core_simulator_device_dir(sim_udid), 'Containers'))
  end

  def mock_core_simulator_device_data_dir(sdk)
    case sdk
      when :sdk8
        @mock_core_simulator_data_dir_sdk8 ||= lambda {
          File.expand_path(File.join(resources_dir, 'simctl', 'sdk8', 'data'))
        }.call
      when :sdk7
        @mock_core_simulator_data_dir_sdk7 ||= lambda {
          File.expand_path(File.join(resources_dir, 'simctl', 'sdk-less-than-8', 'data'))
        }.call
      else
        raise "Expected sdk '#{sdk}' to be on of #{[:sdk8, :sdk7]}"
    end
  end

  def random_simulator_device
    sim_control.simulators.shuffle.detect do |device|
      device.name[/Resizable/,0] == nil
    end
  end

  def with_developer_dir(developer_dir, &block)
    original_developer_dir = ENV['DEVELOPER_DIR']
    begin
      ENV.delete('DEVELOPER_DIR')
      ENV['DEVELOPER_DIR'] = developer_dir
      block.call
    ensure
      ENV['DEVELOPER_DIR'] = original_developer_dir
    end
  end

  def alt_xcode_install_paths
    @alt_xcode_install_paths ||= lambda {
      min_xcode_version = RunLoop::Version.new('6.3.2')
      Dir.glob('/Xcode/*/*.app/Contents/Developer').map do |path|
        xcode_version = path[VERSION_REGEX, 0]

        include = [RunLoop::Version.new(xcode_version) >= min_xcode_version,
                   RunLoop::Version.new(xcode_version) != current_xcode_version].all?

        if include
          path
        else
          nil
        end
      end
    }.call.compact
  end

  def alt_xcode_details_hash(skip_versions=[RunLoop::Version.new('6.0')])
    @alt_xcodes_gte_xc51_hash ||= lambda {
      active_xcode_path = RunLoop::Xcode.new.developer_dir
      with_developer_dir(active_xcode_path) do
        paths =  alt_xcode_install_paths
        paths.map do |path|
          ENV['DEVELOPER_DIR'] = path
          version = RunLoop::Xcode.new.version
          if path == active_xcode_path
            nil
          elsif skip_versions.include?(version)
            nil
          elsif version >= RunLoop::Version.new('5.1.1')
            {
                  :version => RunLoop::Xcode.new.version,
                  :path => path
            }
          else
            nil
          end
        end
      end
    }.call.compact
  end

  def plist_template
     @plist_template ||= File.expand_path(File.join(resources_dir, 'plist-buddy/com.example.plist'))
  end

  def plist_for_testing
    dir = Dir.mktmpdir
    path = File.join(dir, 'com.testing.plist')
    FileUtils.cp(plist_template, path)
    path
  end

  def plist_buddy_verbose
    @plist_verbose ||= {:verbose => true}
  end

  def accessibility_plist_hash
    @accessibility_plist_hash ||=
          {
                :access_enabled => 'AccessibilityEnabled',
                :app_access_enabled => 'ApplicationAccessibilityEnabled',
                :automation_enabled => 'AutomationEnabled',
                :inspector_showing => 'AXInspectorEnabled',
                :inspector_full_size => 'AXInspector.enabled',
                :inspector_frame => 'AXInspector.frame'
          }
  end

  def mocked_sim_support_dir
    @mocked_sim_support_dir ||= File.expand_path(File.join(resources_dir, 'enable-accessibility'))
  end

  def access_plist_for_sdk(sdk, enabled)
    base_dir = File.join(resources_dir, 'enable-accessibility', 'CoreSimulator')
    if sdk < RunLoop::Version.new('8.0')
      if enabled
        File.join(base_dir, 'access-enabled-iOS7.plist')
      else
        File.join(base_dir, 'access-not-enabled-iOS7.plist')
      end
    else
      if enabled
        File.join(base_dir, 'access-enabled-iOS8.plist')
      else
        File.join(base_dir, 'access-not-enabled-iOS8.plist')
      end
    end
  end

  def simulator_with_sdk_test(sdk_test, sim_control)
    sim_control.simulators.shuffle.detect do |device|
      [
            device.state == 'Shutdown',
            device.name != 'rspec-test-device',
            !device.name[/Resizable/,0],
            sdk_test.call(device)
      ].all?
    end
  end

  def plist_with_software_keyboard(enabled)
    base_dir = File.join(resources_dir, 'keyboard', 'CoreSimulator')
    if enabled
      File.join(base_dir, 'software-keyboard-enabled.plist')
    else
      File.join(base_dir, 'software-keyboard-not-enabled.plist')
    end
  end

  def ideviceinstaller_bin_path
    @ideviceinstaller_bin_path ||= `which ideviceinstaller`.chomp!
  end

  def ideviceinstaller_available?
    path = ideviceinstaller_bin_path
    path and File.exist? ideviceinstaller_bin_path
  end

  def ideviceinstaller(device_udid, cmd, opts={})
    default_opts = {:ipa => ipa_path,
                    :bundle_id => bundle_id}

    merged = default_opts.merge(opts)


    bin_path = ideviceinstaller_bin_path
    bundle_id = merged[:bundle_id]

    case cmd
      when :install
        ipa = merged[:ipa]
        Retriable.retriable do
          uninstall device_udid, bundle_id, bin_path
        end
        Retriable.retriable do
          install device_udid, ipa, bundle_id, bin_path
        end
      when :uninstall
        Retriable.retriable do
          uninstall device_udid, bundle_id, bin_path
        end
      else
        cmds = [:install, :uninstall]
        raise ArgumentError, "expected '#{cmd}' to be one of '#{cmds}'"
    end
  end

  def bundle_installed?(udid, bundle_id, installer)
    cmd = "#{installer} -u #{udid} -l"
    if ENV['DEBUG_UNIX_CALLS'] == '1'
      puts "\033[36mEXEC: #{cmd}\033[0m"
    end
    Open3.popen3(cmd) do  |_, stdout,  stderr, _|
      out = stdout.read.strip
      err = stderr.read.strip
      if ENV['DEBUG_UNIX_CALLS'] == '1'
        puts "#{cmd} => stdout: '#{out}' | stderr: '#{err}'"
      end
      out.strip.split(/\s/).include? bundle_id
    end
  end

  def install(udid, ipa, bundle_id, installer)
    if bundle_installed? udid, bundle_id, installer
      if ENV['DEBUG_UNIX_CALLS'] == '1'
        puts "\033[32mINFO: bundle '#{bundle_id}' is already installed\033[0m"
      end
      return true
    end
    cmd = "#{installer} -u #{udid} --install #{ipa}"
    if ENV['DEBUG_UNIX_CALLS'] == '1'
      puts "\033[36mEXEC: #{cmd}\033[0m"
    end
    Open3.popen3(cmd) do  |_, stdout,  stderr, _|
      out = stdout.read.strip
      err = stderr.read.strip
      if ENV['DEBUG_UNIX_CALLS'] == '1'
        puts "#{cmd} => stdout: '#{out}' | stderr: '#{err}'"
      end
    end
    unless bundle_installed?(udid, bundle_id, installer)
      raise "could not install '#{ipa}' on '#{udid}' with '#{bundle_id}'"
    end
    true
  end

  def uninstall(udid, bundle_id, installer)
    unless bundle_installed? udid, bundle_id, installer
      return true
    end
    cmd = "#{installer} -u #{udid} --uninstall #{bundle_id}"
    if ENV['DEBUG_UNIX_CALLS'] == '1'
      puts "\033[36mEXEC: #{cmd}\033[0m"
    end
    Open3.popen3(cmd) do  |_, stdout,  stderr, _|
      out = stdout.read.strip
      err = stderr.read.strip
      if ENV['DEBUG_UNIX_CALLS'] == '1'
        puts "#{cmd} => stdout: '#{out}' | stderr: '#{err}'"
      end
    end
    if bundle_installed?(udid, bundle_id, installer)
      raise "could not uninstall '#{bundle_id}' on '#{udid}'"
    end
    true
  end

  def path_to_fake_instruments
    @path_to_instruments_rb ||= File.join(resources_dir, 'fake-instruments.rb')
  end

  def fork_fake_instruments_process
    pid = Process.fork
    if pid.nil?
      exec("#{path_to_fake_instruments}")
    else
      @fake_instruments_pids ||= []
      @fake_instruments_pids << pid
      Process.detach(pid)
    end
    pid.to_i
  end

  def kill_fake_instruments_process
    return if @fake_instruments_pids.nil?
    @fake_instruments_pids.each do |pid|
      Process.kill('TERM', pid)
    end
    @fake_instruments_pids = []
  end

  def incompatible_xcode_ios_version(device_version, xcode_version)
    [(device_version >= RunLoop::Version.new('8.0') and xcode_version < RunLoop::Version.new('6.0')),
     (device_version >= RunLoop::Version.new('8.1') and xcode_version < RunLoop::Version.new('6.1')),
     (device_version >= RunLoop::Version.new('8.2') and xcode_version < RunLoop::Version.new('6.2')),
     (device_version >= RunLoop::Version.new('8.3') and xcode_version < RunLoop::Version.new('6.3')),
     (device_version >= RunLoop::Version.new('8.4') and xcode_version < RunLoop::Version.new('6.4')),
     (device_version >= RunLoop::Version.new('9.0') and xcode_version < RunLoop::Version.new('7.0')),
     (device_version >= RunLoop::Version.new('9.1') and xcode_version < RunLoop::Version.new('7.1'))].any?
  end

  def idevice_id_bin_path
    @idevice_id_bin_path ||= `which idevice_id`.chomp!
  end

  def idevice_id_available?
    path = idevice_id_bin_path
    path and File.exist? path
  end

  def physical_devices_for_testing(instruments = nil)

    if instruments.nil?
      instruments = self.instruments
    end

    # Xcode 6 + iOS 8 - devices on the same network, whether development or not,
    # appear when calling $ xcrun instruments -s devices. For the purposes of
    # testing, we will only try to connect to devices that are connected via
    # udid.
    devices = instruments.physical_devices
    if idevice_id_available?
      white_list = `#{idevice_id_bin_path} -l`.strip.split("\n")
      devices.select do | device |
        white_list.include?(device.udid) &&
              white_list.count(device.udid) == 1 &&
              !incompatible_xcode_ios_version(device.version, instruments.xcode.version)
      end
    else
      devices
    end
  end

  def launch_instruments_app(xcode = RunLoop::Xcode.new)
    dev_dir = xcode.developer_dir
    instruments_app = File.join(dev_dir, '..', 'Applications', 'Instruments.app')
    pid = Process.fork
    if pid.nil?
      exec "open #{instruments_app}"
    else
      Process.detach pid
      poll_until = Time.now + 5
      delay = 0.1
      while Time.now < poll_until
        ps_output = `ps x -o pid,comm | grep Instruments.app | grep -v grep`.strip
        break if ps_output[/Instruments\.app/, 0]
        sleep delay
      end
    end
  end

  def kill_instruments_app(instruments_obj = self.instruments)
    ps_output = `ps x -o pid,comm | grep Instruments.app | grep -v grep`.strip
    lines = ps_output.lines("\n").map { |line| line.strip }
    lines.each do |line|
      tokens = line.strip.split(' ').map { |token| token.strip }
      pid = tokens.fetch(0, nil)
      process_description = tokens[1..-1].join(' ')
      if process_description[/Instruments\.app/, 0]
        Process.kill('TERM', pid.to_i)
        RunLoop::ProcessTerminator.new(pid, 'TERM', 'Instruments.app').kill_process
      end
    end
  end

  def infinite_lldb_script
    @infinite_lldb_script ||= File.expand_path(File.join(resources_dir, 'infinite.lldb'))
  end

  def spawn_lldb_process
    pid = Process.fork
    if pid.nil?
      args = ['lldb', '--no-lldbinit', '--source', infinite_lldb_script]
      redirect_io = {:out => '/dev/null', :err => '/dev/null'}
      exec('xcrun', *args, redirect_io)
    else
      @lldb_process_pids ||= []
      @lldb_process_pids << pid
      Process.detach(pid)
    end
    pid.to_i
  end

  def kill_owned_lldb_processes
    return if @lldb_process_pids.nil?
    begin
      @lldb_process_pids.each do |pid|
        RunLoop::ProcessTerminator.new(pid, 'KILL', 'lldb').kill_process
      end
    ensure
      @lldb_process_pids = []
    end
  end

  def kill_lldb_processes
    kill_owned_lldb_processes
    Open3.popen3('xcrun', *['killall', '-9', 'lldb']) do |_, _, _, _|
    end
  end

end
