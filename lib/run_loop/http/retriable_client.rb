module RunLoop
  module HTTP
    require "httpclient"

    # An HTTP client that retries its connection on errors and can time out.
    # @!visibility private
    class RetriableClient
      attr_reader :client, :retries, :timeout, :interval

      # @!visibility private
       RETRY_ON =
        [
          # The connection, request, or response timed out
          #HTTPClient::TimeoutError,
          # The address is not found. Useful for polling.
          SocketError,
          # The proxy could not connect to the server (Android)
          #  or the server is not running (iOS)
          HTTPClient::KeepAliveDisconnected,
           # No proxy has been set up (Android)
          Errno::ECONNREFUSED,
          # The server sent a partial response
          #Errno::ECONNRESET,
          # Client sent TCP reset (RST) before server has accepted the
          #  connection requested by client.
          Errno::ECONNABORTED,
          # The foreign function call call timed out
          #Errno::ETIMEDOUT

          Errno::EHOSTUNREACH
        ]

      # @!visibility private
      HEADER =
            {
                  'Content-Type' => 'application/json;charset=utf-8'
            }

      # Creates a new retriable client.
      #
      # This initializer takes multiple options.  If the option is not
      # documented, it should be considered _private_. You use undocumented
      # options at your own risk.
      #
      # @param [RunLoop::HTTP::Server] server The server to make the HTTP request
      #  on.
      # @param [Hash] options Control the retry, timeout, and interval.
      # @option options [Number] :retries (5) How often to retry.
      # @option options [Number] :timeout (5) How long to wait for a response
      #  before timing out.
      # @option options [Number] :interval (0.5) How long to sleep between
      #  retries.
      def initialize(server, options = {})
        @server = server
        @retries = options.fetch(:retries, 5)
        @timeout = options.fetch(:timeout, 5)
        @interval = options.fetch(:interval, 0.5)

        # Call after setting the attr.
        # Yes, it is redundant to set @client, but it makes testing easier.
        @client = new_client!
      end

      # Make an HTTP get request.
      #
      # This method takes multiple options.  If the option is not documented,
      # it should be considered _private_.  You use undocumented options at
      # your own risk.
      #
      # @param [RunLoop::HTTP::Request] request The request.
      # @param [Hash] options Control the retry, timeout, and interval.
      # @option options [Number] :retries (5) How often to retry.
      # @option options [Number] :timeout (5) How long to wait for a response
      #  before timing out.
      # @option options [Number] :interval (0.5) How long to sleep between
      #  retries.
      def get(request, options={})
        request(request, :get, options)
      end

      # Make an HTTP post request.
      #
      # This method takes multiple options.  If the option is not documented,
      # it should be considered _private_.  You use undocumented options at
      # your own risk.
      #
      # @param [RunLoop::HTTP::Request] request The request.
      # @param [Hash] options Control the retry, timeout, and interval.
      # @option options [Number] :retries (5) How often to retry.
      # @option options [Number] :timeout (5) How long to wait for a response
      #  before timing out.
      # @option options [Number] :interval (0.5) How long to sleep between
      #  retries.
      def post(request, options={})
        request(request, :post, options)
      end

      # There is bug in HTTPClient so this method does work.
      # https://xamarin.atlassian.net/browse/TCFW-255
      # httpclient is unable to send a valid DELETE
      def delete(request, options={})
        request(request, :delete, options)
      end

      # Call HTTPClient#reset_all
      def reset_all!
        if @client
          @client.reset_all
          @client = nil
        end
      end

      private

      def new_client!
        reset_all!

        # Assumes ::HTTPClient has these defaults:
        # send_timeout = 120
        # There is an rspec test for this so we will know if they change.

        new_client = HTTPClient.new
        new_client.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
        new_client.connect_timeout = 15
        new_client.receive_timeout = timeout
        @client = new_client
      end

      def request(request, request_method, options={})
        retries = options.fetch(:retries, @retries)
        timeout = options.fetch(:timeout, @timeout)
        interval = options.fetch(:interval, @interval)
        header = options.fetch(:header, HEADER)

        if RunLoop::Environment.debug?
          http_options = {
            :retries => retries,
            :timeout => timeout
          }
          RunLoop.log_debug("HTTP: #{request_method} #{@server.endpoint + request.route} #{http_options}")
        end

        if !client
          raise RuntimeError, "This RetriableClient is not attached to client"
        end

        start_time = Time.now
        last_error = nil

        client.receive_timeout = timeout

        retries.times do |_|

          # Subtract the aggregate time we've spent thus far to make sure we're
          # not exceeding the request timeout across retries.
          time_diff = start_time + timeout - Time.now

          if time_diff <= 0
            raise HTTP::Error, 'Timeout exceeded'
          end

          client.receive_timeout = [time_diff, client.receive_timeout].min

          begin
            return send_request(client, request_method,
                                @server.endpoint + request.route,
                                request.params, header)
          rescue *RETRY_ON => e
            new_client!
            last_error = e
            sleep interval
          end
        end

        # We should raise helpful messages
        if last_error.is_a?(HTTPClient::KeepAliveDisconnected)
          raise HTTP::Error, "#{last_error}: It is likely your server has crashed."
        elsif last_error.is_a?(SocketError)
          raise HTTP::Error, "#{last_error}: Did your server start and is it on the same network?"
        end

        raise HTTP::Error, last_error
      end

      def send_request(client, request_method, endpoint, parameters, header)
        client.send(request_method, endpoint, parameters, header)
      end
    end
  end
end
