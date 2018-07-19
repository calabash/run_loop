
module RunLoop
  module CLI

    require 'thor'
    class Simctl < Thor

      require 'run_loop'
      require 'run_loop/cli/errors'

      attr_reader :simctl

      desc 'tail', 'Tail the log file of the booted simulator'
      def tail
        tail_simulator_logs
      end

      no_commands do
        def tail_simulator_logs
          paths = simctl.simulators.map do |simulator|
            log_file_path = simulator.simulator_log_file_path
            if log_file_path && File.exist?(log_file_path)
              log_file_path
            else
              nil
            end
          end.compact

          args = ["-n", "1000", "-F"] + paths
          exec("tail", *args)
        end
      end

      desc 'booted', 'Prints details about the booted simulator'
      def booted
        device = booted_device
        if device.nil?
          version = xcode.version
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

        manage_processes

        if device
          RunLoop::Environment.with_debugging(debug) do
            RunLoop::CoreSimulator.erase(device)
            launch_simulator(device, xcode)
          end
        else
          RunLoop::Environment.with_debugging(debug) do
            erase_and_launch_each_simulator
          end
        end

      end

      no_commands do
        def erase_and_launch_each_simulator
          simctl.simulators.each do |simulator|
            RunLoop::CoreSimulator.erase(simulator)
            launch_simulator(simulator, xcode)
          end
        end

        def launch_simulator(simulator, xcode)
          core_sim = RunLoop::CoreSimulator.new(simulator, nil,
                                                {:xcode => xcode})
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
          RunLoop::CoreSimulator.terminate_core_simulator_processes
        ensure
          ENV['DEBUG'] = original_value if debug
        end
      end

      no_commands do
        def simctl
          @simctl ||= RunLoop::Simctl.new
        end

        def xcode
          @xcode ||= RunLoop::Xcode.new
        end

        def xcrun
          @xcrun ||= RunLoop::Xcrun.new
        end

        def booted_device
          simctl.simulators.detect(nil) do |device|
            device.state == 'Booted'
          end
        end
      end

      desc 'install --app [OPTIONS]', 'Installs an app on a device.'

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

      method_option 'debug',
                    :desc => 'Enable debug logging.',
                    :aliases => '-v',
                    :required => false,
                    :default => false,
                    :type => :boolean

      method_option 'reset-app-sandbox',
                    :desc => 'If the app is already installed, erase the app data.',
                    :aliases => '-r',
                    :default => false,
                    :type => :boolean

      method_option 'force',
                    :desc => 'Force a re-install the existing app. Deprecated 1.5.6.',
                    :aliases => '-f',
                    :required => false,
                    :default => false,
                    :type => :boolean

      def install
        debug = options[:debug]

        device = expect_device(options)
        app = expect_app(options, device)

        core_sim = RunLoop::CoreSimulator.new(device, app)

        RunLoop::Environment.with_debugging(debug) do
          if options['reset-app-sandbox']

            if core_sim.app_is_installed?
              RunLoop.log_debug('Resetting the app sandbox')
              core_sim.uninstall_app_and_sandbox
            else
              RunLoop.log_debug('App is not installed; skipping sandbox reset')
            end
          end
          core_sim.install
        end
      end

      desc "erase <simulator>", "Erases the simulator"

      method_option 'debug',
                    :desc => 'Enable debug logging.',
                    :aliases => '-v',
                    :required => false,
                    :default => false,
                    :type => :boolean

      def erase(simulator=nil)

        debug = options[:debug]

        RunLoop::Environment.with_debugging(debug) do
          if !simulator
            identifier = RunLoop::Core.default_simulator(xcode)
          else
            identifier = simulator
          end

          options = {simctl: simctl, xcode: xcode}
          device = RunLoop::Device.device_with_identifier(identifier, options)

          RunLoop::CoreSimulator.erase(device, options)
        end
      end

      desc "launch <simulator>", "Launches the simulator"

      method_option 'debug',
                    :desc => 'Enable debug logging.',
                    :aliases => '-v',
                    :required => false,
                    :default => false,
                    :type => :boolean

      def launch(simulator=nil)
        debug = options[:debug]

        RunLoop::Environment.with_debugging(debug) do
          if !simulator
            identifier = RunLoop::Core.default_simulator(xcode)
          else
            identifier = simulator
          end

          options = {simctl: simctl, xcode: xcode}
          device = RunLoop::Device.device_with_identifier(identifier, options)

          core_sim = RunLoop::CoreSimulator.new(device, nil)
          core_sim.launch_simulator
        end
      end

      no_commands do
        def expect_device(options)
          device_from_options = options[:device]
          simulators = simctl.simulators
          if device_from_options.nil?
            default_name = RunLoop::Core.default_simulator
            device = simulators.find do |sim|
              sim.instruments_identifier == default_name
            end

            if device.nil?
              raise RunLoop::CLI::ValidationError,
                    "Could not find a simulator with name that matches '#{device_from_options}'"
            end
          else
            device = simulators.find do |sim|
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
