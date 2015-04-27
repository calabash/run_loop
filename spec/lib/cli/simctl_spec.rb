require 'run_loop/cli/simctl'

describe RunLoop::CLI::Simctl do

  let(:simctl) { RunLoop::CLI::Simctl.new }
  let(:device) {
    RunLoop::Device.new('name', '8.1', '134AECE8-0DDB-4A70-AA83-1CB3BC21ACD4', 'Booted')
  }
  it '#sim_control' do
    expect(simctl.sim_control).to be_an_instance_of RunLoop::SimControl
  end

  describe '#booted_device' do
    it 'returns nil if there are no booted devices' do
      expect(simctl.sim_control).to receive(:simulators).and_return([])
      expect(simctl.booted_device).to be == nil
    end

    it 'returns the first booted device' do
      expect(simctl.sim_control).to receive(:simulators).and_return([device])
      expect(simctl.booted_device).to be == device
    end
  end

  describe '#expect_device' do
    describe 'default simulator' do
      it 'raises error if device cannot be created from default simulator' do
        expect(simctl.sim_control).to receive(:simulators).and_return([])
        expect {
          simctl.expect_device({})
        }.to raise_error RunLoop::CLI::ValidationError

      end

      it 'can create a device from default simulator' do
        expect(simctl.sim_control).to receive(:simulators).and_return([device])
        expect(RunLoop::Core).to receive(:default_simulator).and_return(device.instruments_identifier)
        expect(simctl.expect_device({})).to be_a_kind_of( RunLoop::Device)
      end
    end

    describe 'when passed a UDID or instruments-ready simulator name' do
      it 'UUID' do
        expect(simctl.sim_control).to receive(:simulators).and_return([device])
        options = { :device => device.udid }
        expect(simctl.expect_device(options).udid).to be == device.udid
      end

      it 'name' do
        expect(simctl.sim_control).to receive(:simulators).and_return([device])
        options = { :device => device.instruments_identifier }
        expect(simctl.expect_device(options).udid).to be == device.udid
      end

      it 'raises error error if no match can be found' do
        expect(simctl.sim_control).to receive(:simulators).and_return([device])
        options = { :device => 'foobar' }
        expect {
          simctl.expect_device(options).udid
        }.to raise_error RunLoop::CLI::ValidationError
      end
    end
  end
end
