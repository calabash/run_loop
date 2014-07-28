require 'spec_helper'

describe RunLoop::Core do
  describe '.default_tracetemplate' do
    it 'should always return a template' do
      default_template = RunLoop::Core.default_tracetemplate
      expect(File.exist?(default_template)).to be true
    end

    # optional test
    #
    # requires alternative Xcode versions to be installed like this
    #
    # /Xcode/4.3.1/Xcode.app
    # < snip >
    # /Xcode/5.0.1/Xcode.app
    # < snip >
    # /Xcode/5.1.1/Xcode.app
    # < snip >
    # /Xcode/6b4/Xcode6-Beta4.app
    #
    # if no /Xcode/*/*.app are found, there is no test - lucky you. :)
    it 'should return a template for Xcode >= 5.0' do
      xcode_installs = Dir.glob('/Xcode/*/*.app/Contents/Developer').select { |elm| elm =~ /\/Xcode\/[^4]/ }
      if xcode_installs.empty?
        puts 'INFO: no alternative versions of Xcode >= 5.0 found in /Xcode directory'
      else
        xcode_installs.each do |developer_dir|
          #puts "developer dir = #{developer_dir}"
          ENV['DEVELOPER_DIR'] = developer_dir
          default_template = RunLoop::Core.default_tracetemplate
          expect(File.exist?(default_template)).to be true
        end
      end
    end
  end
end
