require 'thor'

module RunLoop
  module CLI
    class ValidationError < Thor::InvocationError
    end

    class NotImplementedError < Thor::InvocationError
    end
  end
end
