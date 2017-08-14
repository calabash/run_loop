module RunLoop
  class L10N

    # Find the localized name for a given key_code
    #
    # @example
    #  lookup_localization_name('delete.key', 'da') => 'Slet'
    #
    # @param [String] key_code the localization signifier, e.g. 'delete.key'
    # @param [String] localized_lang an iso language code returned by calabash ios server
    #
    # @return [String] the localized name
    def lookup_localization_name(key_code, localized_lang)
      lookup_table_dir = lang_dir(localized_lang)
      return nil unless lookup_table_dir

      key_name_lookup_table(lookup_table_dir)[key_code]
    end

    UIKIT_AXBUNDLE_PATH_CORE_SIM = 'Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/AccessibilityBundles/UIKit.axbundle/'
    UIKIT_AXBUNDLE_PATH_CORE_SIM_XCODE_9 = "Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot/System/Library/AccessibilityBundles/UIKit.axbundle"

    LANG_CODE_TO_LANG_NAME_MAP = {
          'en' => 'English',
          'nl' => 'Dutch',
          'fr' => 'French',
          'de' => 'German',
          'es' => 'Spanish',
          'it' => 'Italian',
          'jp' => 'Japanese'
    }

    # @!visibility private
    def to_s
      "#<L10N #{uikit_bundle_l10n_path}>"
    end

    # @!visibility private
    def inspect
      to_s
    end

    # maps the ios keyboard localization to a language directory where we can
    # find a key-code -> localized-label mapping
    def lang_dir(localized_lang)
      l10n_path = uikit_bundle_l10n_path

      ## 2 char + _ + sub localization
      # en_GB.lproj
      lang_dir_name = "#{localized_lang}.lproj".sub('-','_')
      if File.exists?(File.join(l10n_path, lang_dir_name))
        return lang_dir_name
      end

      # 2 char iso language code
      # vi.lproj
      two_char_country_code = localized_lang.split('-')[0]
      lang_dir_name = "#{two_char_country_code}.lproj"
      if File.exists?(File.join(l10n_path, lang_dir_name))
        return lang_dir_name
      end

      # Full name
      # e.g. Dutch.lproj
      lang_dir_name = "#{LANG_CODE_TO_LANG_NAME_MAP[two_char_country_code]}.lproj"
      if is_full_name?(two_char_country_code) &&
            File.exists?(File.join(l10n_path, lang_dir_name))
        return lang_dir_name
      end
      nil
    end

    def uikit_bundle_l10n_path
      if xcode.version_gte_90?
        File.join(xcode.developer_dir, UIKIT_AXBUNDLE_PATH_CORE_SIM_XCODE_9)
      else
        File.join(xcode.developer_dir, UIKIT_AXBUNDLE_PATH_CORE_SIM)
      end
    end

    def is_full_name?(two_letter_country_code)
      LANG_CODE_TO_LANG_NAME_MAP.has_key?(two_letter_country_code)
    end

    def key_name_lookup_table(lang_dir_name)
      path = File.join(uikit_bundle_l10n_path, lang_dir_name, 'Accessibility.strings')
      JSON.parse(`plutil -convert json #{path} -o -`)
    end

    # @!visibility private
    attr_reader :xcode

    # @!visibility private
    def xcode
      @xcode ||= RunLoop::Xcode.new
    end
  end
end
