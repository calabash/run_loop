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
      soft_keyboard_enabled = pbuddy.plist_read('SoftwareKeyboardShownByTouch', plist) != 'false'
      minimization_disabled = pbuddy.plist_read('AutomaticMinimizationEnabled', plist) != 'true'

      hw_keyboard_disabled && minimization_disabled && soft_keyboard_enabled
    end

    # Add properties needed for soft keyboard to show into preferences plist
    def ensure_soft_keyboard_will_show
      pbuddy.plist_set('HardwareKeyboardLastSeen', 'bool', false, plist)
      pbuddy.plist_set('SoftwareKeyboardShownByTouch', 'bool', true, plist)
      pbuddy.plist_set('AutomaticMinimizationEnabled', 'bool', false, plist)
    end

    # Enable/disable keyboard autocorrection
    #
    # @param [Boolean] condition, option passed by the user in launch arguments
    # default: nil(false)
    def enable_autocorrection(condition)
      pbuddy.plist_set('KeyboardAutocorrection', 'bool', condition, plist)
    end

    # Enable/disable keyboard caps lock
    #
    # @param [Boolean] condition, option passed by the user in launch arguments
    # default: nil(false)
    def enable_caps_lock(condition)
      pbuddy.plist_set('KeyboardCapsLock', 'bool', condition, plist)
    end

    # Enable/disable keyboard autocapitalization
    #
    # @param [Boolean] condition, option passed by the user in launch arguments
    # default: nil(false)
    def enable_autocapitalization(condition)
      pbuddy.plist_set('KeyboardAutocapitalization', 'bool', condition, plist)
    end

    # Checks if plist value that responds for autocorrection is set to true
    #
    # @return [Boolean]
    def autocorrection_enabled?
      pbuddy.plist_read('KeyboardAutocorrection', plist) == 'true'
    end

    # Checks if plist value that responds for caps lock is set to true
    #
    # @return [Boolean]
    def caps_lock_enabled?
      pbuddy.plist_read('KeyboardCapsLock', plist) == 'true'
    end

    # Checks if plist value that responds for autocapitalization is set to true
    #
    # @return [Boolean]
    def autocapitalization_enabled?
      pbuddy.plist_read('KeyboardAutocapitalization', plist) == 'true'
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
