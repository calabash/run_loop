module RunLoop

  # @!visibility private
  #
  # This class is required for the XTC.
  class Logging

    def self.log_info(logger, message)
      log_level :info, logger, message
    end

    def self.log_debug(logger, message)
      log_level :debug, logger, message
    end

    def self.log_header(logger, message)
      msg = "\n\e[#{35}m### #{message} ###\e[0m"
      if logger.respond_to?(:debug)
        logger.debug(msg)
      else
        debug_puts(msg)
      end
    end

    def self.log_level(level, logger, message)
      level = level.to_sym
      msg = "#{Time.now} [RunLoop:#{level}]: #{message}"
      if logger.respond_to?(level)
        logger.send(level, msg)
      else
        debug_puts(msg)
      end
    end

    def self.debug_puts(msg)
      puts msg if RunLoop::Environment.debug?
    end

  end

  # These are suitable for anything that does not need to be logged on the XTC.

  # cyan
  def self.log_unix_cmd(msg)
    if RunLoop::Environment.debug?
      puts Color.cyan("SHELL: #{msg}") if msg
    end
  end

  # blue
  def self.log_warn(msg)
    puts Color.blue("WARN: #{msg}") if msg
  end

  # magenta
  def self.log_debug(msg)
    if RunLoop::Environment.debug?
      puts Color.magenta("DEBUG: #{msg}") if msg
    end
  end

  # .log_info is already taken by the XTC logger. (>_O)
  # green
  def self.log_info2(msg)
    puts Color.green("INFO: #{msg}") if msg
  end

  # red
  def self.log_error(msg)
    puts Color.red("ERROR: #{msg}") if msg
  end

  module Color
    # @!visibility private
    def self.colorize(string, color)
      if RunLoop::Environment.windows_env?
        string
      elsif RunLoop::Environment.xtc?
        string
      else
        "\033[#{color}m#{string}\033[0m"
      end
    end

    # @!visibility private
    def self.red(string)
      colorize(string, 31)
    end

    # @!visibility private
    def self.blue(string)
      colorize(string, 34)
    end

    # @!visibility private
    def self.magenta(string)
      colorize(string, 35)
    end

    # @!visibility private
    def self.cyan(string)
      colorize(string, 36)
    end

    # @!visibility private
    def self.green(string)
      colorize(string, 32)
    end
  end
end

