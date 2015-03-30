require 'run_loop/cli/instruments'

describe RunLoop::CLI::Instruments do

  describe 'launch' do
    describe '#parse_app_launch_args' do
      it 'if options[:args] => nil, return empty array' do
        options = {}
        expect(subject.parse_app_launch_args(options)).to be == []
      end

      it 'if options[:args] => a single item, create a one element array' do
        options = {:args => '-com.apple.CoreData.SQLDebug'}
        expect(subject.parse_app_launch_args(options)).to be == [options[:args]]
      end

      it 'if options[:args] => a csv string, convert to an array' do
        args = '-NSShowNonLocalizedStrings,YES,-AppleLanguages,(de)'
        options = {:args => args}
        expected = args.split(',')
        expect(subject.parse_app_launch_args(options)).to be == expected
      end
    end

    describe '#detect_bundle_id_or_bundle_path' do
      describe 'raises an error when' do
        it 'app is used with ipa key' do
          options = {:app => 'path/to/app',
                     :ipa => 'path/to/ipa'}
          expect {
            subject.detect_bundle_id_or_bundle_path(options)
          }.to raise_error RunLoop::CLI::ValidationError
        end

        it 'app is used with bundle id key' do
          options = {:app => 'path/to/app',
                     :bundle_id => 'com.example.YourApp'}
          expect {
            subject.detect_bundle_id_or_bundle_path(options)
          }.to raise_error RunLoop::CLI::ValidationError
        end
      end
    end

    describe '#detect_device_udid_from_options' do
      it 'returns default simulator when --app and ! --device' do
        expect(RunLoop::Core).to receive(:default_simulator).and_return('simulator')
        options = {:app => '/path/to/app',
                   :device => nil}
        expect(subject.detect_device_udid_from_options(options)).to be == 'simulator'
      end

      it 'returns device if --device is defined' do
        options = {:app => '/path/to/app',
                   :device => 'some device'}
        expect(subject.detect_device_udid_from_options(options)).to be == 'some device'
      end
    end
  end
end
