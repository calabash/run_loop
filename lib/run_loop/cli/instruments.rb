require 'thor'
require 'run_loop'

module RunLoop
  module CLI
    class Instruments < Thor

      attr_accessor :signal

      desc 'instruments quit', 'Send a kill signal to all instruments processes.'

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


      desc 'instruments launch [--app | [--ipa | --bundle-id]] [OPTIONS]', 'Launch an app with instruments.'

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
                    :desc => 'Path to a .app bundle.',
                    :aliases => '-a',
                    :required => false,
                    :type => :string

      method_option 'ipa',
                    :desc => 'Path to an .ipa bundle.',
                    :aliases => '-i',
                    :required => false,
                    :type => :string

      method_option 'bundle-id',
                    :desc => 'Path to an .ipa bundle.',
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

      end

      no_commands{
        def validate_launch_args(options)

        end

        def validate_app_ipa_or_bundle_id(options)

        end

        def validate_args(options)

        end
      }
    end
  end
end
