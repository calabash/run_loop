require 'run_loop/cli/errors'

describe RunLoop::CLI::ValidationError do

  it 'can be used to raise an error' do
    expect {
      raise RunLoop::CLI::ValidationError, 'Hey!'
    }.to raise_error
  end

end

describe RunLoop::CLI::NotImplementedError do

  it 'can be used to raise an error' do
    expect {
      raise RunLoop::CLI::NotImplementedError, 'Hey!'
    }.to raise_error
  end

end
