
require 'run_loop/cli/simctl'

describe RunLoop::CLI::Simctl do

  let(:simctl) { RunLoop::CLI::Simctl.new }
  let(:device) {
    RunLoop::Device.new('name', '8.1', '134AECE8-0DDB-4A70-AA83-1CB3BC21ACD4', 'Booted')
  }
  it '#simctl' do
    expect(simctl.simctl).to be_an_instance_of RunLoop::Simctl
  end

  describe '#booted_device' do
    it 'returns nil if there are no booted devices' do
      expect(simctl.simctl).to receive(:simulators).and_return([])
      expect(simctl.booted_device).to be == nil
    end

    it 'returns the first booted device' do
      expect(simctl.simctl).to receive(:simulators).and_return([device])
      expect(simctl.booted_device).to be == device
    end
  end

  describe '#expect_device' do
    describe 'default simulator' do
      it 'raises error if device cannot be created from default simulator' do
        expect(simctl.simctl).to receive(:simulators).and_return([])
        expect {
          simctl.expect_device({})
        }.to raise_error RunLoop::CLI::ValidationError

      end

      it 'can create a device from default simulator' do
        expect(simctl.simctl).to receive(:simulators).and_return([device])
        identifier = device.instruments_identifier
        expect(RunLoop::Core).to receive(:default_simulator).and_return(identifier)

        expect(simctl.expect_device({})).to be_a_kind_of(RunLoop::Device)
      end
    end

    describe 'when passed a UDID or instruments-ready simulator name' do
      it 'UUID' do
        expect(simctl.simctl).to receive(:simulators).and_return([device])
        options = { :device => device.udid }
        expect(simctl.expect_device(options).udid).to be == device.udid
      end

      it 'name' do
        expect(simctl.simctl).to receive(:simulators).and_return([device])
        identifier = device.instruments_identifier
        options = { :device => identifier }
        expect(simctl.expect_device(options).udid).to be == device.udid
      end

      it 'raises error error if no match can be found' do
        expect(simctl.simctl).to receive(:simulators).and_return([device])
        options = { :device => 'foobar' }
        expect {
          simctl.expect_device(options).udid
        }.to raise_error RunLoop::CLI::ValidationError
      end
    end
  end

  describe '#expect_app' do
    let(:options) {
      options = { :app => Resources.shared.cal_app_bundle_path }
    }

    it 'returns an app' do
      expect(simctl.expect_app(options, device)).to be_a_kind_of(RunLoop::App)
    end

    describe 'raises error when' do
      describe 'app bundle path' do
        it 'does not exist' do
          options = { :app => '/some/path/that/does/not/exist' }
          expect {
            simctl.expect_app(options, device)
          }.to raise_error RunLoop::CLI::ValidationError
        end

        it 'is not a directory' do
          options = {
            :app => FileUtils.touch(File.join(Dir.mktmpdir(), 'foo.txt')).first }
          expect {
            simctl.expect_app(options, device)
          }.to raise_error RunLoop::CLI::ValidationError
        end

        it 'does not have .app extension' do
          options = {
            :app => FileUtils.mkdir_p(File.join(Dir.mktmpdir(), 'foo.txt')).first }
          expect {
            simctl.expect_app(options, device)
          }.to raise_error RunLoop::CLI::ValidationError
        end
      end

      describe 'not a valid app' do
        it 'cannot find the bundle identifier' do
          expect_any_instance_of(RunLoop::App).to receive(:bundle_identifier).and_raise(RuntimeError)
          expect {
            simctl.expect_app(options, device)
          }.to raise_error RunLoop::CLI::ValidationError
        end

        it 'cannot find the executable name' do
          expect_any_instance_of(RunLoop::App).to receive(:executable_name).and_raise(RuntimeError)
          expect {
            simctl.expect_app(options, device)
          }.to raise_error RunLoop::CLI::ValidationError
        end

        it 'app has incompatible arch' do
          expect_any_instance_of(RunLoop::Lipo).to(
            receive(
              :expect_compatible_arch
            ).with(device).and_raise(RunLoop::IncompatibleArchitecture)
          )
          expect {
            simctl.expect_app(options, device)
          }.to raise_error RunLoop::CLI::ValidationError
        end
      end
    end
  end
end
