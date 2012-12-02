require 'fileutils'
require 'tmpdir'

module RunLoop
  module Core

    SCRIPTS_PATH = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'scripts'))
    SCRIPTS = {
        :dismiss => "run_dismiss_location.js"
    }

    def self.scripts_path
      SCRIPTS_PATH
    end

    def self.script_for_key(key)
      if SCRIPTS[key].nil?
        return nil
      end
      File.join(scripts_path, SCRIPTS[key])
    end

    def self.run_with_options(options)
      template = automation_template
      instruments_path = File.join(scripts_path,"unix_instruments")
      results_dir = options[:results_dir] || Dir.mktmpdir("run_loop")
      results_dir_trace = File.join(results_dir,"trace")
      FileUtils.mkdir_p(results_dir_trace)

      bundle_dir_or_bundle_id = options[:app] || ENV['APP_BUNDLE_PATH']

      unless bundle_dir_or_bundle_id
        raise "key :app or environment variable APP_BUNDLE_PATH must be specified as path to app bundle (simulator) or bundle id (device)"
      end

      cmd = [
        instruments_path,
        "-D", results_dir_trace,
        "-t", template,
        bundle_dir_or_bundle_id,
        "-e", "UIARESULTSPATH", results_dir,
        "-e", "UIASCRIPT", options[:script],
        *(options[:instruments_args] || [])
      ]

      pid = fork do
        log_header("Starting App: #{bundle_dir_or_bundle_id}")
        cmd_str = cmd.join(" ")
        if ENV['DEBUG']
          log(cmd_str)
        end
        exec(cmd_str)
      end

      Process.detach(pid)

      pid
    end

    def self.automation_template
      xcode_path = `xcode-select -print-path`.chomp
      automation_bundle = File.expand_path(File.join(xcode_path, "..", "Applications", "Instruments.app", "Contents", "PlugIns", "AutomationInstrument.bundle"))
      if not File.exist? automation_bundle
        automation_bundle= File.expand_path(File.join(xcode_path, "Platforms", "iPhoneOS.platform", "Developer", "Library", "Instruments", "PlugIns", "AutomationInstrument.bundle"))
        raise "Unable to find AutomationInstrument.bundle" if not File.exist? automation_bundle
      end
      File.join(automation_bundle, "Contents", "Resources", "Automation.tracetemplate")
    end

    def self.log(message)
      puts "#{Time.now } #{message}"
      $stdout.flush
    end

    def self.log_header(message)
      puts "\n\e[#{35}m### #{message} ###\e[0m"
      $stdout.flush
    end

  end

  def self.run(options={})
    script = validate_script(options)
    options[:script] = script

    Core.run_with_options(options)
  end

  def self.validate_script(options)
    script = options[:script]
    if script
      if script.is_a?(Symbol)
        script = Core.script_for_key(script)
        unless script
          raise "Unknown script for symbol: #{options[:script]}. Options: #{Core::SCRIPTS.keys.join(', ')}"
        end
      elsif script.is_a?(String)
        unless File.exist?(script)
          raise "File does not exist: #{script}"
        end
      else
        raise "Unknown type for :script key: #{options[:script].class}"
      end
    else
      script = Core.script_for_key(:dismiss)
    end
    script
  end

end