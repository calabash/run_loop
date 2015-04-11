module RunLoop::Simctl

  class SimctlError < StandardError

  end

  # @!visibility private
  # This is not a public API.  You have been warned.
  #
  # TODO Rename this class.
  # TODO Some code is duplicated from sim_control.rb
  # TODO Uninstall
  # TODO Reinstall if checksum does not match.
  # TODO Analyze terminate_core_simulator_processes
  class Bridge

    attr_reader :device
    attr_reader :app
    attr_reader :sim_control

    def initialize(device, app_bundle_path)

      @sim_control = RunLoop::SimControl.new
      @path_to_ios_sim_app_bundle = lambda {
        dev_dir = @sim_control.xctools.xcode_developer_dir
        "#{dev_dir}/Applications/iOS Simulator.app"
      }.call

      @app = RunLoop::App.new(app_bundle_path)

      unless @app.valid?
        raise "Could not recreate a valid app from '#{app_bundle_path}'"
      end

      @device = device

      RunLoop::SimControl.terminate_all_sims
      shutdown
      terminate_core_simulator_processes
    end

    def udid
      @udid ||= device.udid
    end

    def fullname
      @fullname ||= device.instruments_identifier
    end

    def bundle_identifier
      app.bundle_identifier
    end

    def executable_name
      app.executable_name
    end

    def simulator_app_dir
      @simulator_app_dir ||= lambda {
        device_dir = File.expand_path('~/Library/Developer/CoreSimulator/Devices')
        if device.version < RunLoop::Version.new('8.0')
          File.join(device_dir, udid, 'data', 'Applications')
        else
          File.join(device_dir, udid, 'data', 'Containers', 'Bundle', 'Application')
        end
      }.call
    end

    def update_device_state

      debug_logging = RunLoop::Environment.debug?

      interval = UPDATE_DEVICE_STATE_OPTS[:interval]
      tries = UPDATE_DEVICE_STATE_OPTS[:tries]

      on_retry = Proc.new do |_, try, elapsed_time, next_interval|
        if debug_logging
          # Retriable 2.0
          if elapsed_time && next_interval
            puts "Updating device state attempt #{try} failed in '#{elapsed_time}'; will retry in '#{next_interval}'"
          else
            puts "Updating device state attempt #{try} failed; will retry in #{interval}"
          end
        end
      end

      retry_opts = RunLoop::RetryOpts.tries_and_interval(tries, interval,
                                                         {:on_retry => on_retry,
                                                          :on => [SimctlError]
                                                         })
      current = nil

      Retriable.retriable(retry_opts) do
        current = sim_control.simulators.detect do |sim|
          sim.udid == udid
        end

        unless current
          raise "simctl could not find device with '#{udid}'"
        end

        if current.state == nil || current.state == ''
          raise SimctlError, "Could not find the state of the device with #{udid}"
        end
      end

      @device = current
      @device.state
    end

    def terminate_core_simulator_processes
      ['SimulatorBridge', 'CoreSimulatorBridge', 'configd_sim', 'launchd_sim'].each do |name|
        pids = RunLoop::ProcessWaiter.new(name).pids
        pids.each do |pid|
          puts "Sending 'TERM' to #{name} '#{pid}'"
          term = RunLoop::ProcessTerminator.new(pid, 'TERM', name)
          unless term.kill_process
            puts "Sending 'KILL' to #{name} '#{pid}'"
            term = RunLoop::ProcessTerminator.new(pid, 'KILL', name)
            term.kill_process
          end
        end
      end
    end


    def wait_for_device_state(target_state)
      return true if update_device_state == target_state

      now = Time.now
      timeout = WAIT_FOR_DEVICE_STATE_OPTS[:timeout]
      poll_until = now + WAIT_FOR_DEVICE_STATE_OPTS[:timeout]
      delay = WAIT_FOR_DEVICE_STATE_OPTS[:interval]
      in_state = false
      while Time.now < poll_until
        in_state = update_device_state == target_state
        break if in_state
        sleep delay
      end

      puts "Waited for #{timeout} seconds for device to have state: '#{target_state}'."
      unless in_state
        raise "Expected '#{target_state} but found '#{device.state}' after waiting."
      end
      in_state
    end

    def app_is_installed?
      sim_app_dir = simulator_app_dir
      return false if !File.exist?(sim_app_dir)
      app_path = Dir.glob("#{sim_app_dir}/**/*.app").detect do |path|
        RunLoop::App.new(path).bundle_identifier == bundle_identifier
      end

      !app_path.nil?
    end

    def wait_for_app_install
      return true if app_is_installed?

      now = Time.now
      timeout = WAIT_FOR_APP_INSTALL_OPTS[:timeout]
      poll_until = now + timeout
      delay = WAIT_FOR_APP_INSTALL_OPTS[:interval]
      is_installed = false
      while Time.now < poll_until
        is_installed = app_is_installed?
        break if is_installed
        sleep delay
      end

      puts "Waited for #{timeout} seconds for '#{bundle_identifier}' to install."

      unless is_installed
        raise "Expected app to be installed on #{fullname}"
      end

      true
    end

    def wait_for_app_uninstall
      return true unless app_is_installed?

      now = Time.now
      timeout = WAIT_FOR_APP_INSTALL_OPTS[:timeout]
      poll_until = now + timeout
      delay = WAIT_FOR_APP_INSTALL_OPTS[:interval]
      not_installed = false
      while Time.now < poll_until
        not_installed = !app_is_installed?
        break if not_installed
        sleep delay
      end

      puts "Waited for #{timeout} seconds for '#{bundle_identifier}' to uninstall."

      unless not_installed
        raise "Expected app to be installed on #{fullname}"
      end

      true
    end

    def shutdown
      return true if update_device_state == 'Shutdown'

      if device.state != 'Booted'
        raise "Cannot handle state '#{device.state}' for #{fullname}"
      end

      args = "simctl shutdown #{udid}".split(' ')
      Open3.popen3('xcrun', *args) do |_, _, stderr, status|
        err = stderr.read.strip
        exit_status = status.value.exitstatus
        if exit_status != 0
          raise "Could not shutdown #{fullname}: #{exit_status} => '#{err}'"
        end
      end
      wait_for_device_state('Shutdown')
    end

    def boot
      return true if update_device_state == 'Booted'

      if device.state != 'Shutdown'
        raise "Cannot handle state '#{device.state}' for #{fullname}"
      end

      args = "simctl boot #{udid}".split(' ')
      Open3.popen3('xcrun', *args) do |_, _, stderr, status|
        err = stderr.read.strip
        exit_status = status.value.exitstatus
        if exit_status != 0
          raise "Could not boot #{fullname}: #{exit_status} => '#{err}'"
        end
      end
      wait_for_device_state('Booted')
    end

    def install
      return true if app_is_installed?

      boot

      args = "simctl install #{udid} #{app.path}".split(' ')
      Open3.popen3('xcrun', *args) do |_, _, stderr, process_status|
        err = stderr.read.strip
        exit_status = process_status.value.exitstatus
        if exit_status != 0
          raise "Could not install '#{bundle_identifier}': #{exit_status} => '#{err}'."
        end
      end

      wait_for_app_install
      shutdown
    end

    def uninstall
      return true unless app_is_installed?

      boot

      args = "simctl uninstall #{udid} #{app.bundle_identifier}".split(' ')
      Open3.popen3('xcrun', *args) do |_, _, stderr, process_status|
        err = stderr.read.strip
        exit_status = process_status.value.exitstatus
        if exit_status != 0
          raise "Could not uninstall '#{bundle_identifier}': #{exit_status} => '#{err}'."
        end
      end

      wait_for_app_uninstall
      shutdown
    end

    def launch_simulator
      args = ['open', '-a', @path_to_ios_sim_app_bundle, '--args', '-CurrentDeviceUDID', udid]
      pid = spawn('xcrun', *args)
      Process.detach(pid)
      sleep(5)
    end

    def launch

      install
      launch_simulator

      args = "simctl launch #{udid} #{bundle_identifier}".split(' ')
      Open3.popen3('xcrun', *args) do |_, _, stderr, process_status|
        err = stderr.read.strip
        exit_status = process_status.value.exitstatus
        unless exit_status == 0
          raise "Could not simctl launch '#{bundle_identifier}' on '#{fullname}': #{exit_status} => '#{err}'"
        end
      end

      RunLoop::ProcessWaiter.new(executable_name, WAIT_FOR_APP_LAUNCH_OPTS).wait_for_any
      true
    end

    private

    WAIT_FOR_DEVICE_STATE_OPTS =
          {
                interval: 0.1,
                timeout: 5
          }

    WAIT_FOR_APP_INSTALL_OPTS =
          {
                interval: 0.1,
                timeout: 20
          }

    WAIT_FOR_APP_LAUNCH_OPTS =
          {
                timeout: 10,
                raise_on_timeout: true
          }

    UPDATE_DEVICE_STATE_OPTS =
          {
                :tries => 100,
                :interval => 0.1
          }
  end
end
