module RunLoop
  class Environment

    # Returns the user's Unix uid.
    # @return [Integer] The user's Unix uid as an integer.
    def self.uid
      `id -u`.strip.to_i
    end

    # Returns true if debugging is enabled.
    def self.debug?
      ENV['DEBUG'] == '1'
    end

    # Returns true if read debugging is enabled.
    def self.debug_read?
      ENV['DEBUG_READ'] == '1'
    end

    # Returns true if we are running on the XTC
    def self.xtc?
      ENV['XAMARIN_TEST_CLOUD'] == '1'
    end

    def self.trace_template
      ENV['TRACE_TEMPLATE']
    end
  end
end
