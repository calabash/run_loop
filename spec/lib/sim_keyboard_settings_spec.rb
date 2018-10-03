describe RunLoop::SimKeyboardSettings do
  let(:keyboard_enabled) { Resources.shared.plist_with_software_keyboard(true) }
  let(:keyboard_not_enabled) { Resources.shared.plist_with_software_keyboard(false) }
  let(:empty_plist) { Resources.shared.empty_plist }

  let(:physical) do
    RunLoop::Device.new('name', '9.4',
                        '30c4b52a41d0f6c64a44bd01ff2966f03105de1e')
  end

  let(:simulator) do
    RunLoop::Device.new('iPhone 5s', '9.4',
                        '77DA3AC3-EB3E-4B24-B899-4A20E315C318', 'Shutdown')
  end

  subject(:sim_keyboard) { RunLoop::SimKeyboardSettings.new(device) }

  describe 'software keyboard will show' do
    let(:device) { simulator }

    describe '#soft_keyboard_will_show?' do
      it 'returns true if Preferences.plist:AutomaticMinimizationEnabled/HardwareKeyboardLastSeen is false and SoftwareKeyboardShownByTouch is true' do
        expect(sim_keyboard).to(
          receive(:preferences_plist_path).and_return(keyboard_enabled)
        )

        expect(sim_keyboard.soft_keyboard_will_show?).to be true
      end

      it 'returns false if Preferences.plist:AutomaticMinimizationEnabled/HardwareKeyboardLastSeen is true and SoftwareKeyboardShownByTouch is false' do
        expect(sim_keyboard).to(
          receive(:preferences_plist_path).and_return(keyboard_not_enabled)
        )

        expect(sim_keyboard.soft_keyboard_will_show?).to be false
      end

      it 'returns true when AutomaticMinimizationEnabled/HardwareKeyboardLastSeen/SoftwareKeyboardShownByTouch are not set' do
        expect(sim_keyboard).to(
          receive(:preferences_plist_path).and_return(empty_plist)
        )

        expect(sim_keyboard.soft_keyboard_will_show?).to be true
      end
    end

    describe '#ensure_soft_keyboard_will_show' do
      it 'checks if keyboard will be shown' do
        plist = File.join(Resources.shared.local_tmp_dir, 'Preferences.plist')
        FileUtils.rm_rf(plist)
        FileUtils.cp(keyboard_not_enabled, plist)

        expect(sim_keyboard).to(
          receive(:preferences_plist_path).at_least(:once).and_return(plist)
        )

        expect(sim_keyboard.soft_keyboard_will_show?).to be false

        actual = sim_keyboard.ensure_soft_keyboard_will_show
        expect(actual).to be_truthy

        expect(sim_keyboard.soft_keyboard_will_show?).to be true
      end
    end
  end

  describe '#preferences_plist_path' do
    context 'when using a physical device' do
      let(:device) { physical }

      it 'returns nil' do
        expect(sim_keyboard.preferences_plist_path).to be nil
      end
    end

    context 'when using simulator' do
      let(:device) { simulator }

      it 'returns path to Preference.plist' do
        actual = sim_keyboard.preferences_plist_path
        expect(actual[/com.apple.Preferences.plist/]).to be_truthy
      end
    end
  end
end
