module RunLoop
  module RSpec
    module Instruments
      TEMPLATES_GTE_60 = {
            :output => %q(
Known Templates:
"Activity Monitor"
"Allocations"
"Automation"
"Blank"
"Cocoa Layout"
"Core Animation"
"Core Data"
"Counters"
"Dispatch"
"Energy Diagnostics"
"File Activity"
"GPU Driver"
"Leaks"
"Network"
"OpenGL ES Analysis"
"Sudden Termination"
"System Trace"
"System Usage"
"Time Profiler"
"Zombies"
"~/Library/Application Support/Instruments/Templates/alloc-and-leaks.tracetemplate"
"~/Library/Application Support/Instruments/Templates/mem-and-cpu.tracetemplate"
"~/Library/Application Support/Instruments/Templates/memory.tracetemplate"
"~/Library/Application Support/Instruments/Templates/MyAutomation.tracetemplate"
),
            :expected => [
                  "Activity Monitor",
                  "Allocations",
                  "Automation",
                  "Blank",
                  "Cocoa Layout",
                  "Core Animation",
                  "Core Data",
                  "Counters",
                  "Dispatch",
                  "Energy Diagnostics",
                  "File Activity",
                  "GPU Driver",
                  "Leaks",
                  "Network",
                  "OpenGL ES Analysis",
                  "Sudden Termination",
                  "System Trace",
                  "System Usage",
                  "Time Profiler",
                  "Zombies",
                  "~/Library/Application Support/Instruments/Templates/alloc-and-leaks.tracetemplate",
                  "~/Library/Application Support/Instruments/Templates/mem-and-cpu.tracetemplate",
                  "~/Library/Application Support/Instruments/Templates/memory.tracetemplate",
                  "~/Library/Application Support/Instruments/Templates/MyAutomation.tracetemplate"
            ]
      }

      TEMPLATES_511 = {
            :output => %q(
Known Templates:
/Xcode/5.1.1/Xcode.app/Contents/Applications/Instruments.app/Contents/Resources/templates/Activity Monitor.tracetemplate
/Xcode/5.1.1/Xcode.app/Contents/Applications/Instruments.app/Contents/Resources/templates/Allocations.tracetemplate
/Xcode/5.1.1/Xcode.app/Contents/Applications/Instruments.app/Contents/Resources/templates/Blank.tracetemplate
/Xcode/5.1.1/Xcode.app/Contents/Applications/Instruments.app/Contents/Resources/templates/Counters.tracetemplate
/Xcode/5.1.1/Xcode.app/Contents/Applications/Instruments.app/Contents/Resources/templates/Event Profiler.tracetemplate
/Xcode/5.1.1/Xcode.app/Contents/Applications/Instruments.app/Contents/Resources/templates/Leaks.tracetemplate
/Xcode/5.1.1/Xcode.app/Contents/Applications/Instruments.app/Contents/Resources/templates/Network.tracetemplate
/Xcode/5.1.1/Xcode.app/Contents/Applications/Instruments.app/Contents/Resources/templates/System Trace.tracetemplate
/Xcode/5.1.1/Xcode.app/Contents/Applications/Instruments.app/Contents/Resources/templates/Time Profiler.tracetemplate
/Users/moody/Library/Application Support/Instruments/Templates/alloc-and-leaks.tracetemplate
/Users/moody/Library/Application Support/Instruments/Templates/mem-and-cpu.tracetemplate
/Users/moody/Library/Application Support/Instruments/Templates/memory.tracetemplate
/Users/moody/Library/Application Support/Instruments/Templates/MyAutomation.tracetemplate
/Xcode/5.1.1/Xcode.app/Contents/Applications/Instruments.app/Contents/PlugIns/AutomationInstrument.bundle/Contents/Resources/Automation.tracetemplate
/Xcode/5.1.1/Xcode.app/Contents/Applications/Instruments.app/Contents/PlugIns/OpenGLESAnalyzerInstrument.bundle/Contents/Resources/OpenGL ES Analysis.tracetemplate
/Xcode/5.1.1/Xcode.app/Contents/Applications/Instruments.app/Contents/PlugIns/XRMobileDeviceDiscoveryPlugIn.bundle/Contents/Resources/Energy Diagnostics.tracetemplate
/Xcode/5.1.1/Xcode.app/Contents/Applications/Instruments.app/Contents/PlugIns/XRMobileDeviceDiscoveryPlugIn.bundle/Contents/Resources/OpenGL ES Driver.tracetemplate
/Xcode/5.1.1/Xcode.app/Contents/Applications/Instruments.app/Contents/PlugIns/XRMobileDeviceDiscoveryPlugIn.bundle/Contents/Resources/templates/Core Animation.tracetemplate
/Xcode/5.1.1/Xcode.app/Contents/Applications/Instruments.app/Contents/PlugIns/XRMobileDeviceDiscoveryPlugIn.bundle/Contents/Resources/templates/System Usage.tracetemplate
/Xcode/5.1.1/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Instruments/PlugIns/CoreData/Core Data.tracetemplate
/Xcode/5.1.1/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Instruments/PlugIns/templates/Cocoa Layout.tracetemplate
/Xcode/5.1.1/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Instruments/PlugIns/templates/Dispatch.tracetemplate
/Xcode/5.1.1/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Instruments/PlugIns/templates/File Activity.tracetemplate
/Xcode/5.1.1/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Instruments/PlugIns/templates/GC Monitor.tracetemplate
/Xcode/5.1.1/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Instruments/PlugIns/templates/Multicore.tracetemplate
/Xcode/5.1.1/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Instruments/PlugIns/templates/Sudden Termination.tracetemplate
/Xcode/5.1.1/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Instruments/PlugIns/templates/UI Recorder.tracetemplate
/Xcode/5.1.1/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Instruments/PlugIns/templates/Zombies.tracetemplate
),
            :expected => [
                  "/Xcode/5.1.1/Xcode.app/Contents/Applications/Instruments.app/Contents/Resources/templates/Activity Monitor.tracetemplate",
                  "/Xcode/5.1.1/Xcode.app/Contents/Applications/Instruments.app/Contents/Resources/templates/Allocations.tracetemplate",
                  "/Xcode/5.1.1/Xcode.app/Contents/Applications/Instruments.app/Contents/Resources/templates/Blank.tracetemplate",
                  "/Xcode/5.1.1/Xcode.app/Contents/Applications/Instruments.app/Contents/Resources/templates/Counters.tracetemplate",
                  "/Xcode/5.1.1/Xcode.app/Contents/Applications/Instruments.app/Contents/Resources/templates/Event Profiler.tracetemplate",
                  "/Xcode/5.1.1/Xcode.app/Contents/Applications/Instruments.app/Contents/Resources/templates/Leaks.tracetemplate",
                  "/Xcode/5.1.1/Xcode.app/Contents/Applications/Instruments.app/Contents/Resources/templates/Network.tracetemplate",
                  "/Xcode/5.1.1/Xcode.app/Contents/Applications/Instruments.app/Contents/Resources/templates/System Trace.tracetemplate",
                  "/Xcode/5.1.1/Xcode.app/Contents/Applications/Instruments.app/Contents/Resources/templates/Time Profiler.tracetemplate",
                  "/Users/moody/Library/Application Support/Instruments/Templates/alloc-and-leaks.tracetemplate",
                  "/Users/moody/Library/Application Support/Instruments/Templates/mem-and-cpu.tracetemplate",
                  "/Users/moody/Library/Application Support/Instruments/Templates/memory.tracetemplate",
                  "/Users/moody/Library/Application Support/Instruments/Templates/MyAutomation.tracetemplate",
                  "/Xcode/5.1.1/Xcode.app/Contents/Applications/Instruments.app/Contents/PlugIns/AutomationInstrument.bundle/Contents/Resources/Automation.tracetemplate",
                  "/Xcode/5.1.1/Xcode.app/Contents/Applications/Instruments.app/Contents/PlugIns/OpenGLESAnalyzerInstrument.bundle/Contents/Resources/OpenGL ES Analysis.tracetemplate",
                  "/Xcode/5.1.1/Xcode.app/Contents/Applications/Instruments.app/Contents/PlugIns/XRMobileDeviceDiscoveryPlugIn.bundle/Contents/Resources/Energy Diagnostics.tracetemplate",
                  "/Xcode/5.1.1/Xcode.app/Contents/Applications/Instruments.app/Contents/PlugIns/XRMobileDeviceDiscoveryPlugIn.bundle/Contents/Resources/OpenGL ES Driver.tracetemplate",
                  "/Xcode/5.1.1/Xcode.app/Contents/Applications/Instruments.app/Contents/PlugIns/XRMobileDeviceDiscoveryPlugIn.bundle/Contents/Resources/templates/Core Animation.tracetemplate",
                  "/Xcode/5.1.1/Xcode.app/Contents/Applications/Instruments.app/Contents/PlugIns/XRMobileDeviceDiscoveryPlugIn.bundle/Contents/Resources/templates/System Usage.tracetemplate",
                  "/Xcode/5.1.1/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Instruments/PlugIns/CoreData/Core Data.tracetemplate",
                  "/Xcode/5.1.1/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Instruments/PlugIns/templates/Cocoa Layout.tracetemplate",
                  "/Xcode/5.1.1/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Instruments/PlugIns/templates/Dispatch.tracetemplate",
                  "/Xcode/5.1.1/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Instruments/PlugIns/templates/File Activity.tracetemplate",
                  "/Xcode/5.1.1/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Instruments/PlugIns/templates/GC Monitor.tracetemplate",
                  "/Xcode/5.1.1/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Instruments/PlugIns/templates/Multicore.tracetemplate",
                  "/Xcode/5.1.1/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Instruments/PlugIns/templates/Sudden Termination.tracetemplate",
                  "/Xcode/5.1.1/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Instruments/PlugIns/templates/UI Recorder.tracetemplate",
                  "/Xcode/5.1.1/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Instruments/PlugIns/templates/Zombies.tracetemplate"
            ]
      }



      SPAM_GTE_60 = %q(
instruments[98552:4623] WebKit Threading Violation - initial use of WebKit from a secondary thread.
2014-10-01 05:24:43.029 instruments[51852:5503] Connection peer refused channel request for "com.apple.instruments.server.services.launchdaemon"; channel canceled <DTXChannel: 0x7ff188f52c90>
2014-10-01 05:24:43.029 instruments[51852:5503] Connection peer refused channel request for "com.apple.instruments.server.services.device.xpccontrol"; channel canceled <DTXChannel: 0x7ff18b601180>
2014-10-01 05:24:43.029 instruments[51852:5503] Connection peer refused channel request for "com.apple.instruments.server.services.deviceinfo"; channel canceled <DTXChannel: 0x7ff18b6017a0>
2014-10-01 05:24:43.030 instruments[51852:5503] Connection peer refused channel request for "com.apple.instruments.server.services.processcontrol"; channel canceled <DTXChannel: 0x7ff188ef9bb0>
2014-10-01 05:24:43.030 instruments[51852:5503] Connection peer refused channel request for "com.apple.instruments.server.services.processcontrol.posixspawn"; channel canceled <DTXChannel: 0x7ff188efa1d0>
2014-10-01 05:24:43.030 instruments[51852:5503] Connection peer refused channel request for "com.apple.instruments.server.services.mobilenotifications"; channel canceled <DTXChannel: 0x7ff188efa7f0>
2014-10-01 05:24:43.030 instruments[51852:5503] Connection peer refused channel request for "com.apple.instruments.server.services.device.applictionListing"; channel canceled <DTXChannel: 0x7ff188efb610>
)
    end
  end
end
