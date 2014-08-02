describe RunLoop::SimControl do

  subject(:sim_control) { RunLoop::SimControl.new }

  describe '.new' do
    it 'has xctools attr' do
      expect(sim_control.xctools).to be_a RunLoop::XCTools
    end

    it 'hash plist_buddy attr' do
      expect(sim_control.pbuddy).to be_a RunLoop::PlistBuddy
    end
  end

  describe '#sim_name' do
    it 'for Xcode >= 6.0' do
      xctools = sim_control.xctools
      expect(xctools).to receive(:xcode_version).and_return(xctools.v60)
      expect(sim_control.instance_eval { sim_name }).to be == 'iOS Simulator.app'
    end

    it 'for Xcode < 6.0' do
      xctools = sim_control.xctools
      expect(xctools).to receive(:xcode_version).and_return(xctools.v51)
      expect(sim_control.instance_eval { sim_name }).to be == 'iPhone Simulator.app'
    end
  end

  describe '#sim_app_path' do
    it 'for Xcode >= 6.0' do
      xctools = sim_control.xctools
      expect(xctools).to receive(:xcode_developer_dir).and_return('/Xcode')
      expect(xctools).to receive(:xcode_version).and_return(xctools.v60)
      expected = '/Xcode/Applications/iOS Simulator.app'
      expect(sim_control.instance_eval { sim_app_path }).to be == expected
    end

    it 'for Xcode < 6.0' do
      xctools = sim_control.xctools
      expect(xctools).to receive(:xcode_developer_dir).and_return('/Xcode')
      expect(xctools).to receive(:xcode_version).and_return(xctools.v51)
      expected = '/Xcode/Platforms/iPhoneSimulator.platform/Developer/Applications/iPhone Simulator.app'
      expect(sim_control.instance_eval { sim_app_path }).to be == expected
    end

    it 'returns a path that exists' do
      path = sim_control.instance_eval { sim_app_path }
      expect(File.exists?(path)).to be == true
    end
  end

  describe '#relaunch_sim' do

    before(:each) { RunLoop::SimControl.terminate_all_sims }

    it 'with current version of Xcode' do
      sim_control.relaunch_sim({:hide_after => true})
      expect(sim_control.sim_is_running?).to be == true
    end

    it 'with Xcode >= 5.0' do
      xcode_installs = Resources.shared.alt_xcode_install_paths
      if xcode_installs.empty?
        rspec_info_log 'no alternative versions of Xcode >= 5.0 found in /Xcode directory'
      else
        xcode_installs.each do |developer_dir|
          RunLoop::SimControl.terminate_all_sims
          ENV['DEVELOPER_DIR'] = developer_dir
          rspec_test_log "launching simulator from '#{developer_dir}'"
          local_sim_control = RunLoop::SimControl.new
          local_sim_control.relaunch_sim({:hide_after => true})
          expect(local_sim_control.sim_is_running?).to be == true
        end
      end
    end
  end


end
