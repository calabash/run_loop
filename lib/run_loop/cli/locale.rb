require "thor"
require "run_loop"
require "run_loop/cli/errors"

module RunLoop
  module CLI
    class Locale < Thor

      desc "print-alert-regexes", "Print privacy alert regular expressions"

      def print_alert_regexes
        dir = File.expand_path(File.dirname(__FILE__))
        scripts_dir = File.join(dir, "..", "..", "..", "scripts")
        on_alert = File.join(scripts_dir, "lib", "on_alert.js")

        lines = []
        File.read(on_alert).force_encoding("UTF-8").split($-0).each do |line|
          if line[/\[\".+\", \/.+\/\]/, 0]
            line.chomp!
            if line[-1,1] == ","
              line = line[0, line.length - 1]
            end
            lines << line
          end
        end

        puts lines.join(",#{$-0}")
      end
    end
  end
end
