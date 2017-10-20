require 'thor'
require 'run_loop'
require 'run_loop/cli/errors'

module RunLoop
  module CLI
    class Instruments < Thor

      attr_accessor :signal

      desc 'quit', 'Send a kill signal to all instruments processes.'

      method_option 'signal',
                    :desc => 'The kill signal to send.',
                    :aliases => '-s',
                    :required => false,
                    :default => 'TERM',
                    :type => :string

      method_option 'debug',
                    :desc => 'Enable debug logging.',
                    :aliases => '-v',
                    :required => false,
                    :default => false,
                    :type => :boolean


      def quit
        if RunLoop::Xcode.new.version_gte_8?
          puts "instruments quit with Xcode 8 is not supported"
          exit 1
        end

        signal = options[:signal]
        ENV['DEBUG'] = '1' if options[:debug]
        instruments = RunLoop::Instruments.new
        instruments.instruments_pids.each do |pid|
          terminator = RunLoop::ProcessTerminator.new(pid, signal, 'instruments')
          unless terminator.kill_process
            terminator = RunLoop::ProcessTerminator.new(pid, 'KILL', 'instruments')
            terminator.kill_process
          end
        end
      end


      desc 'launch [--app | [--ipa | --bundle-id]] [OPTIONS]', 'Launch an app with instruments.'

# This is the description we want, but Thor doesn't handle newlines well(?).
# long_desc <<EOF
# # Launch App.app on a simulator.
# $ be run-loop instruments launch --app /path/to/App.app
#
# # Launch App.ipa on a device; bundle id will be extracted.
# $ be run-loop instruments launch --ipa /path/to/App.ipa
#
# # Launch the app with bundle id on a device.
# $ be run-loop instruments launch --bundle-id com.example.MyApp-cal
#
# You can pass arguments to application as a comma separated list.
# --args -NSShowNonLocalizedStrings,YES,-AppleLanguages,(de)
# --args -com.apple.CoreData.SQLDebug,3'
# EOF

      method_option 'device',
                    :desc => 'The device UDID or simulator identifier.',
                    :aliases => '-d',
                    :required => false,
                    :type => :string

      method_option 'app',
                    :desc => 'Path to a .app bundle to launch on simulator.',
                    :aliases => '-a',
                    :required => false,
                    :type => :string

      method_option 'bundle-id',
                    :desc => 'Bundle id of app to launch on device.',
                    :aliases => '-b',
                    :required => false,
                    :type => :string

      method_option 'template',
                    :desc => 'Path to an automation template.',
                    :aliases => '-t',
                    :required => false,
                    :type => :string

      method_option 'args',
                    :desc => 'Arguments to pass to the app.',
                    :required => false,
                    :type => :string

      method_option 'debug',
                    :desc => 'Enable debug logging.',
                    :aliases => '-v',
                    :required => false,
                    :default => false,
                    :type => :boolean

      def launch
        if RunLoop::Xcode.new.version_gte_8?
          puts "Launching applications with Xcode 8 is not supported"
          exit 1
        end

        debug = options[:debug]
        original_value = ENV['DEBUG']

        ENV['DEBUG'] = '1' if debug

        begin
          launch_options = {
                :args => parse_app_launch_args(options),
                :udid => detect_device_udid_from_options(options),
                :app => detect_bundle_id_or_bundle_path(options)
          }
          run_loop = RunLoop.run(launch_options)
          puts JSON.generate(run_loop)
        ensure
          ENV['DEBUG'] = original_value if debug
        end
      end

      no_commands do
        def parse_app_launch_args(options)
          args = options[:args]
          if args.nil?
            []
          else
            args.split(',')
          end
        end

        def detect_bundle_id_or_bundle_path(options)
          app = options[:app]
          ipa = options[:ipa]
          bundle_id = options[:bundle_id]

          if app && ipa
            raise RunLoop::CLI::ValidationError,
                  "--app #{app} and --ipa #{ipa} are mutually exclusive arguments.  Pass one or the other, not both."
          end

          if app && bundle_id
            raise RunLoop::CLI::ValidationError,
                  "--app #{app} and --bundle-id #{bundle_id} are mutually exclusive arguments. Pass one or the other, not both."
          end

          if ipa && bundle_id
            raise RunLoop::CLI::ValidationError,
                  "--ipa #{ipa} and --bundle-id #{bundle_id} are mutually exclusive arguments. Pass one or the other, not both."
          end
          app || bundle_id
        end

        def detect_device_udid_from_options(options)
          device = options[:device]
          app = options[:app]
          if app && !device
            RunLoop::Core.default_simulator
          else
            device
          end
        end
      end
    end
  end
end
