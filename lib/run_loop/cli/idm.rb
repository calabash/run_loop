
module RunLoop
  module CLI

    require 'thor'
    class IDM < Thor

      require "run_loop"
      require "run_loop/cli/errors"
      require "run_loop/shell"
      include RunLoop::Shell

      require "run_loop/regex"

      desc "install app [OPTIONS]", "Installs an app on a device."

      method_option "device",
                    :desc => 'The simulator UDID or name.',
                    :aliases => "-d",
                    :required => false,
                    :type => :string

      method_option "debug",
                    :desc => "Enable debug logging.",
                    :aliases => "-v",
                    :required => false,
                    :default => false,
                    :type => :boolean

      method_option "force",
                    :desc => "Force a re-install the existing app",
                    :aliases => "-f",
                    :required => false,
                    :default => false,
                    :type => :boolean

      def install(app)
        extension =  File.extname(app)
        if extension == ".app"
          app_instance = RunLoop::App.new(app)
        else
          app_instance = RunLoop::Ipa.new(app)
        end

        xcode = RunLoop::Xcode.new
        simctl = RunLoop::Simctl.new
        instruments = RunLoop::Instruments.new

        detect_options = {}

        device = options[:device]
        if !device
          detect_options[:device] = "device"
        else
          detect_options[:device] = device
        end

        device = RunLoop::Device.detect_device(detect_options, xcode,
                                               simctl, instruments)

        idm = RunLoop::PhysicalDevice::IOSDeviceManager.new(device)

        if options[:force]
          idm.install_app(app_instance)
        else
          idm.ensure_newest_installed(app_instance)
        end
      end
    end
  end
end
