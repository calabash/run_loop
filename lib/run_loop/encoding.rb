
module RunLoop
  module Encoding

    # Removes diacritic markers from string.
    #
    # The ruby Encoding tools cannot perform this action, they can only change
    # convert one encoding to another by substituting characters.
    #
    # In ruby 1.9.3 we would have used Iconv, but that does not exist in 2.0.
    #
    # The Encoding::Convert in 2.0 does not work on string with UTF-16 characters.
    def transliterate(string)
      require "i18n"
      locales = I18n.available_locales
      if !locales.include?(:en)
        I18n.available_locales = locales + [:en]
      end
      I18n.transliterate(string)
    end

    # Raised when a string cannot be coerced to UTF8
    class UTF8Error < RuntimeError; end

    # @!visibility private
    def ensure_command_output_utf8(string, command)
      return '' if !string

      utf8 = string.force_encoding("UTF-8").chomp

      return utf8 if utf8.valid_encoding?

      encoded = utf8.encode("UTF-8", "UTF-8",
                            invalid: :replace,
                            undef: :replace,
                            replace: "")

      return encoded if encoded.valid_encoding?

      raise UTF8Error, %Q{
Could not force UTF-8 encoding on this string:

#{string}

which is the output of this command:

#{command}

Please file an issue with a stacktrace and the text of this error.

https://github.com/calabash/run_loop/issues
      }
    end
  end
end

