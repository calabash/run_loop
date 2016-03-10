
describe RunLoop::DetectAUT::Errors do

  let(:obj) do
    Class.new do
      include RunLoop::DetectAUT::Errors
    end.new
  end

  it "#raise_xcodeproj_missing" do
    expect do
      obj.raise_xcodeproj_missing("My.xcodeproj")
    end.to raise_error RunLoop::XcodeprojMissingError
  end

  it "#raise_multiple_xcodeproj" do
    expect do
      obj.raise_multiple_xcodeproj(["My.xcodeproj", "Your.xcodeproj"])
    end.to raise_error RunLoop::MultipleXcodeprojError
  end

  it "#raise_solution_missing" do
    expect do
      obj.raise_solution_missing("My.sln")
    end.to raise_error RunLoop::SolutionMissingError
  end

  it "#raise_no_simulator_app_found" do
    expect do
      obj.raise_no_simulator_app_found(["path/a", "path/b", "path/c"], 4)
    end.to raise_error RunLoop::NoSimulatorAppFoundError
  end
end
