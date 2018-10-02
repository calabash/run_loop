module RunLoop
  class SimKeyboardSettings

    attr_reader :pbuddy, :device, :simulator_preferences_plist_path

    def initialize(device)
      @device = device
      @pbuddy = RunLoop::PlistBuddy.new
    end

    # Check if all the properties needed for the soft keyboard to appear are set
    # Approach to negate 'true' and 'false' was chosen in order to do not reboot sim too often
    # as this will cover the cases when the properties are not set which means that keyboard will be shown anyways
    def simulator_software_keyboard_will_show?
      plist = simulator_preferences_plist_path
      hw_keyboard_disabled = pbuddy.plist_read('HardwareKeyboardLastSeen', plist) != 'true'
      minimization_disabled = pbuddy.plist_read('AutomaticMinimizationEnabled', plist) != 'true'
      soft_keyboard_enabled = pbuddy.plist_read('SoftwareKeyboardShownByTouch', plist) != 'false'

      hw_keyboard_disabled && minimization_disabled && soft_keyboard_enabled
    end

    # Add properties needed for soft keyboard to show into preferences plist
    def simulator_ensure_software_keyboard_will_show
      plist = simulator_preferences_plist_path
      pbuddy.plist_set('HardwareKeyboardLastSeen', 'bool', 'NO', plist)
      pbuddy.plist_set('SoftwareKeyboardShownByTouch', 'bool', 'YES', plist)
      pbuddy.plist_set('AutomaticMinimizationEnabled', 'bool', 'NO', plist)
    end

    def simulator_preferences_plist_path
      return nil if device.physical_device?

      directory = File.join(device.simulator_root_dir, "data", "Library", "Preferences")
      pbuddy.ensure_plist(directory, "com.apple.Preferences.plist")
    end
  end
end