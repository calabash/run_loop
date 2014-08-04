class Resources

  def self.shared
    @resources ||= Resources.new
  end

  def resources_dir
    @resources_dir = File.expand_path(File.join(File.dirname(__FILE__),  'resources'))
  end

  def app_bundle_path
    @app_bundle_path ||= File.expand_path(File.join(resources_dir, 'chou-cal.app'))
  end

  def alt_xcode_install_paths(version=nil)
    if version
      Dir.glob('/Xcode/*/*.app/Contents/Developer').select { |elm| elm =~ /\/Xcode\/(#{version})/ }
    else
      @alt_xcode_install_paths ||= Dir.glob('/Xcode/*/*.app/Contents/Developer').select { |elm| elm =~ /\/Xcode\/[^4]/ }
    end
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

end

