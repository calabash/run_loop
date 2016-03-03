
describe RunLoop::Sqlite do
  let(:xcrun) { RunLoop::Xcrun.new }
  let(:db) { Resources.shared.example_db }

  before do
    allow(RunLoop::Sqlite).to receive(:xcrun).and_return(xcrun)
  end

  describe ".exec" do
    describe "raises when" do
      it "file does not exist" do
        expect(File).to receive(:exist?).with(db).and_return(false)

        expect do
          RunLoop::Sqlite.exec(db, "")
        end.to raise_error ArgumentError, /sqlite database must exist at path/
      end

      it "sql is nil" do
        expect do
          RunLoop::Sqlite.exec(db, nil)
        end.to raise_error ArgumentError, /Sql argument must not be nil or the empty string/
      end

      it "sql is empty" do
        expect do
          RunLoop::Sqlite.exec(db, "")
        end.to raise_error ArgumentError, /Sql argument must not be nil or the empty string/
      end

      it "exit status is non-zero" do
        hash = {
          :exit_status => 1,
          :out => "Error: something happened"
        }
        expect(xcrun).to receive(:exec).and_return(hash)

        expect do
          RunLoop::Sqlite.exec(db, "some sql")
        end.to raise_error RuntimeError, /Could not complete sqlite operation/
      end

      it "exit status is nil" do
        hash = {
          :exit_status => nil,
          :out => ""
        }
        expect(xcrun).to receive(:exec).and_return(hash)

        expect do
          RunLoop::Sqlite.exec(db, "some sql")
        end.to raise_error RuntimeError, /Could not complete sqlite operation/
      end
    end

    it "select" do
      sql = "select age from person where id=0"
      actual = RunLoop::Sqlite.exec(db, sql)
      expect(actual).to be == "42"

      sql = "select id, name, age from person where id=1"
      actual = RunLoop::Sqlite.exec(db, sql)
      expect(actual).to be == "1|you|35"
    end

    it "update" do
      sql = "update person set age=36 where name=\"you\""
      actual = RunLoop::Sqlite.exec(db, sql)
      expect(actual).to be == ""

      sql = "select age from person where name=\"you\""
      actual = RunLoop::Sqlite.exec(db, sql)
      expect(actual).to be == "36"
    end

    it "delete" do
      sql = "delete from person where name=\"gnarls barkley\""
      actual = RunLoop::Sqlite.exec(db, sql)
      expect(actual).to be == ""

      sql = "select age from person where name=\"gnarls barkley\""
      actual = RunLoop::Sqlite.exec(db, sql)
      expect(actual).to be == ""
    end
  end

  describe ".parse" do
    it "returns empty array if string is nil" do
      expect(RunLoop::Sqlite.parse(nil)).to be == []
    end

    it "returns a array" do
      expect(RunLoop::Sqlite.parse("A|B|C")).to be == ["A", "B", "C"]
    end

    it "uses the delimiter if set" do
      expect(RunLoop::Sqlite.parse("A,B,C", ",")).to be == ["A", "B", "C"]
    end
  end
end

