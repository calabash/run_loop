describe RunLoop::DotDir do

  let(:home_dir) { "./tmp/dot-run-loop-examples" }
  let(:dot_dir) { File.join(home_dir, ".run-loop") }

  before do
    allow(RunLoop::Environment).to receive(:user_home_directory).and_return home_dir
    FileUtils.rm_rf(home_dir)
  end

  it ".directory" do
    path = RunLoop::DotDir.directory

    expect(File.exist?(path)).to be_truthy
  end

  describe ".make_results_dir" do
    it "returns a timestamped directory" do
      timestamp = "2015-10-09_18-56-42"
      expect(RunLoop::DotDir).to receive(:timestamped_dirname).and_return timestamp

      expected = File.join(dot_dir, 'results', timestamp)
      actual = RunLoop::DotDir.make_results_dir

      expect(actual).to be == expected
      expect(File.exist?(actual)).to be_truthy
    end

    it "on the XTC it uses a var directory" do
      expect(RunLoop::Environment).to receive(:xtc?).and_return true

      expected = "./tmp/private/var/db/run_loop-abc"
      expect(Dir).to receive(:mktmpdir).with("run_loop").and_return expected

      expect(RunLoop::DotDir.make_results_dir).to be == expected

      # Because we are stubbing .mktmpdir, the directory is not created.
      # expect(File.exist?(expected)).to be_truthy
    end
  end

  describe ".timestamped_dirname" do
    let(:now) { Time.now }
    let(:future) { now + 1 }

    it "returns a human readable timestamp" do
      expected = now.strftime("%Y-%m-%d_%H-%M-%S")
      expect(Time).to receive(:now).and_return(now)

      dirname = RunLoop::DotDir.send(:timestamped_dirname)
      expect(dirname).to be == expected
    end

    it "adds seconds based on the argument" do
      expected = future.strftime("%Y-%m-%d_%H-%M-%S")
      expect(Time).to receive(:now).and_return(now)

      dirname = RunLoop::DotDir.send(:timestamped_dirname, 1)
      expect(dirname).to be == expected
    end
  end

  describe ".next_timestamped_dir" do
    let(:base_dir) { File.join(dot_dir, "results") }

    it "increments the second to find unique dirname" do
      timestamp = "2015-10-09_18-56-42"
      next_timestamp = "2015-10-09_18-56-43"
      FileUtils.mkdir_p(File.join(dot_dir, "results", timestamp))

      expect(RunLoop::DotDir).to receive(:timestamped_dirname).once.and_return(timestamp)
      expect(RunLoop::DotDir).to receive(:timestamped_dirname).with(1).once.and_return(next_timestamp)

      expected = File.join(dot_dir, "results", next_timestamp)
      actual = RunLoop::DotDir.next_timestamped_dirname(base_dir)

      expect(actual).to be == expected
      expect(File.exist?(actual)).to be_falsey
    end

    it "tries 5 times to find unique timestamp then generates a UUID dir" do
      values = [
        "2015-10-09_18-56-42",
        "2015-10-09_18-56-43",
        "2015-10-09_18-56-44",
        "2015-10-09_18-56-45",
        "2015-10-09_18-56-46"
      ]

      expect(RunLoop::DotDir).to receive(:timestamped_dirname).and_return(*values)

      values.each do |name|
        FileUtils.mkdir_p(File.join(dot_dir, "results", name))
      end

      expect(SecureRandom).to receive(:uuid).and_return("UUID")
      expected = File.join(dot_dir, "results", "UUID")

      actual = RunLoop::DotDir.next_timestamped_dirname(base_dir)

      expect(actual).to be == expected
      expect(File.exist?(actual)).to be_falsey
    end
  end

  describe ".rotate_result_directories" do
    let(:generator) do
      Class.new do
        def initialize(dot_dir)
          @dot_dir = dot_dir
        end

        def generate(n)
          FileUtils.rm_rf(File.join(@dot_dir, "results"))
          generated = []

          n.times do
            file = File.join(@dot_dir, "results", SecureRandom.uuid)
            FileUtils.mkdir_p(file)
            generated << file
          end
          generated
        end
      end.new(dot_dir)
    end

    it "leaves 5 most recent results" do
      generated = generator.generate(10)

      counter = 1
      generated.each do |dir|
        new_time =  Time.now + counter
        expect(File).to receive(:mtime).with(dir).at_least(:once).and_return(new_time)
        counter = counter + 1
      end

      generated.shift(5)

      RunLoop::DotDir.rotate_result_directories

      actual = Dir.glob("#{dot_dir}/results/*").select do |entry|
        !(entry.end_with?('..') || entry.end_with?('.'))
      end.sort_by { |f| File.mtime(f) }

      expect(actual).to be == generated
    end

    it "does nothing on the XTC" do
      expect(RunLoop::Environment).to receive(:xtc?).and_return true

      expect(RunLoop::DotDir.rotate_result_directories).to be == :xtc
    end
  end
end

