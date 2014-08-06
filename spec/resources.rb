class Resources

  def self.shared
    @resources ||= Resources.new
  end

  def travis_ci?
    @travis_ci ||= ENV['TRAVIS'].to_s == 'true'
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

  def app_bundle_path
    @app_bundle_path ||= File.expand_path(File.join(resources_dir, 'chou-cal.app'))
  end

  def ipa_path
    @ipa_path ||= File.expand_path(File.join(resources_dir, 'chou-cal.ipa'))
  end

  def bundle_id
    @bundle_id = 'com.xamarin.chou-cal'
  end

  def alt_xcode_install_paths(version=nil)
    if version
      Dir.glob('/Xcode/*/*.app/Contents/Developer').select { |elm| elm =~ /\/Xcode\/(#{version})/ }
    else
      @alt_xcode_install_paths ||= Dir.glob('/Xcode/*/*.app/Contents/Developer').select { |elm| elm =~ /\/Xcode\/[^4]/ }
    end
  end

  def alt_xcodes_gte_xc51_hash
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
          elsif version >= RunLoop::Version.new('5.1')
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
    File.exist? ideviceinstaller_bin_path
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
      puts "\033[32mINFO: bundle '#{bundle_id}' is already installed\033[0m"
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
end
