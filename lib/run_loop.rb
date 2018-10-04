require "run_loop/abstract"
require 'run_loop/regex'
require 'run_loop/directory'
require "run_loop/encoding"
require "run_loop/shell"
require 'run_loop/environment'
require 'run_loop/logging'
require 'run_loop/dot_dir'
require 'run_loop/xcrun'
require 'run_loop/xcode'
require 'run_loop/l10n'
require 'run_loop/process_terminator'
require 'run_loop/process_waiter'
require 'run_loop/lldb'
require 'run_loop/dylib_injector'
require 'run_loop/fifo'
require 'run_loop/core'
require 'run_loop/version'
require 'run_loop/plist_buddy'
require "run_loop/codesign"
require 'run_loop/app'
require 'run_loop/ipa'
require "run_loop/http/error"
require "run_loop/http/server"
require "run_loop/http/request"
require "run_loop/http/retriable_client"
require "run_loop/device_agent/client"
require "run_loop/device_agent/runner"
require "run_loop/device_agent/frameworks"
require "run_loop/device_agent/launcher_strategy"
require "run_loop/device_agent/ios_device_manager"
require "run_loop/device_agent/xcodebuild"
require "run_loop/detect_aut/errors"
require "run_loop/detect_aut/xamarin_studio"
require "run_loop/detect_aut/xcode"
require "run_loop/detect_aut/detect"
require 'run_loop/device'
require 'run_loop/instruments'
require 'run_loop/lipo'
require "run_loop/otool"
require "run_loop/strings"
require 'run_loop/cache'
require "run_loop/sim_keyboard_settings"
require 'run_loop/patches/awesome_print'
require 'run_loop/core_simulator'
require "run_loop/simctl"
require 'run_loop/template'
require "run_loop/locale"
require "run_loop/language"
require "run_loop/physical_device/life_cycle"
require "run_loop/physical_device/ios_device_manager"

