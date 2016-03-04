require "thor"
require "run_loop"
require "run_loop/cli/errors"

module RunLoop
  module CLI
    class TCC < Thor

      desc "services", "Print known services"

      def services
        RunLoop::TCC::PRIVACY_SERVICES.each do |key, _|
          puts key
        end
      end

      desc "open", "Open the TCC.db of a device in an editor EXPERIMENTAL"

      method_option "device",
        :desc => "Device name or identifier.",
        :aliases => "-d",
        :required => true,
        :type => :string

      def open
        device = expect_device(options)

        tcc_db = device.simulator_tcc_db

        return false if tcc_db.nil?

        args = ['open', tcc_db]

        pid = Process.spawn(*args)
        Process.detach(pid)
        pid
      end

      desc "allow", "Prevent a Privacy Alert from appearing (Sim only)"

      method_option "device",
        :desc => "Device name or identifier. If undefined, operation will be on all devices",
        :aliases => "-d",
        :required => false,
        :type => :string

      method_option "app",
        :desc => "App to allow service on",
        :aliases => "-a",
        :required => true,
        :type => :string

      method_option "service",
        :desc => "Service to allow.  If undefined, all known services will be allowed",
        :aliases => "-s",
        :required => false,
        :type => :string

      method_option 'debug',
        :desc => 'Enable debug logging.',
        :aliases => '-v',
        :required => false,
        :default => false,
        :type => :boolean

      def allow
        debug = options[:debug]

        device = options[:device]
        if device
          devices = [expect_device(options)]
        else
          devices = sim_control.simulators
        end

        service = options[:service]

        if service
          services = [service]
        else
         services = RunLoop::TCC::PRIVACY_SERVICES.map do |key, _|
          key
         end
        end

        app = RunLoop::App.new(options[:app])

        RunLoop::Environment.with_debugging(debug) do
          devices.each do |_device|
            tcc = RunLoop::TCC.new(_device, app)
            services.each do |_service|
              tcc.allow_service(_service)
            end
          end
        end
        true
      end

      no_commands do
        def expect_device(options)
          device_from_options = options[:device]
          simulators = sim_control.simulators
          if device_from_options.nil?
            default_name = RunLoop::Core.default_simulator
            device = simulators.find do |sim|
              sim.instruments_identifier(xcode) == default_name
            end

            if device.nil?
              raise RunLoop::CLI::ValidationError,
                    "Could not find a simulator with name that matches '#{device_from_options}'"
            end
          else
            device = simulators.find do |sim|
              sim.udid == device_from_options ||
                    sim.instruments_identifier(xcode) == device_from_options
            end

            if device.nil?
              raise RunLoop::CLI::ValidationError,
                    "Could not find a simulator with name or UDID that matches '#{device_from_options}'"
            end
          end
          device
        end

        def sim_control
          @sim_control ||= RunLoop::SimControl.new
        end

        def xcode
          @xcode ||= RunLoop::Xcode.new
        end
      end

    end
  end
end

