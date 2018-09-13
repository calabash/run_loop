require 'fileutils'
require 'tmpdir'
require 'timeout'
require 'json'
require 'open3'
require 'erb'
require 'ap'

module RunLoop

  module Core

    include RunLoop::Regex

    START_DELIMITER = "OUTPUT_JSON:\n"
    END_DELIMITER="\nEND_OUTPUT"

    SCRIPTS = {
      :dismiss => 'run_dismiss_location.js',
      :run_loop_host => 'run_loop_host.js',
      :run_loop_fast_uia => 'run_loop_fast_uia.js',
      :run_loop_shared_element => 'run_loop_shared_element.js',
      :run_loop_basic => 'run_loop_basic.js'
    }

    SCRIPTS_PATH = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'scripts'))
    READ_SCRIPT_PATH = File.join(SCRIPTS_PATH, 'read-cmd.sh')
    TIMEOUT_SCRIPT_PATH = File.join(SCRIPTS_PATH, 'timeout3')

    def self.log_run_loop_options(options, xcode)
      return unless RunLoop::Environment.debug?
      # Ignore :sim_control b/c it is a ruby object; printing is not useful.
      ignored_keys = [:sim_control]
      options_to_log = {}
      options.each_pair do |key, value|
        next if ignored_keys.include?(key)
        options_to_log[key] = value
      end
      # Objects that override '==' cannot be printed by awesome_print
      # https://github.com/michaeldv/awesome_print/issues/154
      # RunLoop::Version overrides '=='
      options_to_log[:xcode] = xcode.version.to_s
      options_to_log[:xcode_path] = xcode.developer_dir
      message = options_to_log.ai({:sort_keys => true})
      logger = options[:logger]
      RunLoop::Logging.log_debug(logger, "\n" + message)
    end

    def self.script_for_key(key)
      if SCRIPTS[key].nil?
        return nil
      end
      SCRIPTS[key]
    end

    # @!visibility private
    # This is the entry point for UIAutomation.
    def self.run_with_options(options)
      before = Time.now

      self.prepare(options)

      logger = options[:logger]
      simctl = options[:sim_control] || options[:simctl] || RunLoop::Simctl.new
      xcode = options[:xcode] || RunLoop::Xcode.new
      instruments = options[:instruments] || RunLoop::Instruments.new

      # Guard against Xcode version check on the XTC.
      if !RunLoop::Environment.xtc? && xcode.version_gte_8?
        raise %Q[
UIAutomation is not available on Xcode >= 8.*.

We are in the process of updating Calabash to use our new tool: DeviceAgent.

We will track progress in this forum post:

https://groups.google.com/forum/#!topic/calabash-ios/g34znf0LnE4

For now, testing with Xcode 8 is not supported.

Thank you for your patience.
]
      end

      # Device under test: DUT
      device = RunLoop::Device.detect_device(options, xcode, simctl, instruments)

      # App under test: AUT
      app_details = RunLoop::DetectAUT.detect_app_under_test(options)

      # Find the script to pass to instruments and the strategy to communicate
      # with UIAutomation.
      script_n_strategy = self.detect_instruments_script_and_strategy(options,
                                                                      device,
                                                                      xcode)
      instruments_script = script_n_strategy[:script]
      uia_strategy = script_n_strategy[:strategy]

      # The app life cycle reset options.
      reset_options = self.detect_reset_options(options)

      instruments.kill_instruments(xcode)

      timeout = options[:timeout] || 30

      results_dir = options[:results_dir] || RunLoop::DotDir.make_results_dir
      results_dir_trace = File.join(results_dir, 'trace')
      FileUtils.mkdir_p(results_dir_trace)

      dependencies = options[:dependencies] || []
      dependencies << File.join(SCRIPTS_PATH, 'calabash_script_uia.js')
      dependencies.each do |dep|
        FileUtils.cp(dep, results_dir)
      end

      script = File.join(results_dir, '_run_loop.js')

      javascript = UIAScriptTemplate.new(SCRIPTS_PATH, instruments_script).result
      UIAScriptTemplate.sub_path_var!(javascript, results_dir)
      UIAScriptTemplate.sub_read_script_path_var!(javascript, READ_SCRIPT_PATH)
      UIAScriptTemplate.sub_timeout_script_path_var!(javascript, TIMEOUT_SCRIPT_PATH)

      # Using a :no_* option is confusing.
      # TODO Replace :no_flush with :flush_uia_logs; it should default to true
      if RunLoop::Environment.xtc?
        UIAScriptTemplate.sub_mode_var!(javascript, "FLUSH") unless options[:no_flush]
      else
        if self.detect_flush_uia_log_option(options)
          UIAScriptTemplate.sub_flush_uia_logs_var!(javascript, "FLUSH_LOGS")
        end
      end

      repl_path = File.join(results_dir, 'repl-cmd.pipe')
      FileUtils.rm_f(repl_path)

      if uia_strategy == :host
        create_uia_pipe(repl_path)
      else
        FileUtils.touch repl_path
      end

      RunLoop::Cache.default.clear unless RunLoop::Environment.xtc?

      cal_script = File.join(SCRIPTS_PATH, 'calabash_script_uia.js')
      File.open(script, 'w') do |file|
        if include_calabash_script?(options)
          file.puts IO.read(cal_script)
        end
        file.puts javascript
      end

      args = options.fetch(:args, [])

      log_file = options[:log_path] || File.join(results_dir, 'run_loop.out')

      discovered_options =
        {
          :udid => device.udid,
          :device => device,
          :results_dir_trace => results_dir_trace,
          :bundle_id => app_details[:bundle_id],
          :app => app_details[:app]  || app_details[:bundle_id],
          :results_dir => results_dir,
          :script => script,
          :log_file => log_file,
          :args => args,
          :uia_strategy => uia_strategy,
          :base_script => instruments_script
        }
      merged_options = options.merge(discovered_options)

      if device.simulator?
        if !app_details[:app]
          raise %Q[

Invalid APP, APP_BUNDLE_PATH, or BUNDLE_ID detected.

The following information was detected from the environment:

             APP='#{ENV["APP"]}'
 APP_BUNDLE_PATH='#{ENV["APP_BUNDLE_PATH"]}'
       BUNDLE_ID='#{ENV["BUNDLE_ID"]}'


It looks like you are trying to launch an app on a simulator using a bundle
identifier or you have incorrectly set the APP variable to an app bundle that
does not exist.

If you are trying to launch a test against a physical device, set the DEVICE_TARGET
variable to the UDID of your device an APP to a bundle identifier or a path to
an .ipa.

# com.example.MyApp must be installed on the target device
$ APP=com.example.MyApp DEVICE_TARGET="John's iPhone" cucumber

If you are trying to launch against a simulator and you encounter this error, it
means that the APP variable is pointing to a .app that does not exist.

]
        end
        self.prepare_simulator(app_details[:app], device, xcode, simctl, reset_options)
      end

      self.log_run_loop_options(merged_options, xcode)

      automation_template = automation_template(instruments)

      RunLoop::Logging.log_header(logger, "Starting on #{device.name} App: #{app_details[:bundle_id]}")

      pid = instruments.spawn(automation_template, merged_options, log_file)

      File.open(File.join(results_dir, 'run_loop.pid'), 'w') do |f|
        f.write pid
      end

      run_loop = {
        :pid => pid,
        :index => 1,
        :uia_strategy => uia_strategy,
        :udid => device.udid,
        :app => app_details[:bundle_id],
        :repl_path => repl_path,
        :log_file => log_file,
        :results_dir => results_dir,
        :automator => :instruments
      }

      uia_timeout = options[:uia_timeout] || RunLoop::Environment.uia_timeout || 10

      RunLoop::Logging.log_debug(logger, "Preparation took #{Time.now-before} seconds")

      before_instruments_launch = Time.now

      fifo_retry_on = [
        RunLoop::Fifo::NoReaderConfiguredError,
        RunLoop::Fifo::WriteTimedOut
      ]

      begin

        if options[:validate_channel]
          options[:validate_channel].call(run_loop, 0, uia_timeout)
        else

          cmd = "UIALogger.logMessage('Listening for run loop commands')"

          begin

            fifo_timeout = options[:fifo_timeout] || 30
            RunLoop::Fifo.write(repl_path, "0:#{cmd}", timeout: fifo_timeout)

          rescue *fifo_retry_on => e

            message = "Error while writing to fifo. #{e}"
            RunLoop::Logging.log_debug(logger, message)
            raise RunLoop::TimeoutError.new(message)

          end

          Timeout::timeout(timeout, RunLoop::TimeoutError) do
            read_response(run_loop, 0, uia_timeout)
          end

        end
      rescue RunLoop::TimeoutError => e
        RunLoop::Logging.log_debug(logger, "Failed to launch. #{e}: #{e && e.message}")

        message = %Q(

"Timed out waiting for UIAutomation run-loop #{e}.

Logfile: #{log_file}

        #{File.read(log_file)}

        )
        raise RunLoop::TimeoutError, message
      end

      RunLoop::Logging.log_debug(logger, "Launching took #{Time.now-before_instruments_launch} seconds")

      dylib_path = RunLoop::DylibInjector.dylib_path_from_options(merged_options)

      if dylib_path
        if device.physical_device?
          raise RuntimeError, "Injecting a dylib is not supported when targeting a device"
        end

        app = app_details[:app]
        lldb = RunLoop::DylibInjector.new(app.executable_name, dylib_path)
        lldb.retriable_inject_dylib
      end

      RunLoop.log_debug("It took #{Time.now - before} seconds to launch the app")
      run_loop
    end

    # @!visibility private
    # Usually we include CalabashScript to ease uia automation.
    # However in certain scenarios we don't load it since
    # it slows down the UIAutomation initialization process
    # occasionally causing privacy/security dialogs not to be automated.
    #
    # @return {boolean} true if CalabashScript should be loaded
    def self.include_calabash_script?(options)

      if (options[:include_calabash_script] == false) || options[:dismiss_immediate_dialogs]
        return false
      end
      if Core.script_for_key(:run_loop_basic) == options[:script]
        return options[:include_calabash_script]
      end
      true
    end

    # Returns the a default simulator to target.  This default needs to be one
    # that installed by default in the current Xcode version.
    #
    # @param [RunLoop::Xcode] xcode Used to detect the current xcode
    #  version.
    def self.default_simulator(xcode=RunLoop::Xcode.new)
      version = xcode.version
      xcode_major = version.major
      xcode_minor = version.minor
      major = xcode_major + 2
      minor = xcode_minor

      if xcode_major == 10
        model = "XS"
      else
        model = xcode_major - 1
      end

      "iPhone #{model} (#{major}.#{minor})"
    end

    def self.create_uia_pipe(repl_path)
      begin
        Timeout::timeout(5, RunLoop::TimeoutError) do
          loop do
            begin
              FileUtils.rm_f(repl_path)
              return repl_path if system(%Q[mkfifo "#{repl_path}"])
            rescue Errno::EINTR => _
              sleep(0.1)
            end
          end
        end
      rescue RunLoop::TimeoutError => _
        raise RunLoop::TimeoutError, 'Unable to create pipe (mkfifo failed)'
      end
    end

    def self.jruby?
      RUBY_PLATFORM == 'java'
    end

    def self.write_request(run_loop, cmd, logger=nil)
      repl_path = run_loop[:repl_path]
      index = run_loop[:index]
      cmd_str = "#{index}:#{escape_host_command(cmd)}"
      RunLoop::Logging.log_debug(logger, cmd_str)
      write_succeeded = false
      2.times do |i|
        RunLoop::Logging.log_debug(logger, "Trying write of command #{cmd_str} at index #{index}")
        begin
          RunLoop::Fifo.write(repl_path, cmd_str)
          write_succeeded = validate_index_written(run_loop, index, logger)
        rescue RunLoop::Fifo::NoReaderConfiguredError,
          RunLoop::Fifo::WriteTimedOut => e
          RunLoop::Logging.log_debug(logger, "Error while writing command (retry count #{i}). #{e}")
        end
        break if write_succeeded
      end
      unless write_succeeded
        RunLoop::Logging.log_debug(logger, 'Failing...Raising RunLoop::WriteFailedError')
        raise RunLoop::WriteFailedError.new("Trying write of command #{cmd_str} at index #{index}")
      end
      run_loop[:index] = index + 1
      RunLoop::Cache.default.write(run_loop) unless RunLoop::Environment.xtc?
      index
    end

    def self.validate_index_written(run_loop, index, logger)
      begin
        Timeout::timeout(10, RunLoop::TimeoutError) do
          Core.read_response(run_loop, index, 10, 'last_index')
        end
        RunLoop::Logging.log_debug(logger, "validate index written for index #{index} ok")
        return true
      rescue RunLoop::TimeoutError => _
        RunLoop::Logging.log_debug(logger, "validate index written for index #{index} failed. Retrying.")
        return false
      end
    end

    def self.escape_host_command(cmd)
      backquote = "\\"
      cmd.gsub(backquote,backquote*4)
    end

    def self.log_instruments_error(msg)
      $stderr.puts "\033[31m\n\n*** #{msg} ***\n\n\033[0m"
      $stderr.flush
    end

    def self.read_response(run_loop, expected_index, empty_file_timeout=10, search_for_property='index')
      debug_read = RunLoop::Environment.debug_read?

      log_file = run_loop[:log_file]
      initial_offset = run_loop[:initial_offset] || 0
      offset = initial_offset

      result = nil
      loop do
        unless File.exist?(log_file) && File.size?(log_file)
          sleep(0.2)
          next
        end

        size = File.size(log_file)
        output = File.read(log_file, size-offset, offset)

        if /AXError: Could not auto-register for pid status change/.match(output)
          if /kAXErrorServerNotFound/.match(output)
            self.log_instruments_error('Accessibility is not enabled on device/simulator, please enable it.')
          end
          raise RunLoop::TimeoutError.new('AXError: Could not auto-register for pid status change')
        end

        if /Automation Instrument ran into an exception/.match(output)
          raise RunLoop::TimeoutError.new('Exception while running script')
        end

        if /FBSOpenApplicationErrorDomain error/.match(output)
          msg = "Instruments failed to launch app: 'FBSOpenApplicationErrorDomain error 8"
          if RunLoop::Environment.debug?
            self.log_instruments_error(msg)
          end
          raise RunLoop::TimeoutError.new(msg)
        end

        if /Error: Script threw an uncaught JavaScript error: unknown JavaScript exception/.match(output)
          msg = "Instruments failed to launch: because of an unknown JavaScript exception"
          if RunLoop::Environment.debug?
            self.log_instruments_error(msg)
          end
          raise RunLoop::TimeoutError.new(msg)
        end

        index_if_found = output.index(START_DELIMITER)
        if debug_read
          puts output.gsub('*', '')
          puts "Size #{size}"
          puts "offset #{offset}"
          puts "index_of #{START_DELIMITER}: #{index_if_found}"
        end

        if index_if_found

          offset = offset + index_if_found
          rest = output[index_if_found+START_DELIMITER.size..output.length]
          index_of_json = rest.index("}#{END_DELIMITER}")

          if index_of_json.nil?
            #Wait for rest of json
            sleep(0.1)
            next
          end

          json = rest[0..index_of_json]


          if debug_read
            puts "Index #{index_if_found}, Size: #{size} Offset #{offset}"

            puts ("parse #{json}")
          end

          offset = offset + json.size
          parsed_result = JSON.parse(json)
          if debug_read
            p parsed_result
          end
          json_index_if_present = parsed_result[search_for_property]
          if json_index_if_present && json_index_if_present == expected_index
            result = parsed_result
            break
          end
        else
          sleep(0.1)
        end
      end

      run_loop[:initial_offset] = offset
      RunLoop::Cache.default.write(run_loop) unless RunLoop::Environment.xtc?
      result
    end

    def self.automation_template(instruments, candidate=RunLoop::Environment.trace_template)
      unless candidate && File.exist?(candidate)
        candidate = default_tracetemplate(instruments)
      end
      candidate
    end

    def self.default_tracetemplate(instruments=RunLoop::Instruments.new)

      templates = instruments.templates

      if instruments.xcode.version_gte_8?
        raise(RuntimeError, %Q[

There is no Automation template for this #{instruments.xcode} version.

])
      end

      # xcrun instruments -s templates
      # Xcode >= 6 will return known, Apple defined tracetemplates as names
      #  e.g.  Automation, Zombies, Allocations
      #
      # Xcode < 6 will return known, Apple defined tracetemplates as paths.
      #
      # Xcode 6 Beta versions also return paths, but revert to 'normal'
      # behavior when GM is released.
      #
      # Xcode 7 Beta versions appear to behavior like Xcode 6 Beta versions.
      template = templates.find { |name| name == 'Automation' }
      return template if template

      candidate = templates.find do |path|
        path =~ /\/Automation.tracetemplate/ and path =~ /Xcode/
      end

      if !candidate.nil?
        return candidate.tr("\"", '').strip
      end

      raise(RuntimeError, %Q[
Expected instruments to report an Automation tracetemplate.

Please report this as bug:  https://github.com/calabash/run_loop/issues

In the bug report, include the output of:

$ xcrun xcodebuild -version
$ xcrun instruments -s templates
])
    end

    def self.instruments_running?
      RunLoop::Instruments.new.instruments_running?
    end

    private

    # @!visibility private
    #
    # @param [Hash] options The launch options passed to .run_with_options
    def self.prepare(run_options)
      RunLoop::DotDir.rotate_result_directories
      RunLoop::Instruments.rotate_cache_directories
      true
    end

    # @!visibility private
    #
    # @param [RunLoop::Device] device The device under test.
    # @param [RunLoop::Xcode] xcode The active Xcode
    def self.default_uia_strategy(device, xcode)
      if xcode.version_gte_7?
        :host
      elsif device.physical_device? && device.version >= RunLoop::Version.new("8.0")
        :host
      else
        :preferences
      end
    end

    # @!visibility private
    #
    # @param [Hash] options The launch options passed to .run_with_options
    # @param [RunLoop::Device] device The device under test.
    # @param [RunLoop::Xcode] xcode The active Xcode.
    def self.detect_uia_strategy(options, device, xcode)
      strategy = options[:uia_strategy] || self.default_uia_strategy(device, xcode)

      if ![:host, :preferences, :shared_element].include?(strategy)
        raise ArgumentError,
              "Invalid strategy: expected '#{strategy}' to be :host, :preferences, or :shared_element"
      end
      strategy
    end

    # @!visibility private
    #
    # There is an unnatural relationship between the :script and the
    # :uia_strategy keys.
    #
    # @param [Hash] options The launch options passed to .run_with_options
    # @param [RunLoop::Device] device The device under test.
    # @param [RunLoop::Xcode] xcode The active Xcode.
    #
    # @return [Hash] with two keys: :script and :uia_strategy
    def self.detect_instruments_script_and_strategy(options, device, xcode)
      strategy = options[:uia_strategy]
      script = options[:script]

      if script
        script = self.expect_instruments_script(script)
        if !strategy
          strategy = :host
        end
      else
        if strategy
          script = self.instruments_script_for_uia_strategy(strategy)
        else
          if options[:calabash_lite]
            strategy = :host
            script = self.instruments_script_for_uia_strategy(strategy)
          else
            strategy = self.detect_uia_strategy(options, device, xcode)
            script = self.instruments_script_for_uia_strategy(strategy)
          end
        end
      end

      {
        :script => script,
        :strategy => strategy
      }
    end

    # @!visibility private
    #
    # UIAutomation buffers log output in some very strange ways.  RunLoop
    # attempts to work around this buffering by forcing characters onto the
    # UIALogger buffer.  Once the buffer is full, UIAutomation will dump its
    # contents.  It is essential that the communication between UIAutomation
    # and RunLoop be synchronized.
    #
    # Casual users should never set the :flush_uia_logs key; they should use the
    # defaults.
    #
    # :no_flush is supported (for now) as alternative key.
    #
    # @param [Hash] options The launch options passed to .run_with_options
    def self.detect_flush_uia_log_option(options)
      if options.has_key?(:no_flush)
        # Confusing.
        # :no_flush == false means, flush the logs.
        # :no_flush == true means, don't flush the logs.
        return !options[:no_flush]
      end

      return options.fetch(:flush_uia_logs, true)
    end

    # @!visibility private
    #
    # @param [Hash] options The launch options passed to .run_with_options
    def self.detect_reset_options(options)
      return options[:reset] if options.has_key?(:reset)

      return options[:reset_app_sandbox] if options.has_key?(:reset_app_sandbox)

      RunLoop::Environment.reset_between_scenarios?
    end

    # Prepares the simulator for running.
    #
    # 1. enabling accessibility and software keyboard
    # 2. installing / uninstalling apps
    #
    # TODO: move to CoreSimulator?
    def self.prepare_simulator(app, device, xcode, simctl, reset_options)

      # Validate the architecture.
      self.expect_simulator_compatible_arch(device, app)

      RunLoop::CoreSimulator.quit_simulator
      core_sim = RunLoop::CoreSimulator.new(device, app, xcode: xcode)

      # Calabash 0.x can only reset the app sandbox (true/false).
      # Calabash 2.x has advanced reset options.
      if reset_options
        core_sim.reset_app_sandbox
      end

      # Launches the simulator if the app is not installed.
      core_sim.install

      # If CoreSimulator has already launched the simulator, it will not launch it again.
      core_sim.launch_simulator
    end

    # @!visibility private
    # Raise an error if the application binary is not compatible with the
    # target simulator.
    #
    # @param [RunLoop::Device] device The device to install on.
    # @param [RunLoop::App] app The app to install.
    #
    # @raise [RunLoop::IncompatibleArchitecture] Raises an error if the
    #  application binary is not compatible with the target simulator.
    def self.expect_simulator_compatible_arch(device, app)
      lipo = RunLoop::Lipo.new(app.path)
      lipo.expect_compatible_arch(device)

      RunLoop.log_debug("Simulator instruction set '#{device.instruction_set}' is compatible with '#{lipo.info}'")
    end

    # @!visibility private
    def self.expect_instruments_script(script)
      if script.is_a?(String)
        unless File.exist?(script)
          raise %Q[Expected instruments JavaScript file at path:

#{script}

Check the :script key in your launch options.]
        end
        script
      elsif script.is_a?(Symbol)
        path = self.script_for_key(script)
        if !path
          raise %Q[Expected :#{script} to be one of:

#{Core::SCRIPTS.keys.map { |key| ":#{key}" }.join("\n")}

Check the :script key in your launch options.]
        end
        path
      else
        raise %Q[Expected '#{script}' to be a Symbol or a String.

Check the :script key in your launch options.]
      end
    end

    # @!visibility private
    def self.instruments_script_for_uia_strategy(uia_strategy)
      case uia_strategy
      when :preferences
        self.script_for_key(:run_loop_fast_uia)
      when :host
        self.script_for_key(:run_loop_host)
      when :shared_element
        self.script_for_key(:run_loop_shared_element)
      else
        self.script_for_key(:run_loop_basic)
      end
    end
  end
end

