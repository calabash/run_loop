
describe RunLoop::TCC do

  let(:app) do
   path =  Resources.shared.app_bundle_path
   RunLoop::App.new(path)
  end

  let(:device) { Resources.shared.default_simulator }
  let(:tcc) { RunLoop::TCC.new(device, app) }

  describe "public API" do

    before do
      allow(RunLoop::TCC).to receive(:tcc).and_return(tcc)
    end

    it ".services" do
      actual = RunLoop::TCC.services
      expected = [:calendar, :camera, :contacts, :microphone, :motion, :photos, :reminders, :twitter]

      expect(actual).to be == expected
    end

    describe ".allow" do
      it "by default allows all services" do
        services = [:a, :b, :c]
        expect(RunLoop::TCC).to receive(:services).and_return(services)
        expect(tcc).to receive(:allow_service).with(:a).and_return(true)
        expect(tcc).to receive(:allow_service).with(:b).and_return(true)
        expect(tcc).to receive(:allow_service).with(:c).and_return(true)

        expect(RunLoop::TCC.allow(device, app)).to be == services
      end

      it "respects the service arg" do
        services = [:a, :b, :c]
        expect(tcc).to receive(:allow_service).with(:a).and_return(true)
        expect(tcc).to receive(:allow_service).with(:b).and_return(true)
        expect(tcc).to receive(:allow_service).with(:c).and_return(true)

        expect(RunLoop::TCC.allow(device, app, services)).to be == services
      end
    end

    describe ".deny" do
      it "by default allows all services" do
        services = [:a, :b, :c]
        expect(RunLoop::TCC).to receive(:services).and_return(services)
        expect(tcc).to receive(:deny_service).with(:a).and_return(true)
        expect(tcc).to receive(:deny_service).with(:b).and_return(true)
        expect(tcc).to receive(:deny_service).with(:c).and_return(true)

        expect(RunLoop::TCC.deny(device, app)).to be == services
      end

      it "respects the service arg" do
        services = [:a, :b, :c]
        expect(tcc).to receive(:deny_service).with(:a).and_return(true)
        expect(tcc).to receive(:deny_service).with(:b).and_return(true)
        expect(tcc).to receive(:deny_service).with(:c).and_return(true)

        expect(RunLoop::TCC.deny(device, app, services)).to be == services
      end
    end
  end

  describe ".new" do
    it "sets the device and app attributes" do
      expect(tcc.send(:device)).to be == device
      expect(tcc.instance_variable_get(:@device)).to be == device
      expect(tcc.send(:app)).to be == app
      expect(tcc.instance_variable_get(:@app)).to be == app
    end

    describe "raises error when" do
      it "device is a physical device" do
        expect(device).to receive(:physical_device?).and_return(true)

        expect do
          RunLoop::TCC.new(device, app)
        end.to raise_error ArgumentError, /Managing the TCC.db only works on simulators/
      end

      it "app is not a RunLoop::App" do
        expect(app).to receive(:is_a?).with(RunLoop::App).and_return(false)

        expect do
          RunLoop::TCC.new(device, app)
        end.to raise_error ArgumentError, /Managing the TCC.db only works on \.app/
      end
    end
  end

  describe "allow/deny/delete service" do
    let(:service) { "service" }

    describe "#allow_service" do
      it "service is already allowed" do
        expect(tcc).to receive(:service_is_allowed).with(service).and_return(true)

        expect(tcc.allow_service(service)).to be == true
      end

      it "service is not already allowed" do
        expect(tcc).to receive(:service_is_allowed).with(service).and_return(false)
        expect(tcc).to receive(:update_allowed).with(service, 1).and_return("")

        expect(tcc.allow_service(service)).to be == true
      end

      it "service row does not exist" do
        expect(tcc).to receive(:service_is_allowed).with(service).and_return(nil)
        expect(tcc).to receive(:insert_allowed).with(service, 1).and_return("")

        expect(tcc.allow_service(service)).to be == true
      end
    end

    describe "#deny_service" do
      it "service is already denied" do
        expect(tcc).to receive(:service_is_allowed).with(service).and_return(false)
        expect(tcc).to receive(:update_allowed).with(service, 0).and_return("")

        expect(tcc.deny_service(service)).to be == true
      end

      it "service is not already denied" do
        expect(tcc).to receive(:service_is_allowed).with(service).and_return(true)
        expect(tcc).to receive(:update_allowed).with(service, 0).and_return("")

        expect(tcc.deny_service(service)).to be == true
      end

      it "service row does not exist" do
        expect(tcc).to receive(:service_is_allowed).with(service).and_return(nil)
        expect(tcc).to receive(:insert_allowed).with(service, 0).and_return("")

        expect(tcc.deny_service(service)).to be == true
      end
    end

    describe "#delete_service" do
      it "service does not exist" do
        expect(tcc).to receive(:service_is_allowed).with(service).and_return(nil)

        expect(tcc.delete_service(service)).to be == true
      end

      it "service exists" do
        expect(tcc).to receive(:service_is_allowed).with(service).and_return(true, false)
        expect(tcc).to receive(:delete_allowed).twice.with(service).and_return("")

        expect(tcc.delete_service(service)).to be == true
        expect(tcc.delete_service(service)).to be == true
      end
    end
  end

  describe "sql" do
    let(:service) { "service" }
    let(:db) { device.simulator_tcc_db }
    let(:id) { app.bundle_identifier }
    let(:sql) do
      %Q{SELECT allowed FROM access WHERE client=\"#{id}\" AND service=\"#{service}\"}
    end

    describe "#service_is_allowed" do
      it "sevice is allowed" do
        expect(RunLoop::Sqlite).to receive(:exec).with(db, sql).and_return("1")

        actual = tcc.send(:service_is_allowed, service)
        expect(actual).to be == true
      end

      it "service is not allowed" do
        expect(RunLoop::Sqlite).to receive(:exec).with(db, sql).and_return("0")

        actual = tcc.send(:service_is_allowed, service)
        expect(actual).to be == false
      end

      it "service row does not exist" do
        expect(RunLoop::Sqlite).to receive(:exec).with(db, sql).and_return("")

        actual = tcc.send(:service_is_allowed, service)
        expect(actual).to be == nil
      end

      it "raises error if unknown output" do
        expect(RunLoop::Sqlite).to receive(:exec).with(db, sql).and_return("3")

        expect do
          tcc.send(:service_is_allowed, service)
        end.to raise_error RuntimeError, /Expected/
      end
    end

    it "#delete_allowed" do
      sql = %Q{DELETE FROM access WHERE client="#{id}" AND service="#{service}"}
      expect(RunLoop::Sqlite).to receive(:exec).with(db, sql).and_return("")

      expect(tcc.send(:delete_allowed, service)).to be == ""
    end

    describe "#update_allowed" do
      it "allow" do
        sql = %Q{UPDATE access SET allowed=1, prompt_count=1 WHERE client="#{id}" AND service="#{service}"}
        expect(RunLoop::Sqlite).to receive(:exec).with(db, sql).and_return("")

        expect(tcc.send(:update_allowed, service, 1)).to be == ""
      end

      it "deny" do
        sql = %Q{UPDATE access SET allowed=0, prompt_count=0 WHERE client="#{id}" AND service="#{service}"}
        expect(RunLoop::Sqlite).to receive(:exec).with(db, sql).and_return("")

        expect(tcc.send(:update_allowed, service, 0)).to be == ""
      end
    end

    describe "#insert_allowed" do
      it "allow" do
        sql = %Q{INSERT INTO access (service, client, client_type, allowed, prompt_count) VALUES ("#{service}", "#{id}", 0, 1, 1)}
        expect(RunLoop::Sqlite).to receive(:exec).with(db, sql).and_return("")

        expect(tcc.send(:insert_allowed, service, 1)).to be == ""
      end

      it "deny" do
        sql = %Q{INSERT INTO access (service, client, client_type, allowed, prompt_count) VALUES ("#{service}", "#{id}", 0, 0, 0)}
        expect(RunLoop::Sqlite).to receive(:exec).with(db, sql).and_return("")

        expect(tcc.send(:insert_allowed, service, 0)).to be == ""
      end
    end
  end

  describe "#service_name" do
    it "retrieves the name by key" do
      expect(tcc.send(:service_name, :camera)).to be == "kTCCServiceCamera"
    end

    it "uses the key as the service name" do
      expect(tcc.send(:service_name, "kTCCServiceIndustry")).to be == "kTCCServiceIndustry"
    end
  end

  it "#client" do
    bundle_id = app.bundle_identifier
    expect(tcc.send(:client)).to be == bundle_id
  end

  it "#db" do
    path = "data/Library/TCC.db"
    expect(device).to receive(:simulator_tcc_db).and_return(path)

    expect(tcc.send(:db)).to be == path
  end

  describe "#ensure_device" do
    let(:device) { RunLoop::Device.new("a", "9.2", "udid") }
    let(:id) { "id" }

    describe "raises an error when" do
      it "device is a physical device" do
         expect(device).to receive(:physical_device?).and_return(true)

         expect do
           RunLoop::TCC.send(:ensure_device, device)
         end.to raise_error ArgumentError,
         /Cannot manage Privacy Settings on physical devices/
      end

      it "no simulator can be found" do
        expect do
          RunLoop::TCC.send(:ensure_device, id)
        end.to raise_error ArgumentError,
        /Could not find a device with a UDID or name matching/
      end
    end

    describe "returns device when device is a" do
      it "RunLoop::Device simulator" do
        expect(device).to receive(:physical_device?).and_return(false)

        expect(RunLoop::TCC.send(:ensure_device, device)).to be == device
      end

      it "valid simulator identifier" do
        expect(RunLoop::Device).to receive(:device_with_identifier).with(id).and_return(device)
        expect(device).to receive(:physical_device?).and_return(false)

        expect(RunLoop::TCC.send(:ensure_device, id)).to be == device
      end
    end
  end

  describe "#ensure_app" do
    let(:path) { Resources.shared.cal_app_bundle_path }
    let(:app) { RunLoop::App.new(path) }

    describe "raises an error when" do
      it "app is a RunLoop::Ipa" do
        expect(app).to receive(:is_a?).with(RunLoop::Ipa).and_return(true)

        expect do
          RunLoop::TCC.send(:ensure_app, app)
        end.to raise_error ArgumentError,
        /Cannot manage Privacy Settings on .ipa/
      end

      it "app is a path, but it is not valid" do
        path = "path/to/invalid/my.app"

        expect do
          RunLoop::TCC.send(:ensure_app, path)
        end.to raise_error ArgumentError,
        /App does not exist at path or is not an app bundle/
      end
    end

    describe "returns an app when" do
      it "app is a RunLoop::App" do
        expect(RunLoop::TCC.send(:ensure_app, app)).to be == app
      end

      it "app is a path to a valid app bundle" do
        expect(RunLoop::App).to receive(:new).with(path).and_return(app)

        expect(RunLoop::TCC.send(:ensure_app, path)).to be == app
      end
    end
  end
end

