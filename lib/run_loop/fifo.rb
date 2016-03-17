require 'timeout'
module RunLoop
  module Fifo
    BUFFER_SIZE = 4096

    class NoReaderConfiguredError < RuntimeError
    end

    class WriteTimedOut < RuntimeError
    end

    def self.write(pipe, msg, options={})
      msg = "#{msg}\n"
      timeout = options[:timeout] || 10
      begin_at = Time.now
      begin
        open(pipe, File::WRONLY | File::NONBLOCK) do |pipe_io|
          bytes_written = 0
          bytes_to_write = msg.length
          until bytes_written >= bytes_to_write do
            begin
              wrote = pipe_io.write_nonblock msg
              bytes_written += wrote
              msg = msg[wrote..-1]
            rescue IO::WaitWritable, Errno::EINTR, Errno::EPIPE
              timeout_left = timeout - (Time.now - begin_at)
              raise WriteTimedOut if timeout_left <= 0
              IO.select nil, [pipe_io], nil, timeout_left
            end
          end
        end
      rescue Errno::ENXIO
        sleep(0.5)
        timeout_left = timeout - (Time.now - begin_at)
        raise NoReaderConfiguredError if timeout_left <= 0
        retry
      end
    end
  end
end
