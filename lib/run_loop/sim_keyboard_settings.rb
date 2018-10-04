module RunLoop
  class SimKeyboardSettings
    PLIST_KEYS = {
      hw_keyboard_seen: 'HardwareKeyboardLastSeen',
      soft_keyboard_shown: 'SoftwareKeyboardShownByTouch',
      minimization_enabled: 'AutomaticMinimizationEnabled',
      keyboard_autocorrection: 'KeyboardAutocorrection',
      keyboard_caps_lock: 'KeyboardCapsLock',
      keyboard_autocapitalization: 'KeyboardAutocapitalization'
    }.freeze

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
      hw_keyboard_disabled = pbuddy.plist_read(PLIST_KEYS[:hw_keyboard_seen], plist) != 'true'
      soft_keyboard_enabled = pbuddy.plist_read(PLIST_KEYS[:soft_keyboard_shown], plist) != 'false'
      minimization_disabled = pbuddy.plist_read(PLIST_KEYS[:minimization_enabled], plist) != 'true'

      hw_keyboard_disabled && minimization_disabled && soft_keyboard_enabled
    end

    # Add properties needed for soft keyboard to show into preferences plist
    def ensure_soft_keyboard_will_show
      pbuddy.plist_set(PLIST_KEYS[:hw_keyboard_seen], 'bool', false, plist)
      pbuddy.plist_set(PLIST_KEYS[:soft_keyboard_shown], 'bool', true, plist)
      pbuddy.plist_set(PLIST_KEYS[:minimization_enabled], 'bool', false, plist)
    end

    # Enable/disable keyboard autocorrection
    #
    # @param [Boolean] condition, option passed by the user in launch arguments. nil(false) by default
    def enable_autocorrection(condition)
      pbuddy.plist_set(PLIST_KEYS[:keyboard_autocorrection], 'bool', condition, plist)
    end

    # Enable/disable keyboard caps lock
    #
    # @param [Boolean] condition, option passed by the user in launch arguments. nil(false) by default
    def enable_caps_lock(condition)
      pbuddy.plist_set(PLIST_KEYS[:keyboard_caps_lock], 'bool', condition, plist)
    end

    # Enable/disable keyboard autocapitalization
    #
    # @param [Boolean] condition, option passed by the user in launch arguments. nil(false) by default
    def enable_autocapitalization(condition)
      pbuddy.plist_set(PLIST_KEYS[:keyboard_autocapitalization], 'bool', condition, plist)
    end

    # Checks if plist value that responds for autocorrection is set to true
    #
    # @return [Boolean]
    def autocorrection_enabled?
      pbuddy.plist_read(PLIST_KEYS[:keyboard_autocorrection], plist) == 'true'
    end

    # Checks if plist value that responds for caps lock is set to true
    #
    # @return [Boolean]
    def caps_lock_enabled?
      pbuddy.plist_read(PLIST_KEYS[:keyboard_caps_lock], plist) == 'true'
    end

    # Checks if plist value that responds for autocapitalization is set to true
    #
    # @return [Boolean]
    def autocapitalization_enabled?
      pbuddy.plist_read(PLIST_KEYS[:keyboard_autocapitalization], plist) == 'true'
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
