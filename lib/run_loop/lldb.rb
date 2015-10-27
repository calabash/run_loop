module RunLoop

  # A class for interacting with the lldb command-line tool
  class LLDB

    # Returns a list of lldb pids.
    # @return [Array<Integer>] An array of integer pids.
    def self.lldb_pids
      ps_output = `#{LLDB_FIND_PIDS_CMD}`.strip
      lines = ps_output.lines("\n").map { |line| line.strip }
      lldb_processes = lines.select { |line| self.is_lldb_process?(line) }
      lldb_processes.map do |ps_description|
        tokens = ps_description.strip.split(' ').map { |token| token.strip }
        pid = tokens.fetch(0, nil)
        if pid.nil?
          nil
        else
          pid.to_i
        end
      end.compact.sort
    end

    # @!visibility private
    # Is the process described an lldb process?
    #
    # @param [String] ps_details Details about a process as returned by `ps`
    # @return [Boolean] True if the details describe an lldb process.
    def self.is_lldb_process?(ps_details)
      return false if ps_details.nil?
      ps_details[/Contents\/Developer\/usr\/bin\/lldb/, 0] != nil
    end

    # Attempts to gracefully kill all running lldb processes.
    def self.kill_lldb_processes
      self.lldb_pids.each do |pid|
        self.kill_with_signal(pid, 'KILL')
      end
    end

    private

    # @!visibility private
    LLDB_FIND_PIDS_CMD = 'ps x -o pid,command | grep -v grep | grep lldb'

    # @!visibility private
    def self.kill_with_signal(pid, signal)
      options = {:timeout => 1.0, :delay => 0.1}
      RunLoop::ProcessTerminator.new(pid, signal, 'lldb', options).kill_process
    end

  end
end
