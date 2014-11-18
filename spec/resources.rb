require 'singleton'

class Resources
  include Singleton

  attr_accessor :fake_instruments_pids

  def self.shared
    Resources.instance
  end

  def travis_ci?
    @travis_ci ||= ENV['TRAVIS'].to_s == 'true'
  end

  def launch_retries
    travis_ci? ? 8 : 2
  end

  def current_xcode_version
    @current_xcode_version ||= lambda {
      ENV.delete('DEVELOPER_DIR')
      RunLoop::XCTools.new.xcode_version
    }.call
  end

  def resources_dir
    @resources_dir = File.expand_path(File.join(File.dirname(__FILE__),  'resources'))
  end

  def cal_app_bundle_path
    @cal_app_bundle_path ||= File.expand_path(File.join(resources_dir, 'chou-cal.app'))
  end

  def app_bundle_path
    @app_bundle_path ||= File.expand_path(File.join(resources_dir, 'chou.app'))
  end

  def ipa_path
    @ipa_path ||= File.expand_path(File.join(resources_dir, 'chou-cal.ipa'))
  end

  def sim_dylib_path
    @sim_dylib_path ||= File.expand_path(File.join(resources_dir, 'dylibs', 'libCalabashDynSim.dylib'))
  end

  def multi_arch_app_bundle_path
    @multi_arch_app_bundle_path ||= File.expand_path(File.join(resources_dir, 'lipo', 'Payload', 'chou-cal.app'))
  end

  def bundle_id
    @bundle_id = 'com.xamarin.chou-cal'
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

  def alt_xcode_install_paths
    @alt_xcode_install_paths ||= lambda {
      min_xcode_version = RunLoop::Version.new('5.1.1')
      Dir.glob('/Xcode/*/*.app/Contents/Developer').map do |path|
        xcode_version = path[/(\d\.\d(\.\d)?)/, 0]
        if RunLoop::Version.new(xcode_version) >= min_xcode_version
          path
        else
          nil
        end
      end
    }.call.compact
  end

  def alt_xcode_details_hash(skip_versions=[RunLoop::Version.new('6.0')])
    @alt_xcodes_gte_xc51_hash ||= lambda {
      ENV.delete('DEVELOPER_DIR')
      xcode_select_path = RunLoop::XCTools.new.xcode_developer_dir
      paths =  alt_xcode_install_paths
      paths.map do |path|
        begin
          ENV['DEVELOPER_DIR'] = path
          version = RunLoop::XCTools.new.xcode_version
          if path == xcode_select_path
            nil
          elsif skip_versions.include?(version)
            nil
          elsif version >= RunLoop::Version.new('5.1.1')
            {
                  :version => RunLoop::XCTools.new.xcode_version,
                  :path => path
            }
          else
            nil
          end
        ensure
          ENV.delete('DEVELOPER_DIR')
        end
      end
    }.call.compact
  end

  def plist_template
     @plist_template ||= File.expand_path(File.join(resources_dir, 'plist-buddy/com.example.plist'))
  end

  def plist_for_testing
    @plist_for_testing ||= File.expand_path(File.join(resources_dir, 'plist-buddy/com.testing.plist'))
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
     (device_version >= RunLoop::Version.new('8.1') and xcode_version < RunLoop::Version.new('6.1'))].any?
  end

  def idevice_id_bin_path
    @idevice_id_bin_path ||= `which idevice_id`.chomp!
  end

  def idevice_id_available?
    path = idevice_id_bin_path
    path and File.exist? path
  end

  def physical_devices_for_testing(xcode_tools)
    # Xcode 6 + iOS 8 - devices on the same network, whether development or not,
    # appear when calling $ xcrun instruments -s devices. For the purposes of
    # testing, we will only try to connect to devices that are connected via
    # udid.
    @physical_devices_for_testing ||= lambda {
      devices = xcode_tools.instruments(:devices)
      if idevice_id_available?
        white_list = `#{idevice_id_bin_path} -l`.strip.split("\n")
        devices.select { | device | white_list.include?(device.udid) }
      else
        devices
      end
    }.call
  end

  def launch_instruments_app(xcode_tools = RunLoop::XCTools.new)
    dev_dir = xcode_tools.xcode_developer_dir
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

  def kill_instruments_app(instruments_obj = RunLoop::Instruments.new)
    ps_output = `ps x -o pid,comm | grep Instruments.app | grep -v grep`.strip
    lines = ps_output.lines("\n").map { |line| line.strip }
    lines.each do |line|
      tokens = line.strip.split(' ').map { |token| token.strip }
      pid = tokens.fetch(0, nil)
      process_description = tokens[1..-1].join(' ')
      if process_description[/Instruments\.app/, 0]
        Process.kill('TERM', pid.to_i)
        instruments_obj.instance_eval {  wait_for_process_to_terminate pid.to_i }
      end
    end
  end
end
