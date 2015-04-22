module RunLoop
  module Simctl
    class Plists

      SIMCTL_PLIST_DIR = lambda {
        dirname  = File.dirname(__FILE__)
        joined = File.join(dirname, '..', '..', '..', 'plists', 'simctl')
        File.expand_path(joined)
      }.call

      def self.uia_automation_plist
        File.join(SIMCTL_PLIST_DIR, 'com.apple.UIAutomation.plist')
      end

      def self.uia_automation_plugin_plist
        File.join(SIMCTL_PLIST_DIR, 'com.apple.UIAutomationPlugIn.plist')
      end
    end
  end
end
