module RunLoop
  # @!visibility private
  class TCC

    # @!visibility private
    PRIVACY_SERVICES = {
      :calendar => "kTCCServiceCalendar",
      :camera => "kTCCServiceCamera",
      :contacts => "kTCCServiceAddressBook",
      :microphone => "kTCCServiceMicrophone",
      :motion => "kTCCServiceMotion",
      :photos => "kTCCServicePhotos",
      :reminders => "kTCCServiceReminders",
      :twitter => "kTCCServiceTwitter"
    }

    # Returns a list of known services as keys that can be passed
    # to RunLoop::TCC.allow or RunLoop::TCC.deny.
    def self.services
      PRIVACY_SERVICES.map do |key, _|
        key
      end
    end

    # Prohibits the `device` from popping a Privacy Alert for `service`.
    #
    # Only works on iOS Simulator.
    #
    # There is a set of known services like :camera, :microphone, and :twitter,
    # but you can pass arbritary services - this may or may not have an effect
    # on your application.
    #
    # @param [String, RunLoop::Device] device
    # @param [String, RunLoop::App] app
    # @param [Array] services An array of services.  The default is to allow
    #   all services.
    #
    # @raise [ArgumentError] If device is a physical device.
    # @raise [ArgumentError] If not device with identifier can be found.
    # @raise [ArgumentError] If app is an ipa.
    # @raise [ArgumentError] If app is a path that in invalid.
    def self.allow(device, app, services = [])
      _device = self.ensure_device(device)
      _app = self.ensure_app(app)

      if services.empty?
        _services = self.services
      else
        _services = services
      end

      tcc = self.tcc(device, app)

      _services.each do |service|
        tcc.allow_service(service)
      end
      _services
    end

    # Force the `device` to pop a Privacy Alert for `service`.
    #
    # Only works on iOS Simulator.
    #
    # @param [String, RunLoop::Device] device
    # @param [String, RunLoop::App] app
    # @param [Array] services An array of services.  The default is to deny
    #   all services.
    #
    # @raise [ArgumentError] If device is a physical device.
    # @raise [ArgumentError] If not device with identifier can be found.
    # @raise [ArgumentError] If app is an ipa.
    # @raise [ArgumentError] If app is a path that in invalid.
    def self.deny(device, app, services = [])
      _device = self.ensure_device(device)
      _app = self.ensure_app(app)

      if services.empty?
        _services = self.services
      else
        _services = services
      end

      tcc = self.tcc(device, app)

      _services.each do |service|
        tcc.deny_service(service)
      end
      _services
    end

    # @!visibility private
    def initialize(device, app)
      @device = device
      @app = app

      if device.physical_device?
        raise(ArgumentError, "Managing the TCC.db only works on simulators")
      end

      if !app.is_a?(RunLoop::App)
        raise(ArgumentError, "Managing the TCC.db only works on .app (not .ipa)")
      end
    end

    # @!visibility private
    def allow_service(service)
      service_name = service_name(service)
      state = service_is_allowed(service_name)

      return true if state == true

      if state == nil
        insert_allowed(service_name, 1)
      else
        update_allowed(service_name, 1)
      end
      true
    end

    # @!visibility private
    def deny_service(service)
      service_name = service_name(service)
      state = service_is_allowed(service_name)

      # state == false; need to update prompt_count
      if state == nil
        insert_allowed(service_name, 0)
      else
        update_allowed(service_name, 0)
      end
      true
    end

    # @!visibility private
    def delete_service(service)
      service_name = service_name(service)
      state = service_is_allowed(service_name)

      return true if state.nil?
      delete_allowed(service_name)
      true
    end

    private

    # @!visibility private
    attr_reader :device, :app

    # @!visibility private
    ACCESS_COLUMNS = [
      "service",
      "client",
      "client_type",
      "allowed",
      "prompt_count"
    ]

    # @!visibility private
    def where(service)
      %Q{WHERE client="#{client}" AND service="#{service}"}
    end

    # @!visibility private
    def service_is_allowed(service)
      service_name = service_name(service)
      sql = %Q{SELECT allowed FROM access #{where(service_name)}}
      out = RunLoop::Sqlite.exec(db, sql)

      case out
      when ""
        return nil
      when "1"
        return true
      when "0"
        return false
      else
        raise RuntimeError, %Q{Expected '', '1', or '0' found: '#{out}'"}
      end
    end

    # @!visibility private
    def access_columns
      "service, client, client_type, allowed, prompt_count"
    end

    # @!visibility private
    def access_values(service, state)
      %Q{"#{service}", "#{client}", 0, #{state}, #{state}}
    end

    # @!visibility private
    def insert_allowed(service, state)
      sql = %Q{INSERT INTO access (#{access_columns}) VALUES (#{access_values(service, state)})}
      RunLoop::Sqlite.exec(db, sql)
    end

    # @!visibility private
    def update_allowed(service, state)
      sql = %Q{UPDATE access SET allowed=#{state}, prompt_count=#{state} #{where(service)}}
      RunLoop::Sqlite.exec(db, sql)
    end

    # @!visibility private
    def delete_allowed(service)
     sql = %Q{DELETE FROM access #{where(service)}}
     RunLoop::Sqlite.exec(db, sql)
    end

    # @!visibility private
    def service_name(key)
      PRIVACY_SERVICES[key] || key
    end

    # @!visibility private
    def client
      app.bundle_identifier
    end

    # @!visibility private
    def db
      device.simulator_tcc_db
    end

    # @!visibility private
    def self.tcc(device, app)
      RunLoop::TCC.new(device, app)
    end

    # @!visibility private
    def self.ensure_device(device)
      if device.is_a?(RunLoop::Device)
        simulator = device
      else
        simulator = RunLoop::Device.device_with_identifier(device)
      end

      if simulator.physical_device?
        raise ArgumentError,
          "Cannot manage Privacy Settings on physical devices"
      end

      simulator
    end

    # @!visibility private
    def self.ensure_app(app)
      if app.is_a?(RunLoop::Ipa)
        raise ArgumentError,
          "Cannot manage Privacy Settings on .ipa"
      end

      if app.is_a?(RunLoop::App)
        target = app
      else
        target = RunLoop::App.new(app)
      end
      target
    end
  end
end

