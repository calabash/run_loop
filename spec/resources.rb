class Resources

  attr_reader :app_bundle_path

  def initialize
    @app_bundle_path = File.expand_path(File.join(__FILE__, '..', 'resources', 'chou-cal.app'))
  end

end

