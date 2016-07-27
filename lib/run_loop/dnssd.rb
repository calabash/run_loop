module RunLoop

  # @!visibility private
  # This class is a work in progress.
  #
  # At the moment, it is only useful for debugging the bonjour server that is
  # started by DeviceAgent.
  #
  # This class requires the dnssd gem, but dnssd cannot be a dependency of this
  # gem because:
  #
  # 1. This gem must be useable on Linux and Windows.  dnssd is a macOS only
  #    gem.
  # 2. Adding a native extension works locally, but it requires whitelisting
  #    the run_loop gem on the Xamarin Test Cloud which is not practical.
  class DNSSD

    # @!visibility private
    def self.factory(json)
      array = JSON.parse(json, {:symbolize_names => true})
      array.map do |dns|
        RunLoop::DNSSD.new(dns[:service],
                           dns[:ip],
                           dns[:port],
                           dns[:txt])
      end
    end

    # @!visibility private
    attr_reader :service

    # @!visibility private
    attr_reader :ip

    # @!visibility private
    attr_reader :port

    # @!visibility private
    attr_reader :txt

    # @!visibility private
    def initialize(service, ip, port, txt)
      @service = service
      @ip = ip
      @port = port
      @txt = txt
    end

    # @!visibility private
    def url
      @url ||= "http://#{ip}:#{port}"
    end

    # @!visibility private
    def to_s
      "#<#{service}: #{url} TXT: #{txt}"
    end

    # @!visibility private
    def inspect
      to_s
    end

    # @!visibility private
    def ==(other)
      service == other.service
    end

    DEVICE_AGENT = "_calabus._tcp"

    def self.wait_for_new_device_agent(old, options={})
      new = self.wait_for_device_agents(options)
      new.find do |new_dns|
        !old.include?(new_dns)
      end
    end

    def self.wait_for_device_agents(options={})
      default_opts = {
        :timeout => 0.1,
        :retries => 150,
        :interval => 0.1
      }

      merged_opts = default_opts.merge(options)
      timeout = merged_opts[:timeout]
      retries = merged_opts[:retries]
      interval = merged_opts[:interval]

      start_time = Time.now

      retries.times do |try|
        time_diff = start_time + timeout - Time.now

        if time_diff <= 0
          elapsed = Time.now - start_time
          RunLoop.log_debug("Timed out waiting after #{elapsed} seconds for DeviceAgents")
          return []
        end

        agents = self.device_agents(timeout)

        if !agents.empty?
          elapsed = Time.now - start_time
          RunLoop.log_debug("Found #{agents.count} DeviceAgents after #{elapsed} seconds")
          return agents
        end

        sleep(interval)
      end
      []
    end

    def self.device_agents(timeout)
      services = []
      addresses = []
      self.browse(DEVICE_AGENT, timeout) do |reply|
        if reply.flags.add?
          services << reply
        end
        next if reply.flags.more_coming?

        services.each do |service|
          resolved = service.resolve
          addr = Socket.getaddrinfo(resolved.target, nil, Socket::AF_INET)
          addr.each do |address|
            match = addresses.find do |dns|
              dns.service == service.name
            end

            if !match
              dns = RunLoop::DNSSD.new(service.name,
                                       addr[0][2],
                                       resolved.port,
                                       resolved.text_record)
              addresses << dns
            end
          end
        end
      end
      addresses
    end

    def self.browse(type, timeout)
      begin
        require "dnssd"
      rescue LoadError => _
        raise %Q[

This class requires dnssd which cannot be a dependency of this gem.

See the comments at the top of this file:

#{File.expand_path(__FILE__)}

#{e}

]
      end
      domain = nil
      flags = 0
      interface = ::DNSSD::InterfaceAny
      service = ::DNSSD::Service.browse(type, domain, flags, interface)
      service.each(timeout) { |r| yield r }
    ensure
      service.stop if service
    end

  end
end

