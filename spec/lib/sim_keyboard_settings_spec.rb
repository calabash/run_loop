describe RunLoop::SimKeyboardSettings do

  let(:keyboard_enabled) { Resources.shared.plist_with_software_keyboard(true) }
  let(:keyboard_not_enabled) { Resources.shared.plist_with_software_keyboard(false) }
  let(:sim_keyboard) {RunLoop::SimKeyboardSettings.new(RunLoop::Device.new("denis", "9.4", "udid"))}

  context "software keyboard will show" do

    context "#simulator_software_keyboard_will_show?" do
      it "returns true if Preferences.plist:AutomaticMinimizationEnabled is 0" do
        expect(sim_keyboard).to(
            receive(:simulator_preferences_plist_path).and_return(keyboard_enabled)
        )

        expect(sim_keyboard.simulator_software_keyboard_will_show?).to be == true
      end

      it "returns false if Preferences.plist:AutomaticMinimizationEnabled is not 0" do
        expect(sim_keyboard).to(
            receive(:simulator_preferences_plist_path).and_return(keyboard_not_enabled)
        )

        expect(sim_keyboard.simulator_software_keyboard_will_show?).to be == false
      end
    end

    it "#simulator_ensure_software_keyboard_will_show" do
      plist = File.join(Resources.shared.local_tmp_dir, "Preferences.plist")
      FileUtils.rm_rf(plist)
      FileUtils.cp(keyboard_not_enabled, plist)

      expect(sim_keyboard).to(
          receive(:simulator_preferences_plist_path).at_least(:once).and_return(plist)
      )

      expect(sim_keyboard.simulator_software_keyboard_will_show?).to be == false

      actual = sim_keyboard.simulator_ensure_software_keyboard_will_show
      expect(actual).to be_truthy

      expect(sim_keyboard.simulator_software_keyboard_will_show?).to be == true
    end
  end
end