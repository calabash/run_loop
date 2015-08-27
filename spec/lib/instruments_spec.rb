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
      xcode_tools = RunLoop::XCTools.new
      expected =  xcode_tools.xcode_version_gte_6? ? 'QUIT' : 'TERM'
      expect(instruments.send(:kill_signal, xcode_tools)).to be == expected
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
              xcode_tools = RunLoop::XCTools.new
              expected =  xcode_tools.xcode_version_gte_6? ? 'QUIT' : 'TERM'
              expect(instruments.send(:kill_signal, xcode_tools)).to be == expected
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

    stderr = %q(
instruments, version 7.0 (58143.1)
usage: instruments [-t template] [-D document] [-l timeLimit] [-i #] [-w device] [[-p pid] | [application [-e variable value] [argument ...]]]
)
    yielded = ['', StringIO.new(stderr), nil]
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
end
