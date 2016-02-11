module RunLoop
  module HTTP

    # A representation of the RunLoop test server.
    # @!visibility private
    class Server
      attr_reader :endpoint

      # @param [URI] endpoint The endpoint to reach the test server.
      #   running on the device. The port should be included in the URI.
      def initialize(endpoint)
        @endpoint = endpoint
      end
    end
  end
end