module RunLoop

  # Prints a deprecated message that includes the line number.
  #
  # @param [String] version Indicates when the feature was deprecated.
  # @param [String] msg Deprecation message (possibly suggesting alternatives)
  # @return [void]
  def self.deprecated(version, msg)

    stack = Kernel.caller(0, 6)[1..-1].join("\n")

    msg = "deprecated '#{version}' - #{msg}\n#{stack}"

    $stderr.puts "\033[34mWARN: #{msg}\033[0m"
    $stderr.flush
  end

  class TimeoutError < RuntimeError
  end

  class WriteFailedError < RuntimeError
  end

  def self.run(options={})

    cloned_options = options.clone

    # We want to use the _exact_ objects that were passed.
    if options[:xcode]
      cloned_options[:xcode] = options[:xcode]
    else
      cloned_options[:xcode] = RunLoop::Xcode.new
    end

    if options[:simctl]
      cloned_options[:simctl] = options[:simctl]
    else
      cloned_options[:simctl] = RunLoop::Simctl.new
    end

    if options[:instruments]
      cloned_options[:instruments] = options[:instruments]
    else
      cloned_options[:instruments] = RunLoop::Instruments.new
    end

    # Soon to be unsupported.
    if options[:sim_control]
      cloned_options[:sim_control] = options[:sim_control]
    end

    xcode = cloned_options[:xcode]
    simctl = cloned_options[:simctl]
    instruments = cloned_options[:instruments]

    device = Device.detect_device(cloned_options, xcode, simctl, instruments)
    cloned_options[:device] = device

    automator = RunLoop.detect_automator(cloned_options, xcode, device)
    if automator == :device_agent
      RunLoop::DeviceAgent::Client.run(cloned_options)
    else
      if RunLoop::Instruments.new.instruments_app_running?
        raise %q(The Instruments.app is open.

If the Instruments.app is open, the instruments command line tool cannot take
control of your application.

Please quit the Instruments.app and try again.)

      end
      Core.run_with_options(cloned_options)
    end
  end

  def self.send_command(run_loop, cmd, options={timeout: 60}, num_retries=0, last_error=nil)
    if num_retries > 3
      if last_error
        raise last_error
      else
        raise "Max retries exceeded #{num_retries} > 3. No error recorded."
      end
    end

    if options.is_a?(Numeric)
      options = {timeout: options}
    end

    if not cmd.is_a?(String)
      raise "Illegal command #{cmd} (must be a string)"
    end

    if not options.is_a?(Hash)
      raise "Illegal options #{options} (must be a Hash (or number for compatibility))"
    end

    timeout = options[:timeout] || 60
    logger = options[:logger]
    interrupt_retry_timeout = options[:interrupt_retry_timeout] || 25

    expected_index = run_loop[:index]
    result = nil
    begin
      expected_index = Core.write_request(run_loop, cmd, logger)
    rescue RunLoop::WriteFailedError, Errno::EINTR => write_error
      # Attempt recover from interrupt by attempting to read result (assuming write went OK)
      # or retry if attempted read result fails
      run_loop[:index] = expected_index # restore expected index in case it changed
      log_info(logger, "Core.write_request failed: #{write_error}. Attempting recovery...")
      log_info(logger, "Attempting read in case the request was received... Please wait (#{interrupt_retry_timeout})...")
      begin
        Timeout::timeout(interrupt_retry_timeout, TimeoutError) do
          result = Core.read_response(run_loop, expected_index)
        end
        # Update run_loop expected index since we succeeded in reading the index
        run_loop[:index] = expected_index + 1
        log_info(logger, "Did read response for interrupted request of index #{expected_index}... Proceeding.")
        return result
      rescue TimeoutError => _
        log_info(logger, "Read did not result in a response for index #{expected_index}... Retrying send_command...")
        return send_command(run_loop, cmd, options, num_retries+1, write_error)
      end
    end


    begin
      Timeout::timeout(timeout, TimeoutError) do
        result = Core.read_response(run_loop, expected_index)
      end
    rescue TimeoutError => _
      raise TimeoutError, "Time out waiting for UIAutomation run-loop for command #{cmd}. Waiting for index:#{expected_index}"
    end

    result
  end

  def self.stop(run_loop, out=Dir.pwd)
    return if run_loop.nil?
    results_dir = run_loop[:results_dir]
    dest = out

    RunLoop::Instruments.new.kill_instruments

    FileUtils.mkdir_p(dest)
    if results_dir
      pngs = Dir.glob(File.join(results_dir, 'Run 1', '*.png'))
    else
      pngs = []
    end
    FileUtils.cp(pngs, dest) if pngs and pngs.length > 0
  end

  def self.log_info(*args)
    RunLoop::Logging.log_info(*args)
  end

  # @!visibility private
  #
  # @param [RunLoop::Xcode] xcode The active Xcode
  # @param [RunLoop::Device] device The device under test.
  def self.default_automator(xcode, device)
    # TODO XTC support
    return :instruments if RunLoop::Environment.xtc?

    if xcode.version_gte_8?
      if device.version >= RunLoop::Version.new("9.0")
        :device_agent
      else
        raise RuntimeError, %Q[
Invalid Xcode and iOS combination:

Xcode version: #{xcode.version.to_s}
  iOS version: #{device.version.to_s}

Calabash cannot test iOS < 9.0 using Xcode 8 because DeviceAgent is not
compatible with iOS < 9.0 and UIAutomation is not available in Xcode 8.

You can rerun your test if you have Xcode 7 installed:

$ DEVELOPER_DIR=/path/to/Xcode/7.3.1/Xcode.app/Contents/Developer cucumber

]
      end

    else
      :instruments
    end
  end

  # @!visibility private
  #
  # First pass at choosing the correct code path.
  #
  # We don't know if we can test on iOS 8 with UIAutomation or DeviceAgent on
  # Xcode 8.
  #
  # @param [Hash] options The options passed by the user
  # @param [RunLoop::Xcode] xcode The active Xcode
  # @param [RunLoop::Device] device The device under test
  def self.detect_automator(options, xcode, device)
    # TODO XTC support
    return :instruments if RunLoop::Environment.xtc?

    automator = options[:automator]

    if automator
      if xcode.version_gte_8?
        if automator == :instruments
          raise RuntimeError, %Q[
Incompatible :automator option for active Xcode.

Detected :automator => :instruments and Xcode #{xcode.version}.

Don't set the :automator option unless you are gem maintainer.

]
        elsif device.version < RunLoop::Version.new("9.0")
          raise RuntimeError, %Q[

Invalid Xcode and iOS combination:

Xcode version: #{xcode.version.to_s}
  iOS version: #{device.version.to_s}

Calabash cannot test iOS < 9.0 using Xcode 8 because DeviceAgent is not
compatible with iOS < 9.0 and UIAutomation is not available in Xcode 8.

You can rerun your test if you have Xcode 7 installed:

$ DEVELOPER_DIR=/path/to/Xcode/7.3.1/Xcode.app/Contents/Developer cucumber

Don't set the :automator option unless you are gem maintainer.

]
        end
      end

      if ![:device_agent, :instruments].include?(automator)
        raise RuntimeError, %Q[
Invalid :automator option: #{automator}

Allowed automators: :device_agent or :instruments.

Don't set the :automator option unless you are gem maintainer.

]
      end
      automator
    else
      RunLoop.default_automator(xcode, device)
    end
  end
end
