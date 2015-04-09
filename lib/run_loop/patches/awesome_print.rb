require 'awesome_print'

# Monkey patch for AwesomePrint + objects that implement '=='.
# Available in awesome-print 1.6, but requires a cross-platform update.
module AwesomePrint
  class Formatter
    def awesome_self(object, type)
      if @options[:raw] && object.instance_variables.any?
        awesome_object(object)
      elsif object.respond_to?(:to_hash)
        awesome_hash(object.to_hash)
      else
        colorize(object.inspect.to_s, type)
      end
    end
  end
end
