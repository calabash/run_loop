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
 end

 it ".timestamped_dirname" do
   expect(Time).to receive(:now).and_return "2015-10-09 18:56:42 +0200"

   dirname = RunLoop::DotDir.send(:timestamped_dirname)
   expect(dirname).to be == "2015-10-09_18-56-42"
 end

 it ".logs_dir" do
   expected = File.join(dot_dir, 'logs')
   actual = RunLoop::DotDir.logs_dir

   expect(actual).to be == expected
   expect(File.exist?(actual)).to be_truthy
 end

 it '.logfile_for_rotate_results' do
   log = RunLoop::DotDir.logfile_for_rotate_results

   expect(File.exist?(log)).to be_truthy
 end

 it '.log_to_file' do
   file = File.join(RunLoop::DotDir.logs_dir, 'some.log')
   message = "Hey!"

   timestamp = "2015-10-09 15:04:06 +0200"
   expect(Time).to receive(:now).and_return(timestamp)

   expected = "#{timestamp} #{message}\n"

   RunLoop::DotDir.log_to_file(file, message)

   actual = File.open(file, "r") { |log| log.read }
   expect(actual).to be == expected
 end
end

