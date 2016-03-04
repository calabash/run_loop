
describe RunLoop::TCC do
  let(:app) do
   path =  Resources.shared.app_bundle_path
   RunLoop::App.new(path)
  end

  let(:device) { Resources.shared.default_simulator }
  let(:tcc) { RunLoop::TCC.new(device, app) }

  before do
    allow(RunLoop::Environment).to receive(:debug?).and_return(true)
  end

  def fetch(tcc, service)
    db = tcc.send(:db)
    service_name = tcc.send(:service_name, service)
    where = tcc.send(:where, service_name)
    sql = %Q{SELECT allowed, prompt_count FROM access #{where}}
    out = RunLoop::Sqlite.exec(db, sql)
    RunLoop::Sqlite.parse(out)
  end

  it "manages the TCC.db" do
    db = tcc.send(:db)
    RunLoop::Sqlite.exec(db, "DELETE FROM access")
    out = RunLoop::Sqlite.exec(db, "SELECT * FROM access")
    expect(out).to be == ""

    tcc.allow_service(:camera)
    expect(fetch(tcc, :camera)).to be == ["1", "1"]

    tcc.deny_service(:camera)
    expect(fetch(tcc, :camera)).to be == ["0", "0"]
  end
end

