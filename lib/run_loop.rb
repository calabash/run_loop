require 'run_loop/regex'
require 'run_loop/directory'
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
require 'run_loop/xctools'
require 'run_loop/plist_buddy'
require 'run_loop/app'
require 'run_loop/ipa'
require 'run_loop/sim_control'
require 'run_loop/device'
require 'run_loop/instruments'
require 'run_loop/lipo'
require 'run_loop/cache/cache'
require 'run_loop/host_cache'
require 'run_loop/patches/awesome_print'
require 'run_loop/patches/retriable'
require 'run_loop/core_simulator'
require 'run_loop/simctl/plists'

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

    if RunLoop::Instruments.new.instruments_app_running?
      raise %q(The Instruments.app is open.

If the Instruments.app is open, the instruments command line tool cannot take
control of your application.

Please quit the Instruments.app and try again.)

    end

    uia_strategy = options[:uia_strategy]
    if options[:script]
      script = validate_script(options[:script])
    else
      if uia_strategy
        script = default_script_for_uia_strategy(uia_strategy)
      else
        if options[:calabash_lite]
          uia_strategy = :host
          script = Core.script_for_key(:run_loop_host)
        else
          uia_strategy = :preferences
          script = default_script_for_uia_strategy(uia_strategy)
        end
      end
    end
    # At this point, 'script' has been chosen, but uia_strategy might not
    unless uia_strategy
      desired_script = options[:script]
      if desired_script.is_a?(String) #custom path to script
        uia_strategy = :host
      elsif desired_script == :run_loop_host
        uia_strategy = :host
      elsif desired_script == :run_loop_fast_uia
        uia_strategy = :preferences
      elsif desired_script == :run_loop_shared_element
        uia_strategy = :shared_element
      else
        raise "Inconsistent state: desired script #{desired_script} has not uia_strategy"
      end
    end
    # At this point script and uia_strategy selected

    options[:script] = script
    options[:uia_strategy] = uia_strategy

    Core.run_with_options(options)
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

  def self.default_script_for_uia_strategy(uia_strategy)
    case uia_strategy
      when :preferences
        Core.script_for_key(:run_loop_fast_uia)
      when :host
        Core.script_for_key(:run_loop_host)
      when :shared_element
        Core.script_for_key(:run_loop_shared_element)
      else
        Core.script_for_key(:run_loop_basic)
    end
  end

  def self.validate_script(script)
    if script.is_a?(String)
      unless File.exist?(script)
        raise "Unable to find file: #{script}"
      end
    elsif script.is_a?(Symbol)
      script = Core.script_for_key(script)
      unless script
        raise "Unknown script for symbol: #{script}. Options: #{Core::SCRIPTS.keys.join(', ')}"
      end
    else
      raise "Script must be a symbol or path: #{script}"
    end
    script
  end

  def self.log_info(*args)
    RunLoop::Logging.log_info(*args)
  end

end
