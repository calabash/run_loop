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

   it "returns a unique timestamped directory" do
     timestamp = "2015-10-09_18-56-42"
     next_timestamp = "2015-10-09_18-56-43"

     expect(RunLoop::DotDir).to receive(:timestamped_dirname).and_return(timestamp)

     FileUtils.mkdir_p(File.join(dot_dir, 'results', timestamp))

     expected = File.join(dot_dir, 'results', next_timestamp)
     actual = RunLoop::DotDir.make_results_dir

     expect(actual).to be == expected
     expect(File.exist?(actual)).to be_truthy
   end

   it "on the XTC it uses a var directory" do
     expect(RunLoop::Environment).to receive(:xtc?).and_return true
     expected = "./tmp/private/var/db/run_loop-abc"
     expect(Dir).to receive(:mktmpdir).with("run_loop").and_return expected

     expect(RunLoop::DotDir.make_results_dir).to be == expected
     expect(File.exist?(expected)).to be_truthy
   end
 end

 it ".timestamped_dirname" do
   expect(Time).to receive(:now).and_return "2015-10-09 18:56:42 +0200"

   dirname = RunLoop::DotDir.send(:timestamped_dirname)
   expect(dirname).to be == "2015-10-09_18-56-42"
 end

 describe ".next_timestamped_dir" do
   let(:base_dir) { File.join(dot_dir, "results") }

   it "increments the second to find unique dirname" do
     timestamp = "2015-10-09_18-56-42"
     next_timestamp = "2015-10-09_18-56-43"

     expect(RunLoop::DotDir).to receive(:timestamped_dirname).and_return(timestamp)

     FileUtils.mkdir_p(File.join(dot_dir, "results", timestamp))

     expected = File.join(dot_dir, "results", next_timestamp)
     actual = RunLoop::DotDir.next_timestamped_dirname(base_dir)

     expect(actual).to be == expected
     expect(File.exist?(actual)).to be_falsey
   end

   it "tries 5 times to find unique timestamp then generates a UUID dir" do
     timestamp = "2015-10-09_18-56-42"

     expect(RunLoop::DotDir).to receive(:timestamped_dirname).once.and_return(timestamp)
     expect(SecureRandom).to receive(:uuid).and_return("UUID")

     first = File.join(base_dir, timestamp)
     expect(File).to receive(:exist?).with(first).and_return true

     [
       "2015-10-09_18-56-43",
       "2015-10-09_18-56-43",
       "2015-10-09_18-56-44",
       "2015-10-09_18-56-45"
     ].each do |name|
       candidate = File.join(base_dir, name)
         allow(File).to receive(:exist?).with(candidate).and_return true
     end

     expected = File.join(dot_dir, "results", "UUID")

     allow(File).to receive(:exist?).with(expected).and_call_original
     actual = RunLoop::DotDir.next_timestamped_dirname(base_dir)

     expect(actual).to be == expected
     expect(File.exist?(actual)).to be_falsey
   end
 end

 it ".logs_dir" do
   expected = File.join(dot_dir, 'logs')
   actual = RunLoop::DotDir.logs_dir

   expect(actual).to be == expected
   expect(File.exist?(actual)).to be_truthy
 end

 it ".logfile_for_rotate_results" do
   log = RunLoop::DotDir.logfile_for_rotate_results

   expect(File.exist?(log)).to be_truthy
 end

 it ".log_to_file" do
   file = File.join(RunLoop::DotDir.logs_dir, "some.log")
   message = "Hey!"

   timestamp = "2015-10-09 15:04:06 +0200"
   expect(Time).to receive(:now).and_return(timestamp)

   expected = "#{timestamp} #{message}\n"

   RunLoop::DotDir.log_to_file(file, message)

   actual = File.open(file, "r") { |log| log.read }
   expect(actual).to be == expected
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

