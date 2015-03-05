module RunLoop
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
end
