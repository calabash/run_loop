module RunLoop

  # A class for interacting with the instruments command-line tool
  #
  # @note All instruments commands are run in the context of `xcrun`.
  #
  # @todo Detect Instruments.app is running and pop an alert.
  # @todo Needs tests.
  class Instruments

    # @!visibility private
    #  $ ps x -o pid,command | grep -v grep | grep instruments
    #   98081 sh -c xcrun instruments -w "43be3f89d9587e9468c24672777ff6241bd91124" < args >
    #   98082 /Xcode/6.0.1/Xcode.app/Contents/Developer/usr/bin/instruments -w < args >
    FIND_PIDS_CMD = 'ps x -o pid,comm | grep -v grep | grep instruments'

    def grep_for_instruments_pids
      ps_output = `#{FIND_PIDS_CMD}`.strip
      lines = ps_output.lines("\n").map { |line| line.strip }
      lines.map do |line|
        tokens = line.strip.split(' ').map { |token| token.strip }
        pid = tokens.fetch(0, nil)
        process = tokens.fetch(1, nil)
        if process and process[/\/usr\/bin\/instruments/, 0]
          pid.to_i
        else
          nil
        end
      end.compact
    end

    def instruments_pids(&block)
      pids = grep_for_instruments_pids
      if block_given?
        pids.each do |pid|
          block.call(pid)
        end
      else
        pids
      end
    end

    def instruments_running?
      instruments_pids.count > 0
    end

    def kill_instruments(xcode_tools = RunLoop::XCTools.new)
      kill_signal = xcode_tools.xcode_version_gte_6? ? 'QUIT' : 'TERM'
      instruments_pids do |pid|
        if ENV['DEBUG'] == '1'
          puts "Sending '#{kill_signal}' to instruments process '#{pid}'"
        end
        Process.kill(kill_signal, pid.to_i)
      end
    end
  end
end
