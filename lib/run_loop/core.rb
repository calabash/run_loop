module RunLoop
  module Core
    def self.scripts_path
      File.expand_path(File.join(File.dirname(__FILE__), '..', '..','scripts'))
    end


  end
end