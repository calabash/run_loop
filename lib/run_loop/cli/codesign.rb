require "thor"
require "run_loop"
require "run_loop/cli/errors"

module RunLoop
  module CLI
    class Codesign < Thor

      desc "info ARTIFACT", "Print codesign information about ARTIFACT (ipa, app, or library)"

      def info(app_or_ipa)
        extension = File.extname(app_or_ipa)

        if extension == ".app"
          puts RunLoop::App.new(app_or_ipa).codesign_info
        elsif extension == ".ipa"
          puts RunLoop::Ipa.new(app_or_ipa).codesign_info
        else
          puts RunLoop::Codesign.info(app_or_ipa)
        end
      end
    end
  end
end
