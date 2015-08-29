describe RunLoop::Instruments do

  let (:instruments) { RunLoop::Instruments.new }

  before(:each) {
    RunLoop::SimControl.terminate_all_sims
    Resources.shared.kill_fake_instruments_process
  }

  after(:each) {
    Resources.shared.kill_fake_instruments_process
  }

  describe '.new' do
    it 'creates a new RunLoop::Instruments instance' do
      expect(RunLoop::Instruments.new).to be_a RunLoop::Instruments
    end
  end

  describe '#ps_for_instruments' do
    it 'can find instruments processes' do
      cmd = 'ps x -o pid,command | grep -v grep | grep fake-instruments'
      3.times do
        Resources.shared.fork_fake_instruments_process
        sleep(0.1) if Luffa::Environment.travis_ci?
      end

      output = instruments.send(:ps_for_instruments, cmd).strip.split("\n")
      expect(output.count).to be == 3
    end
  end

  describe '#is_instruments_process?' do
    describe 'returns false when process description' do
      it 'is nil' do
        expect(instruments.send(:is_instruments_process?, nil)).to be_falsey
      end

      it 'does not match instruments regex' do
        expect(instruments.send(:is_instruments_process?, '/usr/bin/foo')).to be_falsey
        expect(instruments.send(:is_instruments_process?, 'instruments')).to be_falsey
      end

      it "starts with 'sh -c xcrun instruments'" do
        description = "sh -c xcrun instruments -w \"43be3f89d9587e9468c24672777ff6241bd91124\" < args >"
        expect(instruments.send(:is_instruments_process?, description)).to be_falsey
      end
    end

    describe 'returns true when process description' do
      it "contains '/usr/bin/instruments'" do
        description = "/Xcode/6.0.1/Xcode.app/Contents/Developer/usr/bin/instruments -w \"43be3f89d9587e9468c24672777ff6241bd91124\" < args >"
        expect(instruments.send(:is_instruments_process?, description)).to be_truthy
      end
    end
  end

  describe '#pids_from_ps_output' do
    it 'when no instruments process are running returns an empty array' do
      ps_cmd = 'ps x -o pid,command | grep -v grep | grep a-process-that-does-not-exist'
      expect(instruments.send(:pids_from_ps_output, ps_cmd).count).to be == 0
    end

    it 'can parse pids from typical ps output' do
      ps_output =
            [
                  '98081 /Xcode/6.0.1/Xcode.app/Contents/Developer/usr/bin/instruments -w < args >',
                  '98082 /Applications/Xcode.app/Contents/Developer/usr/bin/instruments -w < args >',
                  '98083 /Applications/Xcode-Beta.app/Contents/Developer/usr/bin/instruments -w < args >'
            ].join("\n")

      expect(instruments).to receive(:ps_for_instruments).and_return(ps_output)
      expected = [98081, 98082, 98083]
      actual = instruments.send(:pids_from_ps_output)
      expect(actual).to match_array expected
    end
  end

  describe '#instruments_pids' do
    it 'when no block is passed it returns a list of processes' do
      expected = [98081, 98082]
      expect(instruments).to receive(:pids_from_ps_output).and_return(expected)
      actual = instruments.instruments_pids
      expect(actual).to match_array expected
    end

    it 'when a block is passed it is applied to the processes' do
      pids = [98081, 98082]
      expect(instruments).to receive(:pids_from_ps_output).and_return(pids)
      expected = ['98081', '98082']
      collected = []
      instruments.instruments_pids do |pid|
        collected << pid.to_s
      end
      expect(collected).to match_array expected
    end
  end

  describe '#instruments_running?' do
    it 'returns false when no instruments process are found' do
      expect(instruments).to receive(:instruments_pids).and_return([])
      expect(instruments.instruments_running?).to be == false
    end

    it 'return true when instruments process are found' do
      expect(instruments).to receive(:instruments_pids).and_return([1])
      expect(instruments.instruments_running?).to be == true
    end
  end

  describe '#kill_signal' do
    it 'the current Xcode version' do
      xcode = RunLoop::Xcode.new
      expected =  xcode.version_gte_6? ? 'QUIT' : 'TERM'
      expect(instruments.send(:kill_signal, xcode)).to be == expected
    end

    describe 'regression' do
      xcode_installs = Resources.shared.alt_xcode_install_paths
      if xcode_installs.empty?
        it 'no alternative versions of Xcode found' do
          expect(true).to be == true
        end
      else
        xcode_installs.each do |developer_dir|
          it "#{developer_dir}" do
            Resources.shared.with_developer_dir(developer_dir) do
              xcode = RunLoop::Xcode.new
              expected =  xcode.version_gte_6? ? 'QUIT' : 'TERM'
              expect(instruments.send(:kill_signal, xcode)).to be == expected
            end
          end
        end
      end
    end
  end

  describe '#spawn_arguments' do
    it 'parses options argument to create an array' do
      automation_template = 'Automation'
      script = 'run_loop.js'
      trace = 'trace'
      bundle = 'MyApp.app'
      result_dir = 'result'
      args = ['-NSDoubleLocalizedStrings', 'YES']
      udid = 'iPhone 5s (8.1 Simulator)'
      launch_options =
            {
                  :app => "/Users/moody/git/run-loop/spec/resources/chou-cal.app",
                  :script => script,
                  :udid => udid,
                  :results_dir_trace => trace,
                  :bundle_dir_or_bundle_id => bundle,
                  :results_dir => result_dir,
                  :args => args
            }
      actual = instruments.send(:spawn_arguments, automation_template, launch_options)
      expected =
            [
                  'instruments',
                  '-w', udid,
                  '-D', trace,
                  '-t', automation_template,
                  bundle,
                  '-e', 'UIARESULTSPATH', result_dir,
                  '-e', 'UIASCRIPT', script,
                  args[0],
                  args[1]
            ]
      expect(actual).to be == expected
    end
  end

  it '#version' do

    output = %q(
instruments, version 7.0 (58143.1)
usage: instruments [-t template] [-D document] [-l timeLimit] [-i #] [-w device] [[-p pid] | [application [-e variable value] [argument ...]]]
)
    stderr = StringIO.new(output)
    yielded = ['', stderr, nil]
    expect(instruments).to receive(:execute_command).with([]).and_yield(*yielded)

    expected = RunLoop::Version.new('7.0')
    expect(instruments.version).to be == RunLoop::Version.new('7.0')
    expect(instruments.instance_variable_get(:@instruments_version)).to be == expected
    # Testing memoization
    expect(instruments.version).to be == expected
  end


  it '#xcode' do
    expect(RunLoop::Xcode).to receive(:new).and_return 'xcode'

    expect(instruments.xcode).to be == 'xcode'
    expect(instruments.instance_variable_get(:@xcode)).to be == 'xcode'
  end

  describe '#templates' do
    it 'Xcode < 5.1' do
      xcode = instruments.xcode
      expect(xcode).to receive(:version).at_least(:once).and_return xcode.v50

      expect do
        instruments.templates
      end.to raise_error RuntimeError, /Xcode version '5.0' is not supported./
    end

    it 'Xcode >= 6.0' do
      xcode = instruments.xcode
      expect(xcode).to receive(:version_gte_6?).at_least(:once).and_return true

      stdout = StringIO.new(RunLoop::RSpec::Instruments::TEMPLATES_GTE_60[:output])
      stderr = StringIO.new(RunLoop::RSpec::Instruments::SPAM_GTE_60)
      yielded = [stdout, stderr, nil]
      args = ['-s', 'templates']
      expect(instruments).to receive(:execute_command).with(args).and_yield(*yielded)
      expect(instruments).to receive(:filter_stderr_spam).with(stderr).and_call_original

      expected = RunLoop::RSpec::Instruments::TEMPLATES_GTE_60[:expected]
      expect(instruments.templates).to be == expected
      expect(instruments.instance_variable_get(:@instruments_templates)).to be == expected
    end

    it '5.1 <= Xcode < 6.0' do
      xcode = instruments.xcode
      expect(xcode).to receive(:version_gte_6?).at_least(:once).and_return false
      expect(xcode).to receive(:version_gte_51?).at_least(:once).and_return true

      stdout = StringIO.new(RunLoop::RSpec::Instruments::TEMPLATES_511[:output])
      stderr = StringIO.new('')

      yielded = [stdout, stderr, nil]
      args = ['-s', 'templates']
      expect(instruments).to receive(:execute_command).with(args).and_yield(*yielded)

      expected = RunLoop::RSpec::Instruments::TEMPLATES_511[:expected]
      expect(instruments.templates).to be == expected
      expect(instruments.instance_variable_get(:@instruments_templates)).to be == expected
    end
  end

  describe '#physical_devices' do
    it 'Xcode >= 7.0' do
      stdout = StringIO.new(RunLoop::RSpec::Instruments::DEVICES_GTE_70)
      stderr = StringIO.new(RunLoop::RSpec::Instruments::SPAM_GTE_60)
      yielded = [stdout, stderr, nil]
      args = ['-s', 'devices']
      expect(instruments).to receive(:execute_command).with(args).and_yield(*yielded)

      actual = instruments.physical_devices

      expect(actual.count).to be == 2
      expect(actual.first.name).to be == 'mercury'
      expect(actual.first.version).to be == RunLoop::Version.new('8.4.1')
      expect(actual.first.udid).to be == '5ddbd7cc1e0894a77811b3f41c8e5caecef3e912'
      expect(actual.first.physical_device?).to be_truthy

      expect(actual.last.name).to be == 'neptune'
      expect(actual.last.version).to be == RunLoop::Version.new('9.0')
      expect(actual.last.udid).to be == '43be3f89d9587e9468c24672777ff6211bd91124'
      expect(actual.last.physical_device?).to be_truthy

      # Testing memoization
      expect(instruments.physical_devices).to be == actual
      expect(instruments.instance_variable_get(:@instruments_physical_devices)).to be == actual
    end

    it 'Xcode < 7.0' do
      stdout = StringIO.new(RunLoop::RSpec::Instruments::DEVICES_60)
      stderr = StringIO.new(RunLoop::RSpec::Instruments::SPAM_GTE_60)
      yielded = [stdout, stderr, nil]
      args = ['-s', 'devices']
      expect(instruments).to receive(:execute_command).with(args).and_yield(*yielded)

      actual = instruments.physical_devices

      expect(actual.count).to be == 2
      expect(actual.first.name).to be == 'mercury'
      expect(actual.first.version).to be == RunLoop::Version.new('8.4.1')
      expect(actual.first.udid).to be == '5ddbd7cc1e0894a77811b3f41c8e5caecef3e912'
      expect(actual.first.physical_device?).to be_truthy

      expect(actual.last.name).to be == 'neptune'
      expect(actual.last.version).to be == RunLoop::Version.new('9.0')
      expect(actual.last.udid).to be == '43be3f89d9587e9468c24672777ff6211bd91124'
      expect(actual.last.physical_device?).to be_truthy

      # Testing memoization
      expect(instruments.physical_devices).to be == actual
      expect(instruments.instance_variable_get(:@instruments_physical_devices)).to be == actual
    end
  end

  describe '#line_is_xcode5_simulator?' do
    subject { instruments.send(:line_is_xcode5_simulator?, line) }

    context 'Xcode 7 simulator' do
      let(:line) { 'iPhone 6 (8.4) [AFD41B4D-AAB8-4FFD-A80D-7B32DE8EC01C]' }
      it { is_expected.to be_falsey }
    end

    context 'Xcode 6 simulator' do
      let(:line) { 'iPhone 6 (8.4 Simulator) [AFD41B4D-AAB8-4FFD-A80D-7B32DE8EC01C]' }
      it { is_expected.to be_falsey }
    end

    context 'Xcode 5 simulator' do
      let(:line) { 'iPad Retina - Simulator - iOS 6.1' }
      it { is_expected.to be_truthy }
    end
  end

  describe '#line_is_core_simulator?' do
    subject { instruments.send(:line_is_core_simulator?, line) }

    context 'Xcode 7 simulator' do
      let(:line) { 'iPhone 6 (8.4) [AFD41B4D-AAB8-4FFD-A80D-7B32DE8EC01C]' }
      it { is_expected.to be_truthy }
    end

    context 'Xcode 6 simulator' do
      let(:line) { 'iPhone 5 (8.4 Simulator) [72EBC8B1-E76F-48D8-9586-D179A68EB2B7]' }
      it { is_expected.to be_truthy }
    end

    context 'Simulator paired with watch' do
      let(:line) { 'iPhone 6 Plus (9.0) + Apple Watch - 42mm (2.0) [8002F486-CF21-4DA0-8CDE-17B3D054C4DE]' }
      it { is_expected.to be_truthy }
    end

    context 'Custom simulator' do
      let(:line) { 'my simulator (8.1) [6E43E3CF-25F5-41CC-A833-588F043AE749]' }
      it { is_expected.to be_truthy }
    end

    context 'Xcode 5 simulator' do
      let(:line) { 'iPad Retina - Simulator - iOS 6.1' }
      it { is_expected.to be_falsey }
    end

    describe 'Not the host machine' do
      context 'Not hostname' do
        let(:line) do
          "#{`xcrun hostname`} [4AFA48C7-5D39-54D0-9733-04301E70E235]"
        end
        it { is_expected.to be_falsey }
      end

      context 'Not uname -n' do
        let(:line) do
          "#{`xcrun uname -n`} [4AFA48C7-5D39-54D0-9733-04301E70E235]"
        end
        it { is_expected.to be_falsey }
      end
    end

    context 'Not a physical device' do
      let(:line) { 'mercury (8.4.1) [5ddbd7cc1e0894a77811b3f41c8e5caecef3e912]' }
      it { is_expected.to be_falsey }
    end
  end

  describe '#simulators' do
    it 'Xcode >= 7.0' do
      stdout = StringIO.new(RunLoop::RSpec::Instruments::DEVICES_GTE_70)
      #stderr = StringIO.new(RunLoop::RSpec::Instruments::SPAM_GTE_60)
      stderr = StringIO.new('')
      yielded = [stdout, stderr, nil]
      args = ['-s', 'devices']
      expect(instruments).to receive(:execute_command).with(args).and_yield(*yielded)

      actual = instruments.simulators

      puts actual

      expect(actual.count).to be == 11
      actual.map do |device|
        expect(device.name[/(iPhone|iPad|my simulator)/, 0]).to be_truthy
        expect(device.udid[RunLoop::Instruments::CORE_SIMULATOR_UDID_REGEX, 0]).to be_truthy
        expect(device.version).to be_a_kind_of(RunLoop::Version)
      end
    end

    it '6.0 <= Xcode < 7.0' do
      stdout = StringIO.new(RunLoop::RSpec::Instruments::DEVICES_60)
      stderr = StringIO.new(RunLoop::RSpec::Instruments::SPAM_GTE_60)
      yielded = [stdout, stderr, nil]
      args = ['-s', 'devices']
      expect(instruments).to receive(:execute_command).with(args).and_yield(*yielded)

      actual = instruments.simulators
      expect(actual.count).to be == 12
      actual.map do |device|
        expect(device.name[/(iPhone|iPad|my simulator)/, 0]).to be_truthy
        expect(device.udid[RunLoop::Instruments::CORE_SIMULATOR_UDID_REGEX, 0]).to be_truthy
        expect(device.version).to be_a_kind_of(RunLoop::Version)
      end
    end

    it '5.1.1 <= Xcode < 6.0' do
      stdout = StringIO.new(RunLoop::RSpec::Instruments::DEVICES_511)
      stderr = StringIO.new('')
      yielded = [stdout, stderr, nil]
      args = ['-s', 'devices']
      expect(instruments).to receive(:execute_command).with(args).and_yield(*yielded)

      actual = instruments.simulators
      expect(actual.count).to be == 21
      actual.map do |device|
        expect(device.name[/(iPhone|iPad)/, 0]).to be_truthy
        expect(device.udid).to be == device.name
        expect(device.version).to be_a_kind_of(RunLoop::Version)
      end
    end
  end

  describe '#line_is_simulator_paired_with_watch?' do
    subject { instruments.send(:line_is_simulator_paired_with_watch?, line) }

    context 'Xcode 7 simulator' do
      let(:line) { 'iPhone 6 (8.4) [AFD41B4D-AAB8-4FFD-A80D-7B32DE8EC01C]' }
      it { is_expected.to be_falsey }
    end

    context 'Xcode 6 simulator' do
      let(:line) { 'iPhone 5 (8.4 Simulator) [72EBC8B1-E76F-48D8-9586-D179A68EB2B7]' }
      it { is_expected.to be_falsey }
    end

    context 'Simulator paired with watch' do
      let(:line) { 'iPhone 6 Plus (9.0) + Apple Watch - 42mm (2.0) [8002F486-CF21-4DA0-8CDE-17B3D054C4DE]' }
      it { is_expected.to be_truthy }
    end
  end
end
