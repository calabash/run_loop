require 'thor'

module RunLoop
  class CLI < Thor
    include Thor::Actions

    def self.source_root
      #File.join( File.dirname(__FILE__), '..','..','frank-skeleton' )
    end


    desc "example", "example desc"
    long_desc "Long desc"
    def example
      say "example"
    end

  end
end

