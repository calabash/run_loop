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

    def self.xtc?
      ENV['XAMARIN_TEST_CLOUD'] == '1'
    end
  end
end
