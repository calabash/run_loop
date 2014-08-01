class Resources

  def app_bundle_path
    @app_bundle_path ||= File.expand_path(File.join(__FILE__, '..', 'resources', 'chou-cal.app'))
  end

  def alt_xcode_install_paths(version=nil)
    unless version
      @alt_xcode_install_paths ||= Dir.glob('/Xcode/*/*.app/Contents/Developer').select { |elm| elm =~ /\/Xcode\/[^4]/ }
    else
      Dir.glob('/Xcode/*/*.app/Contents/Developer').select { |elm| elm =~ /\/Xcode\/(#{version})/ }
    end
  end
end

