module RunLoop

  # A class for terminating processes and waiting for them to die.
  class ProcessTerminator

    # @!attribute [r] pid
    # The process id of the process.
    # @return [Integer] The pid.
    attr_reader :pid

    # @!attribute [r] kill_signal
    # The kill signal to send to the process. Can be a Unix signal name or an
    #   Integer.
    # @return [Integer, String] The kill signal.
    attr_reader :kill_signal

    # @!attribute [r] display_name
    # The process name to use log messages and exceptions.  Not used to find
    #   or otherwise interact with the process.
    # @return [String] The display name.
    attr_reader :display_name

    # @!attribute [r] options
    # Options to control the behavior of `kill_process`.
    # @return [Hash] A hash of options.
    attr_reader :options

    # Create a new process terminator.
    #
    # @param[String,Integer] pid The process pid.
    # @param[String, Integer] kill_signal The kill signal to send to the process.
    # @param[String] display_name The name of the process to kill. Used only
    #  in log messages and exceptions.
    # @option options [Float] :timeout (2.0) How long to wait for the process to
    #  terminate.
    # @option options [Float] :interval (0.1) The polling interval.
    # @option options [Boolean] :raise_on_no_terminate (false) Should an error
    #  be raised if process does not terminate.
    def initialize(pid, kill_signal, display_name, options={})
      @options = DEFAULT_OPTIONS.merge(options)
      @pid = pid.to_i
      @kill_signal = kill_signal
      @display_name = display_name
    end

    # Try to kill the process identified by `pid`.
    #
    # After sending  `kill_signal` to `pid`, wait for the process to terminate.
    #
    # @return [Boolean] Returns true if the process was terminated or is no
    #  longer alive.
    # @raise [SignalException] Raised on an unhandled `Process.kill` exception.
    #   Errno:ESRCH and Errno:EPERM are _handled_ exceptions; all others will
    #   be raised.
    def kill_process
      return true unless process_alive?

      begin
        RunLoop.log_debug("Sending '#{kill_signal}' to #{display_name} process '#{pid}'")
        Process.kill(kill_signal, pid.to_i)
        # Don't wait.
        # We might not own this process and a WNOHANG would be a nop.
        # Process.wait(pid, Process::WNOHANG)
      rescue Errno::ESRCH
        RunLoop.log_debug("Process with pid '#{pid}' does not exist; nothing to do.")
        # Return early; there is no need to wait if the process does not exist.
        return true
      rescue Errno::EPERM
        RunLoop.log_debug("Cannot kill process '#{pid}' with '#{kill_signal}'; not a child of this process")
      rescue SignalException => e
        raise e.message
      end
      if options[:timeout].to_f <= 0.0
        RunLoop.log_debug("Not waiting for process #{display_name} : #{pid} to terminate")
      else
        RunLoop.log_debug("Waiting for #{display_name} with pid '#{pid}' to terminate")
        wait_for_process_to_terminate
      end
    end

    # Is the process `pid` alive?
    # @return [Boolean] Returns true if the process is still alive.
    def process_alive?
      begin
        Process.kill(0, pid.to_i)
        true
      rescue Errno::ESRCH
        false
      rescue Errno::EPERM
        true
      end
    end

    private

    # @!visibility private
    # The default options for waiting on a process to terminate.
    DEFAULT_OPTIONS =
          {
                :timeout => 2.0,
                :interval => 0.1,
                :raise_on_no_terminate => false
          }

    # @!visibility private
    # The details of the process reported by `ps`.
    def ps_details
      `ps -p #{pid} -o pid,comm | grep #{pid}`.strip
    end

    # @!visibility private
    # Wait for the process to terminate by polling.
    def wait_for_process_to_terminate
      now = Time.now
      poll_until = now + options[:timeout]
      delay = options[:interval]
      has_terminated = false
      while Time.now < poll_until
        has_terminated = !process_alive?
        break if has_terminated
        sleep delay
      end

      RunLoop.log_debug("Waited for #{Time.now - now} seconds for #{display_name} with pid '#{pid}' to terminate")

      if @options[:raise_on_no_terminate] and !has_terminated
        raise "Waited #{options[:timeout]} seconds for #{display_name} (#{ps_details}) to terminate"
      end
      has_terminated
    end
  end
end
