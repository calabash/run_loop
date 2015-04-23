require 'run_loop/cli/simctl'

describe RunLoop::CLI::Simctl do

  let(:simctl) { RunLoop::CLI::Simctl.new }
  it '#sim_control' do
    expect(simctl.sim_control).to be_an_instance_of RunLoop::SimControl
  end

  describe '#booted_device' do
    it 'returns nil if there are no booted devices' do
      expect(simctl.sim_control).to receive(:simulators).and_return([])
      expect(simctl.booted_device).to be == nil
    end

    it 'returns the first booted device' do
      device = RunLoop::Device.new('name', '8.1', '134AECE8-0DDB-4A70-AA83-1CB3BC21ACD4', 'Booted')
      expect(simctl.sim_control).to receive(:simulators).and_return([device])
      expect(simctl.booted_device).to be == device
    end
  end
end
