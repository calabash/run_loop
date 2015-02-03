module RunLoop
  class Environment

    # Returns the user's Unix uid.
    # @return [Integer] The user's Unix uid as an integer.
    def self.uid
      `id -u`.strip.to_i
    end

  end
end
