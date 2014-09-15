require 'fileutils'
require 'tmpdir'
require 'timeout'
require 'json'
require 'open3'
require 'erb'

module RunLoop

  class TimeoutError < RuntimeError
  end

  module Core

    START_DELIMITER = "OUTPUT_JSON:\n"
    END_DELIMITER="\nEND_OUTPUT"

    SCRIPTS_PATH = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'scripts'))
    SCRIPTS = {
        :dismiss => 'run_dismiss_location.js',
        :run_loop_fast_uia => 'run_loop_fast_uia.js',
        :run_loop_host => 'run_loop_host.js',
        :run_loop_basic => 'run_loop_basic.js'
    }

    READ_SCRIPT_PATH = File.join(SCRIPTS_PATH, 'read-cmd.sh')

    def self.scripts_path
      SCRIPTS_PATH
    end

    # @deprecated since 1.0.0
    # still used extensively in calabash-ios launcher
    def self.above_or_eql_version?(target_version, xcode_version)
      if target_version.is_a?(RunLoop::Version)
        target = target_version
      else
        target = RunLoop::Version.new(target_version)
      end

      if xcode_version.is_a?(RunLoop::Version)
        xcode = xcode_version
      else
        xcode = RunLoop::Version.new(xcode_version)
      end
      target >= xcode
    end

    def self.script_for_key(key)
      if SCRIPTS[key].nil?
        return nil
      end
      File.join(scripts_path, SCRIPTS[key])
    end

    def self.detect_connected_device
      begin
        Timeout::timeout(1, TimeoutError) do
          return `#{File.join(scripts_path, 'udidetect')}`.chomp
        end
      rescue TimeoutError => _
        `killall udidetect &> /dev/null`
      end
      nil
    end

    def self.run_with_options(options)
      before = Time.now
      ensure_instruments_not_running!

      sim_control ||= options[:sim_control] || RunLoop::SimControl.new
      xctools ||= options[:xctools] || sim_control.xctools

      if self.simulator_target?(options, sim_control)
        # @todo only enable accessibility on the targeted simulator
        sim_control.enable_accessibility_on_sims({:verbose => true})
      end

      device_target = options[:udid] || options[:device_target] || detect_connected_device || 'simulator'
      if device_target && device_target.to_s.downcase == 'device'
        device_target = detect_connected_device
      end

      log_file = options[:log_path]
      timeout = options[:timeout] || 30

      results_dir = options[:results_dir] || Dir.mktmpdir('run_loop')
      results_dir_trace = File.join(results_dir, 'trace')
      FileUtils.mkdir_p(results_dir_trace)

      dependencies = options[:dependencies] || []
      dependencies << File.join(scripts_path, 'calabash_script_uia.js')
      dependencies.each do |dep|
        FileUtils.cp(dep, results_dir)
      end

      script = File.join(results_dir, '_run_loop.js')


      code = File.read(options[:script])
      code = code.gsub(/\$PATH/, results_dir)
      code = code.gsub(/\$READ_SCRIPT_PATH/, READ_SCRIPT_PATH)
      code = code.gsub(/\$MODE/, 'FLUSH') unless options[:no_flush]

      repl_path = File.join(results_dir, 'repl-cmd.pipe')
      FileUtils.rm_f(repl_path)

      uia_strategy = options[:uia_strategy]
      if uia_strategy == :host
        create_uia_pipe(repl_path)
      end

      cal_script = File.join(SCRIPTS_PATH, 'calabash_script_uia.js')
      File.open(script, 'w') do |file|
        file.puts IO.read(cal_script)
        file.puts code
      end

      # Compute udid and bundle_dir / bundle_id from options and target depending on Xcode version
      udid, bundle_dir_or_bundle_id = udid_and_bundle_for_launcher(device_target, options, xctools)

      args = options.fetch(:args, [])

      inject_dylib = self.dylib_path_from_options options
      # WIP This is brute-force call against all lldb processes.
      self.ensure_lldb_not_running if inject_dylib

      log_file ||= File.join(results_dir, 'run_loop.out')

      if ENV['DEBUG']=='1'
        exclude = [:device_target, :udid, :sim_control, :args, :inject_dylib, :app]
        options.each_pair { |key, value|
          unless exclude.include? key
            puts "#{key} => #{value}"
          end
        }
        puts "device_target=#{device_target}"
        puts "udid=#{udid}"
        puts "bundle_dir_or_bundle_id=#{bundle_dir_or_bundle_id}"
        puts "script=#{script}"
        puts "log_file=#{log_file}"
        puts "timeout=#{timeout}"
        puts "uia_strategy=#{options[:uia_strategy]}"
        puts "args=#{args}"
        puts "inject_dylib=#{inject_dylib}"
      end

      after = Time.now

      if ENV['DEBUG']=='1'
        puts "Preparation took #{after-before} seconds"

      end

      cmd = instruments_command(options.merge(:udid => udid,
                                              :results_dir_trace => results_dir_trace,
                                              :bundle_dir_or_bundle_id => bundle_dir_or_bundle_id,
                                              :results_dir => results_dir,
                                              :script => script,
                                              :log_file => log_file,
                                              :args => args),
                                xctools)

      log_header("Starting on #{device_target} App: #{bundle_dir_or_bundle_id}")
      cmd_str = cmd.join(' ')
      if ENV['DEBUG']
        log(cmd_str)
      end
      if !jruby? && RUBY_VERSION && RUBY_VERSION.start_with?('1.8')
        pid = fork do
          exec(cmd_str)
        end
      else
        pid = spawn(cmd_str)
      end

      Process.detach(pid)

      File.open(File.join(results_dir, 'run_loop.pid'), 'w') do |f|
        f.write pid
      end

      run_loop = {:pid => pid,
                  :index => 1,
                  :uia_strategy => uia_strategy,
                  :udid => udid,
                  :app => bundle_dir_or_bundle_id,
                  :repl_path => repl_path,
                  :log_file => log_file,
                  :results_dir => results_dir}

      uia_timeout = options[:uia_timeout] || (ENV['UIA_TIMEOUT'] && ENV['UIA_TIMEOUT'].to_f) || 10

      raw_lldb_output = nil
      before = Time.now
      begin

        if options[:validate_channel]
          options[:validate_channel].call(run_loop, 0, uia_timeout)
        else
          File.open(repl_path, 'w') { |file| file.puts "0:UIALogger.logMessage('Listening for run loop commands');" }
          Timeout::timeout(timeout, TimeoutError) do
            read_response(run_loop, 0, uia_timeout)
          end
        end

        # inject_dylib will be nil or a path to a dylib
        if inject_dylib
          lldb_template_file = File.join(scripts_path, 'calabash.lldb.erb')
          lldb_template = ::ERB.new(File.read(lldb_template_file))
          lldb_template.filename = lldb_template_file

          # Special!
          # These are required by the ERB in calabash.lldb.erb
          # noinspection RubyUnusedLocalVariable
          cf_bundle_executable = find_cf_bundle_executable(bundle_dir_or_bundle_id)
          # noinspection RubyUnusedLocalVariable
          dylib_path_for_target = inject_dylib

          lldb_cmd = lldb_template.result(binding)

          tmpdir = Dir.mktmpdir('lldb_cmd')
          lldb_script = File.join(tmpdir, 'lldb')

          File.open(lldb_script, 'w') { |f| f.puts(lldb_cmd) }

          if ENV['DEBUG'] == '1'
            puts "lldb script #{lldb_script}"
            puts "=== lldb script ==="
            counter = 0
            File.open(lldb_script, 'r').readlines.each { |line|
              puts "#{counter} #{line}"
              counter = counter + 1
            }
            puts "=== lldb script ==="
          end

          # Forcing a timeout.  Do not retry here.  If lldb is hanging,
          # RunLoop::Core.run* needs to be called again.  Put another way,
          # instruments and lldb must be terminated.
          Retriable.retriable({:tries => 1, :timeout => 12, :interval => 1}) do
            raw_lldb_output = `xcrun lldb -s #{lldb_script}`
            if ENV['DEBUG'] == '1'
              puts raw_lldb_output
            end
          end
        end
      rescue TimeoutError => e
        if ENV['DEBUG']
          puts "Failed to launch\n"
          puts "reason=#{e}: #{e && e.message} "
          puts "device_target=#{device_target}"
          puts "udid=#{udid}"
          puts "bundle_dir_or_bundle_id=#{bundle_dir_or_bundle_id}"
          puts "script=#{script}"
          puts "log_file=#{log_file}"
          puts "timeout=#{timeout}"
          puts "uia_strategy=#{uia_strategy}"
          puts "args=#{args}"
          puts "lldb_output=#{raw_lldb_output}" if raw_lldb_output
        end
        raise TimeoutError, "Time out waiting for UIAutomation run-loop to Start. \n Logfile #{log_file} \n\n #{File.read(log_file)}\n"
      end

      after = Time.now()

      if ENV['DEBUG']=='1'
        puts "Launching took #{after-before} seconds"
      end

      run_loop
    end

    # @!visibility private
    # Are we targeting a simulator?
    #
    # @note  The behavior of this method is different than the corresponding
    #   method in Calabash::Cucumber::Launcher method.  If
    #   `:device_target => {nil | ''}`, then the calabash-ios method returns
    #   _false_.  I am basing run-loop's behavior off the behavior in
    #   `self.udid_and_bundle_for_launcher`
    #
    # @see {Core::RunLoop.udid_and_bundle_for_launcher}
    def self.simulator_target?(run_options, sim_control = RunLoop::SimControl.new)
      value = run_options[:device_target]

      # match the behavior of udid_and_bundle_for_launcher
      return true if value.nil? or value == ''

      # support for 'simulator' and Xcode >= 5.1 device targets
      return true if value.downcase.include?('simulator')

      # if Xcode < 6.0, we are done
      return false if not sim_control.xcode_version_gte_6?

      # support for Xcode >= 6 simulator udids
      return true if sim_control.sim_udid? value

      # support for Xcode >= 6 'named simulators'
      sims = sim_control.simulators.each
      sims.find_index { |device| device.name == value } != nil
    end

    # Extracts the value of :inject_dylib from options Hash.
    # @param options [Hash] arguments passed to {RunLoop.run}
    # @return [String, nil] If the options contains :inject_dylibs and it is a
    #  path to a dylib that exists, return the path.  Otherwise return nil or
    #  raise an error.
    # @raise [RuntimeError] If :inject_dylib points to a path that does not exist.
    # @raise [ArgumentError] If :inject_dylib is not a String.
    def self.dylib_path_from_options(options)
      inject_dylib = options.fetch(:inject_dylib, nil)
      return nil if inject_dylib.nil?
      unless inject_dylib.is_a? String
        raise ArgumentError, "Expected :inject_dylib to be a path to a dylib, but found '#{inject_dylib}'"
      end
      dylib_path = File.expand_path(inject_dylib)
      unless File.exist?(dylib_path)
        raise "Cannot load dylib.  The file '#{dylib_path}' does not exist."
      end
      dylib_path
    end

    def self.find_cf_bundle_executable(bundle_dir_or_bundle_id)
      unless File.directory?(bundle_dir_or_bundle_id)
        raise "Injecting dylibs currently only works with simulator and app bundles"
      end
      info_plist = Dir[File.join(bundle_dir_or_bundle_id, 'Info.plist')].first
      raise "Unable to find Info.plist in #{bundle_dir_or_bundle_id}" if info_plist.nil?
      `/usr/libexec/PlistBuddy -c "Print :CFBundleExecutable" "#{info_plist}"`.strip
    end

    def self.udid_and_bundle_for_launcher(device_target, options, xctools=RunLoop::XCTools.new)
      bundle_dir_or_bundle_id = options[:app] || ENV['BUNDLE_ID']|| ENV['APP_BUNDLE_PATH'] || ENV['APP']

      unless bundle_dir_or_bundle_id
        raise 'key :app or environment variable APP_BUNDLE_PATH, BUNDLE_ID or APP must be specified as path to app bundle (simulator) or bundle id (device)'
      end

      udid = nil

      if xctools.xcode_version_gte_51?
        if device_target.nil? || device_target.empty? || device_target == 'simulator'
          if xctools.xcode_version_gte_6?
            # the simulator can be either the textual name or the UDID (directory name)
            device_target = 'iPhone 5 (8.0 Simulator)'
          else
            device_target = 'iPhone Retina (4-inch) - Simulator - iOS 7.1'
          end
        end
        udid = device_target

        unless /simulator/i.match(device_target)
          bundle_dir_or_bundle_id = options[:bundle_id] if options[:bundle_id]
        end
      else
        if device_target == 'simulator'

          unless File.exist?(bundle_dir_or_bundle_id)
            raise "Unable to find app in directory #{bundle_dir_or_bundle_id} when trying to launch simulator"
          end


          device = options[:device] || :iphone
          device = device && device.to_sym

          plistbuddy='/usr/libexec/PlistBuddy'
          plistfile="#{bundle_dir_or_bundle_id}/Info.plist"
          if device == :iphone
            uidevicefamily=1
          else
            uidevicefamily=2
          end
          system("#{plistbuddy} -c 'Delete :UIDeviceFamily' '#{plistfile}'")
          system("#{plistbuddy} -c 'Add :UIDeviceFamily array' '#{plistfile}'")
          system("#{plistbuddy} -c 'Add :UIDeviceFamily:0 integer #{uidevicefamily}' '#{plistfile}'")
        else
          udid = device_target
          bundle_dir_or_bundle_id = options[:bundle_id] if options[:bundle_id]
        end
      end
      return udid, bundle_dir_or_bundle_id
    end

    # @deprecated 1.0.0 replaced with Xctools#version
    def self.xcode_version(xctools=XCTools.new)
      xctools.xcode_version.to_s
    end

    def self.create_uia_pipe(repl_path)
      begin
        Timeout::timeout(5, TimeoutError) do
          loop do
            begin
              FileUtils.rm_f(repl_path)
              return repl_path if system(%Q[mkfifo "#{repl_path}"])
            rescue Errno::EINTR => e
              #retry
              sleep(0.1)
            end
          end
        end
      rescue TimeoutError => _
        raise TimeoutError, 'Unable to create pipe (mkfifo failed)'
      end
    end

    def self.jruby?
      RUBY_PLATFORM == 'java'
    end

    def self.write_request(run_loop, cmd)
      repl_path = run_loop[:repl_path]
      index = run_loop[:index]
      File.open(repl_path, 'w') { |f| f.puts("#{index}:#{cmd}") }
      run_loop[:index] = index + 1

      index
    end

    def self.read_response(run_loop, expected_index, empty_file_timeout=10)

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
            $stderr.puts "\n\n****** Accessibility is not enabled on device/simulator, please enable it *** \n\n"
            $stderr.flush
          end
          raise TimeoutError.new('AXError: Could not auto-register for pid status change')
        end
        if /Automation Instrument ran into an exception/.match(output)
          raise TimeoutError.new('Exception while running script')
        end
        index_if_found = output.index(START_DELIMITER)
        if ENV['DEBUG_READ']=='1'
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


          if ENV['DEBUG_READ']=='1'
            puts "Index #{index_if_found}, Size: #{size} Offset #{offset}"

            puts ("parse #{json}")
          end

          offset = offset + json.size
          parsed_result = JSON.parse(json)
          if ENV['DEBUG_READ']=='1'
            p parsed_result
          end
          json_index_if_present = parsed_result['index']
          if json_index_if_present && json_index_if_present == expected_index
            result = parsed_result
            break
          end
        else
          sleep(0.1)
        end
      end

      run_loop[:initial_offset] = offset

      result

    end

    def self.pids_for_run_loop(run_loop, &block)
      results_dir = run_loop[:results_dir]
      udid = run_loop[:udid]
      instruments_prefix = instruments_command_prefix(udid, results_dir)

      pids_str = `ps x -o pid,command | grep -v grep | grep "#{instruments_prefix.gsub(%Q["], %Q[\\"])}" | awk '{printf "%s,", $1}'`
      pids = pids_str.split(',').map { |pid| pid.to_i }
      if block_given?
        pids.each do |pid|
          block.call(pid)
        end
      else
        pids
      end
    end

    def self.instruments_command_prefix(udid, results_dir_trace)
      instruments_path = 'xcrun instruments'
      if udid
        instruments_path = "#{instruments_path} -w \"#{udid}\""
      end
      instruments_path << " -D \"#{results_dir_trace}\"" if results_dir_trace
      instruments_path
    end


    def self.instruments_command(options, xctools=XCTools.new)
      udid = options[:udid]
      results_dir_trace = options[:results_dir_trace]
      bundle_dir_or_bundle_id = options[:bundle_dir_or_bundle_id]
      results_dir = options[:results_dir]
      script = options[:script]
      log_file = options[:log_file]
      args= options[:args] || []

      instruments_prefix = instruments_command_prefix(udid, results_dir_trace)
      cmd = [
          instruments_prefix,
          '-t', "\"#{automation_template(xctools)}\"",
          "\"#{bundle_dir_or_bundle_id}\"",
          '-e', 'UIARESULTSPATH', results_dir,
          '-e', 'UIASCRIPT', script,
          args.join(' ')
      ]
      if log_file
        cmd << "&> #{log_file}"
      end
      cmd
    end

    def self.automation_template(xctools, candidate = ENV['TRACE_TEMPLATE'])
      unless candidate && File.exist?(candidate)
        candidate = default_tracetemplate xctools
      end
      candidate
    end

    def self.default_tracetemplate(xctools=XCTools.new)
      templates = xctools.instruments :templates
      if xctools.xcode_version_gte_6?
        templates.delete_if do |name|
          not name =~ /\/Automation/
        end.first
      else
        templates.delete_if do |path|
          not path =~ /\/Automation.tracetemplate/
        end.delete_if do |path|
          not path =~ /Xcode/
        end.first.tr("\"", '').strip
      end
    end

    def self.log(message)
      if ENV['DEBUG']=='1'
        puts "#{Time.now } #{message}"
        $stdout.flush
      end
    end

    def self.log_header(message)
      if ENV['DEBUG']=='1'
        puts "\n\e[#{35}m### #{message} ###\e[0m"
        $stdout.flush
      end
    end

    def self.ensure_instruments_not_running!
      instruments_pids.each do |pid|
        if ENV['DEBUG']=='1'
          puts "Found instruments #{pid}. Killing..."
        end
        `kill -9 #{pid} && wait #{pid} &> /dev/null`
      end
    end

    def self.instruments_running?
      instruments_pids.size > 0
    end

    def self.instruments_pids
      pids_str = `ps x -o pid,command | grep -v grep | grep "instruments" | awk '{printf "%s,", $1}'`.strip
      pids_str.split(',').map { |pid| pid.to_i }
    end

    # @todo This is a WIP
    # @todo Needs rspec test
    def self.ensure_lldb_not_running
      descripts = `xcrun ps x -o pid,command | grep "lldb" | grep -v grep`.strip.split("\n")
      descripts.each do |process_desc|
        pid = process_desc.split(' ').first
        Open3.popen3("xcrun kill -9 #{pid} && xcrun wait #{pid}") do |_, stdout, stderr, _|
          out = stdout.read.strip
          err = stderr.read.strip
          next if out.to_s.empty? and err.to_s.empty?
          # there lots of 'ownership' problems trying to kill the lldb process
          #puts "kill process '#{pid}' => stdout: '#{out}' | stderr: '#{err}'"
        end
      end
    end
  end

  def self.default_script_for_uia_strategy(uia_strategy)
    case uia_strategy
      when :preferences
        Core.script_for_key(:run_loop_fast_uia)
      when :host
        Core.script_for_key(:run_loop_host)
      else
        Core.script_for_key(:run_loop_basic)
    end
  end

  def self.run(options={})
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
      else
        raise "Inconsistent state: desired script #{desired_script} has not uia_strategy"
      end
    end
    # At this point script and uia_strategy selected

    options[:script] = script
    options[:uia_strategy] = uia_strategy

    Core.run_with_options(options)
  end

  def self.send_command(run_loop, cmd, timeout=60)

    if not cmd.is_a?(String)
      raise "Illegal command #{cmd} (must be a string)"
    end


    expected_index = Core.write_request(run_loop, cmd)
    result = nil

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


    Core.pids_for_run_loop(run_loop) do |pid|
      Process.kill('TERM', pid.to_i)
    end


    FileUtils.mkdir_p(dest)

    if results_dir
      pngs = Dir.glob(File.join(results_dir, 'Run 1', '*.png'))
    else
      pngs = []
    end
    FileUtils.cp(pngs, dest) if pngs and pngs.length > 0
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

end
