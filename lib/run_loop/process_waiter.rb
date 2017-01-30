module RunLoop

  # A class for waiting on processes.
  class ProcessWaiter

    require "run_loop/shell"

    include RunLoop::Shell

    attr_reader :process_name

    # Return a list of pids by matching `match_string` against the command
    # and full argument list of the command.  As the name suggests, this
    # method uses `pgrep -f`.
    #
    # @param match_string the string to match against
    # @return Array[Integer] an array of pids
    def self.pgrep_f(match_string)
      cmd = ["pgrep", "-f", match_string]
      hash = RunLoop::Shell.run_shell_command(cmd)

      out = hash[:out]
      return [] if out.nil? || out == ""

      out.split($-0).map { |pid| pid.to_i }
    end

    def initialize(process_name, options={})
      @options = DEFAULT_OPTIONS.merge(options)
      @process_name = process_name
    end

    # Collect a list of Integer pids.
    # @return [Array<Integer>] An array of integer pids for the `process_name`
    def pids
      cmd = ["pgrep", "-x", process_name]
      hash = run_shell_command(cmd)
      out = hash[:out]

      if out.nil? || out == ""
        []
      else
        out.split($-0).map do |pid|
          if pid.nil? || pid == ""
            nil
          else
            pid.to_i
          end
        end.compact
      end
    end

    # Is the `process_name` a running?
    def running_process?
      !pids.empty?
    end

    # Wait for a number of process to start.
    # @param [Integer] n The number of processes to wait for.
    # @raise [ArgumentError] If n < 0
    # @raise [ArgumentError] If n is not an Integer
    def wait_for_n(n)
      unless n.is_a?(Integer)
        raise ArgumentError, "Expected #{n.class} to be #{1.class}"
      end

      unless n > 0
        raise ArgumentError, "Expected #{n} to be > 0"
      end

      return true if pids.count == n

      now = Time.now
      poll_until = now + @options[:timeout]
      delay = @options[:interval]
      there_are_n = false
      while Time.now < poll_until
        there_are_n = pids.count == n
        break if there_are_n
        sleep delay
      end

      plural = n > 1 ? "es" : ''
      RunLoop.log_debug("Waited for #{Time.now - now} seconds for #{n} '#{process_name}' process#{plural} to start.")

      if @options[:raise_on_timeout] and !there_are_n
        plural = n > 1 ? "es" : ''
        raise "Waited #{@options[:timeout]} seconds for #{n} '#{process_name}' process#{plural} to start."
      end
      there_are_n
    end

    # Wait for `process_name` to start.
    def wait_for_any
      return true if running_process?

      now = Time.now
      poll_until = now + @options[:timeout]
      delay = @options[:interval]
      is_alive = false
      while Time.now < poll_until
        is_alive = running_process?
        break if is_alive
        sleep delay
      end

      RunLoop.log_debug("Waited for #{Time.now - now} seconds for '#{process_name}' to start.")

      if @options[:raise_on_timeout] and !is_alive
        raise "Waited #{@options[:timeout]} seconds for '#{process_name}' to start."
      end
      is_alive
    end

    # Wait for all `process_name` to finish.
    def wait_for_none
      return true if !running_process?

      now = Time.now
      poll_until = now + @options[:timeout]
      delay = @options[:interval]
      has_terminated = false
      while Time.now < poll_until
        has_terminated = !self.running_process?
        break if has_terminated
        sleep delay
      end

      RunLoop.log_debug("Waited for #{Time.now - now} seconds for '#{process_name}' to die.")

      if @options[:raise_on_timeout] and !has_terminated
        raise "Waited #{@options[:timeout]} seconds for '#{process_name}' to die."
      end
      has_terminated
    end

    private

    # @!visibility private
    DEFAULT_OPTIONS =
          {
                :timeout => 10.0,
                :interval => 0.1,
                :raise_on_timeout => false
          }
  end
end

