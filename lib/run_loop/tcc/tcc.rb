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
  end
end
