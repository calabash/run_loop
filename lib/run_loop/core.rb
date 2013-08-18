require 'fileutils'
require 'tmpdir'
require 'timeout'
require 'json'

module RunLoop

  class TimeoutError < RuntimeError
  end

  module Core

    START_DELIMITER = "OUTPUT_JSON:\n"
    END_DELIMITER="\nEND_OUTPUT"

    SCRIPTS_PATH = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'scripts'))
    SCRIPTS = {
        :dismiss => "run_dismiss_location.js",
        :run_loop => "run_loop.js"
    }

    def self.scripts_path
      SCRIPTS_PATH
    end

    def self.script_for_key(key)
      if SCRIPTS[key].nil?
        return nil
      end
      File.join(scripts_path, SCRIPTS[key])
    end

    def self.run_with_options(options)

      device = options[:device] || :iphone
      udid = options[:udid]
      timeout = options[:timeout] || 30

      log_file = options[:log_path]



      results_dir = options[:results_dir] || Dir.mktmpdir("run_loop")
      results_dir_trace = File.join(results_dir, "trace")
      FileUtils.mkdir_p(results_dir_trace)

      dependencies = options[:dependencies] || []
      dependencies << File.join(scripts_path,'calabash_script_uia.js')
      dependencies.each do |dep|
        FileUtils.cp(dep, results_dir)
      end

      script = File.join(results_dir, "_run_loop.js")


      code = File.read(options[:script])
      code = code.gsub(/\$PATH/, results_dir)
      code = code.gsub(/\$MODE/, "FLUSH") unless options[:no_flush]

      repl_path = File.join(results_dir, "repl-cmd.txt")
      File.open(repl_path, "w") { |file| file.puts "0:UIALogger.logMessage('Listening for run loop commands');" }

      File.open(script, "w") { |file| file.puts code }


      bundle_dir_or_bundle_id = options[:app] || ENV['BUNDLE_ID']|| ENV['APP_BUNDLE_PATH']

      unless bundle_dir_or_bundle_id
        raise 'key :app or environment variable APP_BUNDLE_PATH or BUNDLE_ID must be specified as path to app bundle (simulator) or bundle id (device)'
      end

      if File.exist?(bundle_dir_or_bundle_id)
        #Assume simulator
        udid = nil
        plistbuddy="/usr/libexec/PlistBuddy"
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
        unless udid
          begin
            Timeout::timeout(3, TimeoutError) do
              udid = `#{File.join(scripts_path, 'udidetect')}`.chomp
            end
          rescue TimeoutError => e

          end
          unless udid
            raise "Unable to find connected device."
          end
        end

      end

      log_file ||= File.join(results_dir, 'run_loop.out')

      cmd = instruments_command(udid, results_dir_trace, bundle_dir_or_bundle_id, results_dir, script, log_file)

      pid = fork do
        log_header("Starting App: #{bundle_dir_or_bundle_id}")
        cmd_str = cmd.join(" ")
        if ENV['DEBUG']
          log(cmd_str)
        end
        exec(cmd_str)
      end

      Process.detach(pid)

      File.open(File.join(results_dir, "run_loop.pid"), "w") do |f|
        f.write pid
      end

      run_loop = {:pid => pid, :udid => udid, :app => bundle_dir_or_bundle_id, :repl_path => repl_path, :log_file => log_file, :results_dir => results_dir}

      #read_response(run_loop,0)
      begin
        Timeout::timeout(timeout, TimeoutError) do
          read_response(run_loop, 0)
        end
      rescue TimeoutError => e
        raise TimeoutError, "Time out waiting for UIAutomation run-loop to Start. \n Logfile #{log_file} \n #{File.read(log_file)}"
      end

      run_loop
    end

    def self.write_request(run_loop, cmd)
      repl_path = run_loop[:repl_path]

      cur = File.read(repl_path)

      colon = cur.index(':')

      if colon.nil?
        raise "Illegal contents of #{repl_path}: #{cur}"
      end
      index = cur[0, colon].to_i + 1


      tmp_cmd = File.join(File.dirname(repl_path), '__repl-cmd.txt')
      File.open(tmp_cmd, "w") do |f|
        f.write("#{index}:#{cmd}")
        if ENV['DEBUG']
          puts "Wrote: #{index}:#{cmd}"
        end
      end

      FileUtils.mv(tmp_cmd, repl_path)
      index
    end

    def self.read_response(run_loop, expected_index)
      log_file = run_loop[:log_file]
      initial_offset = run_loop[:initial_offset] || 0
      offset = initial_offset

      result = nil
      loop do
        unless File.exist?(log_file) && File.size?(log_file)
          sleep(0.5)
          next
        end

        size = File.size(log_file)
        output = File.read(log_file, size-offset, offset)
        index_if_found = output.index(START_DELIMITER)
        if ENV['DEBUG_READ']=='1'
          puts output.gsub("*", '')
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

      pids_str = `ps x -o pid,command | grep -v grep | grep "#{instruments_prefix}" | awk '{printf "%s,", $1}'`
      pids = pids_str.split(",").map { |pid| pid.to_i }
      if block_given?
        pids.each do |pid|
          block.call(pid)
        end
      else
        pids
      end
    end

    def self.instruments_command_prefix(udid,results_dir_trace)
      instruments_path = 'instruments'
      if udid
        instruments_path = "#{instruments_path} -w #{udid}"
      end
      instruments_path << " -D \"#{results_dir_trace}\""
      instruments_path
    end


    def self.instruments_command(udid, results_dir_trace, bundle_dir_or_bundle_id, results_dir, script, log_file)
      instruments_prefix = instruments_command_prefix(udid, results_dir_trace)
      cmd = [
          instruments_prefix,
          "-t", automation_template,
          "\"#{bundle_dir_or_bundle_id}\"",
          "-e", "UIARESULTSPATH", results_dir,
          "-e", "UIASCRIPT", script
      ]
      if log_file
        cmd << "&> #{log_file}"
      end
      cmd
    end

    def self.automation_template
      xcode_path = `xcode-select -print-path`.chomp
      automation_bundle = File.expand_path(File.join(xcode_path, "..", 'Applications', "Instruments.app", "Contents", "PlugIns", 'AutomationInstrument.bundle'))
      if not File.exist? automation_bundle
        automation_bundle= File.expand_path(File.join(xcode_path, "Platforms", "iPhoneOS.platform", "Developer", "Library", "Instruments", "PlugIns", "AutomationInstrument.bundle"))
        raise "Unable to find AutomationInstrument.bundle" if not File.exist? automation_bundle
      end
      File.join(automation_bundle, "Contents", "Resources", "Automation.tracetemplate")
    end

    def self.log(message)
      puts "#{Time.now } #{message}"
      $stdout.flush
    end

    def self.log_header(message)
      puts "\n\e[#{35}m### #{message} ###\e[0m"
      $stdout.flush
    end

  end

  def self.run(options={})
    script = validate_script(options)
    options[:script] = script

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

    rescue TimeoutError => e
      raise TimeoutError, "Time out waiting for UIAutomation run-loop for command #{cmd}. Waiting for index:#{expected_index}"
    end

    result
  end

  def self.stop(run_loop, out=Dir.pwd)
    return if run_loop.nil?
    results_dir = run_loop[:results_dir]
    udid = run_loop[:udid]
    instruments_prefix = Core.instruments_command_prefix(udid, results_dir)
    pid = run_loop[:pid] || IO.read(File.join(results_dir, "run_loop.pid"))
    dest = out

    Core.pids_for_run_loop(run_loop) do |pid|
      Process.kill('TERM', pid.to_i)
    end

    FileUtils.mkdir_p(dest)
    pngs = Dir.glob(File.join(results_dir, "Run 1", "*.png"))
    FileUtils.cp(pngs, dest) if pngs and pngs.length > 0
  end


  def self.validate_script(options)
    script = options[:script]
    if script
      if script.is_a?(Symbol)
        script = Core.script_for_key(script)
        unless script
          raise "Unknown script for symbol: #{options[:script]}. Options: #{Core::SCRIPTS.keys.join(', ')}"
        end
      elsif script.is_a?(String)
        unless File.exist?(script)
          raise "File does not exist: #{script}"
        end
      else
        raise "Unknown type for :script key: #{options[:script].class}"
      end
    else
      script = Core.script_for_key(:run_loop)
    end
    script
  end

end
