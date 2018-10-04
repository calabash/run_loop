module RunLoop
  class SimKeyboardSettings
    attr_reader :pbuddy, :device, :plist

    def initialize(device)
      @device = device
      @pbuddy = RunLoop::PlistBuddy.new
    end

    # Check if all the properties needed for the soft keyboard to appear are set
    # Approach to negate 'true' and 'false' was chosen in order to do not
    # reboot sim too often, as this will cover the cases when the properties
    # are not set which means that keyboard will be shown anyways
    #
    # @return [Bool]
    def soft_keyboard_will_show?
      hw_keyboard_disabled = pbuddy.plist_read('HardwareKeyboardLastSeen', plist) != 'true'
      minimization_disabled = pbuddy.plist_read('AutomaticMinimizationEnabled', plist) != 'true'
      soft_keyboard_enabled = pbuddy.plist_read('SoftwareKeyboardShownByTouch', plist) != 'false'

      hw_keyboard_disabled && minimization_disabled && soft_keyboard_enabled
    end

    # Add properties needed for soft keyboard to show into preferences plist
    def ensure_soft_keyboard_will_show
      pbuddy.plist_set('HardwareKeyboardLastSeen', 'bool', 'NO', plist)
      pbuddy.plist_set('SoftwareKeyboardShownByTouch', 'bool', true, plist)
      pbuddy.plist_set('AutomaticMinimizationEnabled', 'bool', 'NO', plist)
    end

    # Get plist path or use existing one
    #
    # @return [String] plist path
    def plist
      @plist ||= preferences_plist_path
    end

    # Get preferences plist path
    #
    # @return nil if doesn't run against simulator
    # @return [String] with path to the plist
    def preferences_plist_path
      return nil if device.physical_device?

      directory = File.join(device.simulator_root_dir, 'data', 'Library', 'Preferences')
      pbuddy.ensure_plist(directory, 'com.apple.Preferences.plist')
    end
  end
end
