require 'irb/completion'
require 'irb/ext/save-history'
require 'awesome_print'

AwesomePrint.irb!

ARGV.concat [ '--readline',
              '--prompt-mode',
              'simple']

# monkey patch for AwesomePrint + objects that implement '=='
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

# 25 entries in the list
IRB.conf[:SAVE_HISTORY] = 50

# Store results in home directory with specified file name
IRB.conf[:HISTORY_FILE] = '.irb-history'

Dir.glob('./lib/run_loop/**/*.rb').each { |file|
  print "require '#{file}'..."
  require file
  puts 'done!'
}

motd=["Let's get this done!", 'Ready to rumble.', 'Enjoy.', 'Remember to breathe.',
      'Take a deep breath.', "Isn't it time for a break?", 'Can I get you a coffee?',
      'What is a calabash anyway?', 'Smile! You are on camera!', 'Let op! Wild Rooster!',
      "Don't touch that button!", "I'm gonna take this to 11.", 'Console. Engaged.',
      'Your wish is my command.', 'This console session was created just for you.']
puts "#{motd.sample()}"
