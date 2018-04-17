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

      DEVICES_GTE_70 = %q(
Known Devices:
stern [4AFA48C7-5D39-54D0-9733-04301E70E235]
(null) [548929865d9d3f151f6f371c7c311e5160987abd]
mercury (8.4.1) [5ddbd7cc1e0894a77811b3f41c8e5caecef3e912]
neptune (9.0) [43be3f89d9587e9468c24672777ff6211bd91124]
Apple TV 1080p (9.0) [7F01721F-B916-4608-8DCB-4AB164D48A1A]
iPad 2 (9.0) [492F53BE-4E57-4294-AE8D-FE1CD68843E5]
iPad Air (8.4) [643BAA7B-2DA9-4E13-9B0E-858650B25141]
iPad Air 2 (9.0) [C4119171-BB51-46BD-A870-738A828679CF]
iPad Retina (8.1) [C6163436-8B6C-4ED4-831A-C98956F99DA3]
iPhone 4s (8.2) [C8A0303D-9C0A-4442-B461-0059915BEB40]
iPhone 5 (9.0) [C7342EDF-4B29-41CE-9B8B-96DA5F4815F6]
iPhone 5s (8.2) [7D828A9B-8635-4739-9AB4-A752FCAA8B4A]
iPhone 6 (9.0) [3EDC9C6E-3096-48BF-BCEC-7A5CAF8AA706]
iPhone 6 (9.0) + Apple Watch - 38mm (2.0) [EE3C200C-69BA-4816-A087-0457C5FCEDA0]
iPhone 6 Plus (8.4) [B04685D3-FBA0-45FF-B4B0-C3162A77F90B]
iPhone 6 Plus (9.0) [87354E70-0645-4A50-B2A3-84C664089358]
iPhone 6 Plus (9.0) + Apple Watch - 42mm (2.0) [8002F486-CF21-4DA0-8CDE-17B3D054C4DE]
my simulator (8.1) [6E43E3CF-25F5-41CC-A833-588F043AE749]
)

      DEVICES_60 = %q(
Known Devices:
stern [4AFA48C7-5D39-54D0-9733-04301E70E235]
mercury (8.4.1) [5ddbd7cc1e0894a77811b3f41c8e5caecef3e912]
neptune (9.0) [43be3f89d9587e9468c24672777ff6211bd91124]
Resizable iPad (8.1 Simulator) [77DA3AC3-EB3E-4B24-B899-4A20E315C318]
iPad 2 (7.1 Simulator) [4BAD3291-C79C-492E-9B4E-A6738A944A54]
iPad Air (7.1 Simulator) [4FD0301D-B37F-4B55-8642-B92751DA2014]
iPad Air (8.4 Simulator) [643BAA7B-2DA9-4E13-9B0E-858650B25141]
iPad Retina (8.3 Simulator) [EA79555F-ADB4-4D75-930C-A745EAC8FA8B]
iPhone 4s (8.1 Simulator) [24B4E07E-AEBF-48E5-8DF7-D9BAFEFF10AF]
iPhone 5 (8.4 Simulator) [72EBC8B1-E76F-48D8-9586-D179A68EB2B7]
iPhone 5s (7.1 Simulator) [37C0F5F5-EF11-4404-A86D-3E53E306AE22]
iPhone 5s (8.2 Simulator) [7D828A9B-8635-4739-9AB4-A752FCAA8B4A]
iPhone 6 (8.1 Simulator) [12EE4E79-D561-46D2-9F80-BB7278E4A883]
iPhone 6 Plus (8.4 Simulator) [B04685D3-FBA0-45FF-B4B0-C3162A77F90B]
my simulator (8.1 Simulator) [6E43E3CF-25F5-41CC-A833-588F043AE749]
)

      DEVICES_511 = %q(
Known Devices:
neptune (v8.4.1) (43be3f89d9587e9468c24672777ff6211bd91124)
mercury (v8.4.1) (5ddbd7cc1e0894a77811b3f41c8e5caecef3e912)
stern (com.apple.instruments.devices.local)
iPhone - Simulator - iOS 6.1
iPhone - Simulator - iOS 7.0
iPhone - Simulator - iOS 7.1
iPhone Retina (3.5-inch) - Simulator - iOS 6.1
iPhone Retina (3.5-inch) - Simulator - iOS 7.0
iPhone Retina (3.5-inch) - Simulator - iOS 7.1
iPhone Retina (4-inch) - Simulator - iOS 6.1
iPhone Retina (4-inch) - Simulator - iOS 7.0
iPhone Retina (4-inch) - Simulator - iOS 7.1
iPhone Retina (4-inch 64-bit) - Simulator - iOS 6.1
iPhone Retina (4-inch 64-bit) - Simulator - iOS 7.0
iPhone Retina (4-inch 64-bit) - Simulator - iOS 7.1
iPad - Simulator - iOS 6.1
iPad - Simulator - iOS 7.0
iPad - Simulator - iOS 7.1
iPad Retina - Simulator - iOS 6.1
iPad Retina - Simulator - iOS 7.0
iPad Retina - Simulator - iOS 7.1
iPad Retina (64-bit) - Simulator - iOS 6.1
iPad Retina (64-bit) - Simulator - iOS 7.0
iPad Retina (64-bit) - Simulator - iOS 7.1
)
    end
  end
end
