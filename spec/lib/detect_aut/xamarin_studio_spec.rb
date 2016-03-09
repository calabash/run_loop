
describe RunLoop::DetectAUT::XamarinStudio do
  let(:obj) do
    Class.new do
      include RunLoop::DetectAUT::XamarinStudio
      include RunLoop::DetectAUT::Errors
    end.new
  end

  describe "#xamarin_project?" do
    it "true" do
      expect(obj).to receive(:solution_directory).and_return("")

      expect(obj.xamarin_project?).to be_truthy
    end

    it "false" do
      expect(obj).to receive(:solution_directory).and_return(nil)

      expect(obj.xamarin_project?).to be_falsey
    end
  end

  describe "#solution_directory" do
    describe "SOLUTION defined" do
      let(:path) { "path/to/MyApp.sln" }

      before do
        expect(RunLoop::Environment).to receive(:solution).and_return(path)
      end

      it "raises error if no solution does not exist" do
        expect(File).to receive(:exist?).with(path).and_return(false)

        expect do
          obj.solution_directory
        end.to raise_error RunLoop::SolutionMissingError
      end

      it "returns the directory that .sln is in" do
        expect(File).to receive(:exist?).with(path).and_return(true)

        expect(obj.solution_directory).to be == File.dirname(path)
      end
    end

    it "calls find_solution_directory" do
      expected = "path/to/directory/that/contains/solution"
      expect(RunLoop::Environment).to receive(:solution).and_return(nil)
      expect(obj).to receive(:find_solution_directory).and_return(expected)

      expect(obj.solution_directory).to be == expected
    end
  end

  describe "#find_solution_directory" do
    before do
      allow(RunLoop::Environment).to receive(:solution).and_return(nil)
    end

    let(:glob0) { "#{Dir.pwd}/*.sln" }
    let(:path0) { File.join(Dir.pwd, "MyApp.sln") }
    let(:glob1) { "#{Dir.pwd}/../*.sln" }
    let(:path1) { File.expand_path(File.join(Dir.pwd, "..", "MyApp.sln")) }

    it "solution in ./" do
      expect(Dir).to receive(:glob).with(glob0).and_return([path0])

      expected = File.dirname(path0)
      expect(obj.find_solution_directory).to be == expected
    end

    it "solution in ../" do
      expect(Dir).to receive(:glob).with(glob0).and_return([])
      expect(Dir).to receive(:glob).with(glob1).and_return([path1])

      expected = File.dirname(path1)
      expect(obj.find_solution_directory).to be == expected
    end

    it "no solutions" do
      expect(Dir).to receive(:glob).with(glob0).and_return([])
      expect(Dir).to receive(:glob).with(glob1).and_return([])

      expect(obj.find_solution_directory).to be == nil
    end
  end
end

