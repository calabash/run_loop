require 'thor'
require 'run_loop'
require 'run_loop/cli/errors'

module RunLoop
  module CLI
    class Simctl < Thor

      attr_reader :sim_control

      desc 'tail', 'Tail the log file of the booted simulator'
      def tail
        tail_booted
      end

      no_commands do
        def tail_booted
          device = booted_device
          if device.nil?
            version = Xcode.new.version
            puts "No simulator for active Xcode (version #{version}) is booted."
          else
            log_file = device.simulator_log_file_path
            exec('tail', *['-F', log_file])
          end
        end
      end

      desc 'booted', 'Prints details about the booted simulator'
      def booted
        device = booted_device
        if device.nil?
          version = Xcode.new.version
          puts "No simulator for active Xcode (version #{version}) is booted."
        else
          puts device
        end
      end

      desc 'doctor', 'EXPERIMENTAL: Prepare the CoreSimulator environment for testing'

      method_option 'debug',
                    :desc => 'Enable debug logging.',
                    :aliases => '-v',
                    :required => false,
                    :default => false,
                    :type => :boolean

      method_option 'device',
                    :desc => 'The simulator UDID or name.',
                    :aliases => '-d',
                    :required => false,
                    :type => :string

      def doctor
        debug = options[:debug]
        device = options[:device]

        if device
          device = expect_device(options)
          if debug
            RunLoop::Environment.with_debugging do
              launch_simulator(device)
            end
          else
            launch_simulator(device)
          end
        else
          if debug
            RunLoop::Environment.with_debugging do
              launch_each_simulator
            end
          else
            launch_each_simulator
          end
        end
      end

      no_commands do
        def launch_each_simulator
          sim_control = RunLoop::SimControl.new
          sim_control.simulators.each do |simulator|
            launch_simulator(simulator, sim_control)
          end
        end

        def launch_simulator(simulator, sim_control=RunLoop::SimControl.new)
          core_sim = RunLoop::LifeCycle::CoreSimulator.new(nil,
                                                           simulator,
                                                           sim_control)
          core_sim.launch_simulator
        end
      end

      desc 'manage-processes', 'Manage CoreSimulator processes by quiting stale processes'

      method_option 'debug',
                    :desc => 'Enable debug logging.',
                    :aliases => '-v',
                    :required => false,
                    :default => false,
                    :type => :boolean

      def manage_processes
        debug = options[:debug]
        original_value = ENV['DEBUG']

        ENV['DEBUG'] = '1' if debug

        begin
          RunLoop::SimControl.terminate_all_sims
          RunLoop::LifeCycle::Simulator.new.terminate_core_simulator_processes
        ensure
          ENV['DEBUG'] = original_value if debug
        end
      end

      no_commands do
        def sim_control
          @sim_control ||= RunLoop::SimControl.new
        end

        def booted_device
          sim_control.simulators.detect(nil) do |device|
            device.state == 'Booted'
          end
        end
      end

      desc 'install --app [OPTIONS]', 'Installs an app on a device'

      method_option 'app',
                    :desc => 'Path to a .app bundle to launch on simulator.',
                    :aliases => '-a',
                    :required => true,
                    :type => :string

      method_option 'device',
                    :desc => 'The simulator UDID or name.',
                    :aliases => '-d',
                    :required => false,
                    :type => :string

      method_option 'force',
                    :desc => 'Force a re-install the existing app.',
                    :aliases => '-f',
                    :required => false,
                    :default => false,
                    :type => :boolean

      method_option 'debug',
                    :desc => 'Enable debug logging.',
                    :aliases => '-v',
                    :required => false,
                    :default => false,
                    :type => :boolean

      def install
        debug = options[:debug]

        if debug
          ENV['DEBUG'] = '1'
        end

        debug_logging = RunLoop::Environment.debug?

        device = expect_device(options)
        app = expect_app(options, device)

        bridge = RunLoop::Simctl::Bridge.new(device, app.path)

        xcode = bridge.sim_control.xcode
        if xcode.version >= RunLoop::Version.new('7.0')
          puts "ERROR: Xcode #{xcode.version.to_s} detected."
          puts "ERROR: Apple's simctl install/uninstall is broken for this version of Xcode."
          puts "ERROR: See the following links for details:"
          puts "ERROR: https://forums.developer.apple.com/message/51922"
          puts "ERROR: https://github.com/calabash/run_loop/issues/235"
          puts "ERROR: exiting 1"
          exit 1
        end

        force_reinstall = options[:force]

        before = Time.now

        if bridge.app_is_installed?
          if debug_logging
            puts "App with bundle id '#{app.bundle_identifier}' is already installed."
          end

          if force_reinstall
            if debug_logging
              puts 'Will force a re-install.'
            end
            bridge.uninstall
            bridge.install
          else
            new_digest = RunLoop::Directory.directory_digest(app.path)
            if debug_logging
              puts "      New app has SHA: '#{new_digest}'."
            end
            installed_app_bundle = bridge.fetch_app_dir
            old_digest = RunLoop::Directory.directory_digest(installed_app_bundle)
            if debug_logging
              puts "Installed app has SHA: '#{old_digest}'."
            end
            if new_digest != old_digest
              if debug_logging
                puts "Will re-install '#{app.bundle_identifier}' because the SHAs don't match."
              end
              bridge.uninstall
              bridge.install
            else
              if debug_logging
                puts "Will not re-install '#{app.bundle_identifier}' because the SHAs match."
              end
            end
          end
        else
          bridge.install
        end

        if debug_logging
          "Launching took #{Time.now-before} seconds"
          puts "Installed '#{app.bundle_identifier}' on #{device} in #{Time.now-before} seconds."
        end
      end

      no_commands do
        def expect_device(options)
          device_from_options = options[:device]
          simulators = sim_control.simulators
          if device_from_options.nil?
            default_name = RunLoop::Core.default_simulator
            device = simulators.detect do |sim|
              sim.instruments_identifier == default_name
            end

            if device.nil?
              raise RunLoop::CLI::ValidationError,
                    "Could not find a simulator with name that matches '#{device_from_options}'"
            end
          else
            device = simulators.detect do |sim|
              sim.udid == device_from_options ||
                    sim.instruments_identifier == device_from_options
            end

            if device.nil?
              raise RunLoop::CLI::ValidationError,
                    "Could not find a simulator with name or UDID that matches '#{device_from_options}'"
            end
          end
          device
        end

        def expect_app(options, device_obj)
          app_bundle_path = options[:app]
          unless File.exist?(app_bundle_path)
            raise RunLoop::CLI::ValidationError, "Expected '#{app_bundle_path}' to exist."
          end

          unless File.directory?(app_bundle_path)
            raise RunLoop::CLI::ValidationError,
                  "Expected '#{app_bundle_path}' to be a directory."
          end

          unless File.extname(app_bundle_path) == '.app'
            raise RunLoop::CLI::ValidationError,
                  "Expected '#{app_bundle_path}' to end in .app."
          end

          app = RunLoop::App.new(app_bundle_path)

          begin
            app.bundle_identifier
            app.executable_name
          rescue RuntimeError => e
            raise RunLoop::CLI::ValidationError, e.message
          end

          lipo = RunLoop::Lipo.new(app.path)
          begin
            lipo.expect_compatible_arch(device_obj)
          rescue RunLoop::IncompatibleArchitecture => e
            raise RunLoop::CLI::ValidationError, e.message
          end

          app
        end
      end
    end
  end
end
