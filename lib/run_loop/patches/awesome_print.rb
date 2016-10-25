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

module Kernel
  # Patch for BasicObject inspections.
  # https://github.com/awesome-print/awesome_print/pull/253
  def ap(object, options = {})
    if object_id
      begin
        puts object.ai(options)
      rescue NoMethodError => _
        puts "(Object doesn't support #inspect)"
      end

      object unless AwesomePrint.console?
    end
  end
end
