## Change Log

### 3.0.1

* Core: default simulator for Xcode 10 is iPhone 10S #696

#### DeviceAgent 1.3.1

https://github.com/calabash/DeviceAgent.iOS/releases/tag/1.3.1

* Add new iPhone 10S, 10S Max, and 10R model numbers #296
* Server: add speech recognition alert texts #293
* Server: add new localizations for SB alerts #294

#### iOSDeviceManager 3.2.1

https://github.com/calabash/iOSDeviceManager/releases/tag/3.2.1

* Upload xctestconfig command requires file paths #320
* Frameworks: update FBSimControl related frameworks with new ios 12
  device models #231

### 3.0.0

Built with Xcode 10 beta 6

* Simctl: retry app install on 'could not install app at this time' error #694
* App#calabash\_server\_id: extract fingerprint of embedded server #692
* Remove support for legacy Xcode toolchains #691
* Lib: add Xcode 10 support #690
* Improve simulator "wait for stable" heuristic #689

#### DeviceAgent 1.2.6

Provide support for Xcode 10 beta 6.

* Improve query speed by loading BootstrapInject.dylib into AUT #282
* remove simulator log redirect #285
* SpringBoard: update Italian localizations #287
* Support for Xcode 10 beta 6 #291

* https://github.com/calabash/DeviceAgent.iOS/releases/tag/1.2.6

#### iOSDeviceManager 3.2.0

This release provides support for Xcode 10 beta 6.

* Shell: all NSTask executed with timeout #219
* Fix simulator-by-alias/name algorithm #225
* Codesign is timing out on low resource machines #226
* Stablize Simulator app life cycle events for Xcode 10 beta 6 #228

* https://github.com/calabash/iOSDeviceManager/releases/tag/3.2.0

### 2.7.1

Built with Xcode 9.4 beta 2

#### DeviceAgent 1.2.4

* Server: add Apple Music en and ru alerts #277

Built from the /develop branch:

* https://github.com/calabash/DeviceAgent.iOS/commit/e729d78793d5a206d81013644346c9f33bab1944

#### iOSDeviceManager 3.1.0

* Frameworks: update frameworks #210
* Commands: add erase simulator command #209

Built from the /develop branch:

* https://github.com/calabash/iOSDeviceManager/commit/1e34858496ad693a21e3d99bfc3b064e6b4d21cf

### 2.7.0

This release contains DeviceAgent 1.2.4 and iOSDeviceManager 3.1.0.

* Dir#digest: change how cumulative digest is computed #683
* Shell#run_shell_command responds to :environment option #682
* iOSDeviceManager partially implements PhysicalDevice::LifeCycle interface #681
* Add support for Xcode 9.4 #680

#### iOSDeviceManager 3.1.0

* Fixed is-installed command simulator bug #206
* Add clear-app-data and download-xcappdata commands #203

https://github.com/calabash/iOSDeviceManager/releases/tag/3.1.0

### 2.6.6

This release contains DeviceAgent 1.2.4 and iOSDeviceManager 3.0.0.

#### DeviceAgent 1.2.4

* added Russian SpringBoard alerts localizations (DeviceAgent) #271
* OSS: changes for MSFT open source review #275

Also includes support dismissing "is not Activated" alerts for iOS >= 10
in US English and Dutch locales.

https://github.com/calabash/DeviceAgent.iOS/releases/tag/1.2.4

#### iOSDeviceManager 3.0.0

* Ask if app is installed only once during app installation #193
* Xcode 9.3 and iOS 11.3 support #199
* Replace install --update-app with --force flag and fix behavior #200

https://github.com/calabash/iOSDeviceManager/releases/tag/3.0.0

### 2.6.5

This release contains support a new DeviceAgent and iOSDeviceManager
for Xcode 9.3 support - built with Xcode 9.3 beta 4.

* Gem: add Xcode 9.3 support #667
* add Russian translations for SpringBoard alerts (UIAutomation) #669
* Improve CoreSimulator Services process management #670
* Add element_types method to DeviceAgent client #671

#### DeviceAgent 1.2.3

* added Russian SpringBoard alerts localizations (DeviceAgent) #271
* OSS: changes for MSFT open source review #275

Also includes support dismissing "is not Activated" alerts for iOS >= 10
in US English and Dutch locales.

Built from the /develop branch:

* https://github.com/calabash/DeviceAgent.iOS/commit/ab996d6b4ec9ecf217bdd67d9f3c58d2ff7ba30b

#### iOSDeviceManager 3.0.0

* Ask if app is installed only once during app installation #193
* Xcode 9.3 and iOS 11.3 support #199
* Replace install --update-app with --force flag and fix behavior #200

Built from the /develop branch:

* https://github.com/calabash/iOSDeviceManager/commit/f3f1f90fe3026191406cadaf3325f4c0936fc789

### 2.6.4

This release contains an update to DeviceAgent to help support
drag-and-drop on iOS 11.

#### DeviceAgent 1.2.3

* Xcode: target + script for running XCUITests against arbitrary.app #260
* Server: drag-n-drop can start with a touch-and-hold #259
* TestApp: update URLs to calabash-ci.xyz domain #258

https://github.com/calabash/DeviceAgent.iOS/releases/tag/1.2.3

### 2.6.3

* DeviceAgent: improve support for inspecting app state and terminating apps #663

#### DeviceAgent 1.2.2

* Use XCUIApplication#terminate to terminate applications #256
* Server: XCUIElement with type Any may or may not respond to WebDriver methods #255
* Add iOS 11 'would like to add to your photos' SpringBoard alert #254
* SB: add camera alert for iOS 11 de #252
* Server: update CBXDevice with iPhone 8 and 10 models #251

https://github.com/calabash/DeviceAgent.iOS/releases/tag/1.2.2

### 2.6.2

* Support Xcode 9.2 and iOSDeviceManager 2.1.2 #660
* DylibInjector: user can add delay before injecting #659
* Xcode: add support for 9.1 #658
* Updated XCUIElementType documentation #656
* HTTP: client retries on unreachable host #655

#### iOSDeviceManager 2.1.2

* Update FBSimulatorControl frameworks to fix various Xcode > 9.0 problems #191
* CLI: remove start-test command and sources #190
* CLI: commands for decoding xctestconfiguration files #189

https://github.com/calabash/iOSDeviceManager/releases/tag/2.1.2

### 2.6.1

* CoreSim: disable hardward keyboard at launch 243ee0a

#### DeviceAgent 1.2.1

* Server: handle 3 button SpringBoard location alert #249

https://github.com/calabash/DeviceAgent.iOS/releases/tag/1.2.1

#### iOSDeviceManager 2.1.1

No changes applicable to run-loop.

https://github.com/calabash/iOSDeviceManager/releases/tag/2.1.1

### 2.6.0

Support for testing with Xcode 9 and iOS 11.

#### DeviceAgent 1.2.0

* Xcode 9: redirect simulator logs to ~/Library/CoreSimulator/<UDID>/system.log #247 @JoeSSS
* Server: XCUIApplication cannot be first responder #246

https://github.com/calabash/DeviceAgent.iOS/releases/tag/1.2.0

#### iOSDeviceManager 2.1.0

No changes applicable to run-loop.

https://github.com/calabash/iOSDeviceManager/releases/tag/2.1.0

### 2.5.4

This patch improves support for testing against iOS Simulators in Xcode
9 beta 6.  Please note that until Xcode 9 GM, support is preliminary and
the next Xcode 9 beta may break existing tests.

* Device: use PlistBuddy#unshift\_array to set Simulator language #651
* PlistBuddy can run arbitrary commands and push new values onto arrays #650
* Device: ensure simulator plist paths exist #649

### 2.5.3

This patch provides preliminary support for testing against iOS
Simulators in Xcode 9 beta 6.

* Xcode 9: ensure software keyboard will show #647
* Xcode 9: update CoreSim.app\_installed? #646
* Xcode 9/iOS 11: add new languages and locales #645
* Simctl: can switch back to Xcode 8 after Xcode 9 is active #644
* CoreSim: update list of managed simulator processes #643
* Xcode 9: adjust the required processes for "wait for simulator stable" heuristic #642

### 2.5.2

This a patch release for Xcode 9 beta 6.  It includes iOSDeviceManger
2.0.2, which contains a fix for loading Swift dylibs in Xcode 9.

### 2.5.1

This is patch release for Xcode 9 beta 6.

* DeviceAgent: update to iOSDeviceManager 2.0.1 #639

#### iOSDeviceManager 2.0.1

* Terminate apps before uninstalling to prevent black
  screen/unresponsive apps on physical devices #177
* FBSimulatorControl: sync to 0.4.0 f7c5822 on Aug 18 2017 #176
* CLI for uploading in entire xcappdata bundles #175
* Fixes getting resources from args for install-app #172

### 2.5.0

This release provide preliminary support testing with Xcode 9 against
iOS 11 physical devices.  Testing against simulators is not yet
supported.

run-loop now responds to `PROVISIONING_PROFILE` environment variable.

* DeviceAgent: update to DeviceAgent 1.1.3 #637
* L10N: update path to UIKit.axbundle for Xcode 9 #636
* Update equality rules for Version class #635
* Respond to DeviceAgent iOS 11 changes to POST /rotate\_home\_button\_to #634
* Better xcodebuild process management #633
* Update to iOSDeviceManager 2.0 #632
* CLI: add simctl erase and launch commands #631
* Gem: fix reference to version.rb for bundler 1.15 #630
* CoreSim: simulator does not steal focus when launching #629
* CoreSimulator can handle Xcode 9 DeviceAgent name change #628
* Device: wait for .GlobalPreferences.plist to exist #627
* Xcodebuild: manage existing test-without-building processes #625
* Initial Xcode 9/iOS 11 support #622
* Option for DeviceAgent to terminate AUT if it is running when new test
  session starts #620

#### DeviceAgent 1.1.3

This DeviceAgent was built with Xcode 8.3.3 on macOS Sierra.

https://github.com/calabash/DeviceAgent.iOS/releases/tag/1.1.3

* Server: decrease default touch time to 0.1 #244
* Update device rotation gesture and orientation reporting for iOS 11 #243
* Server: Remove pre-launch is-installed check; does not work on iOS 11 #242
* Xcode 9: text queries not forwarding to WebDriver attributes #241
* Server: handle infinite and CGFloat max/min floating point values #240
* Server: OR predicates not evaling correctly on web views - updated
  tests; issue is not resolved #239
* SpringBoard: add Hebrew and Italian SpringBoard alerts #238
* Update CBXDevice for iPad Pro 10.5 and arm64 devices #236
* Update build scripts to publish TestApp to test-cloud-test-apps #235

#### iOSDeviceManager 2.0.0

iOSDeviceManager 2.0 has improved code signing and preliminary support
for Xcode 9.

This iOSDeviceManager  was built with Xcode 8.3.3 on macOS Sierra.

https://github.com/calabash/iOSDeviceManager/releases/tag/2.0.0

* Stabilize and improve the resigning integration tests #168
* FBSimulatorControl includes ReturnAttributes key when inspecting
  installed applications #163
* Fetching applications before downloading app data prevents failures  #162
* Xcode 9: can install provisioning profiles #161
* Add app-info command #160
* Fix file uploading when targeting physical devices #157
* upload command writes upload path to stdout #155
* CLI 2.0 #137

### 2.4.1

This release does not contain a new DeviceAgent stack.

* Migrate ~/.run-loop/xcuittest to ~/.run-loop/DeviceAgent to ensure
  xctestrun run exists #616

### 2.4.0

This release supports Xcode 8.3 and iOS 10.3.

This release contains a new DeviceAgent stack.

If you build run_loop from sources with bundler, you must run:

```
$ rake device_agent:expand
```

to get the new DeviceAgent stack.

The iOSDeviceManager resigning algorithm has been improved and we
expect this iOSDeviceManager to execute application lifecycle events
faster.

* DeviceAgent: replace start_test with xcodebuild test-without-building #613
* API for managing SpringBoard alerts manually #611
* Adds handling for Korean SpringBoard alerts. #610
* JS: add VPN definition to on_alert #608

#### DeviceAgent 1.1.1

https://github.com/calabash/DeviceAgent.iOS/releases/tag/1.1.1

* DeviceAgent.xctest bundle includes xctestrun files #214
* Dismiss 'Open in' alerts automatically #212
* Fix PT-br APNS SpringBoard alert localizations #211
* Add Korean localizations for SpringBoard alerts #209
* Adds handling for VPN configuration springboard alert. #208
* Update for Xcode 8.3 #206
* Allow users to interact with SpringBoard alerts and control whether or
  not alerts are automatically dismissed #205
* Server: disable screenshots on server start #204

#### iOSDeviceManager 1.1.1

https://github.com/calabash/iOSDeviceManager/releases/tag/1.1.1

* Simulator#launch: wait for required simulator sevices #131
* Xcode 8.3 support #126
* Add library version of iOSDeviceManager for interop w/ Test Recorder #120
* Integration test using run_loop ruby API #110
* implement ios-cli resigning algorithm and add CLI interface #108
* Improve default device detection #104
* Add support for app lifecycle events on .ipa archives #103
* Allow positional argument for device ID #102
* Stores identities rather than making multiple find-identity calls #101

### 2.3.1

This release does not contain a new DeviceAgent stack.

* Xcode#version returns 0.0.0 on XTC and on RuntimeErrors #606
* CoreSim: quit simulator before resetting app sandbox #605
* DeviceAgent::Client: skip ensure software keyboard check #604
* Prepare for Xcode 8.3 support #603
* Directory: rescue errors during skip check and File.size #598
* Directory: rescue ENOENT errors during skip check #597

### 2.3.0

This release contains a significant change - Simulators will not be
automatically be relaunched whenever
`Calabash::Cucumber::Launcher#relaunch` is called.  Instead, run-loop
will try to keep the simulator running as long as it appears to be
health.  This change is only for DeviceAgent test runs.  Tests that use
UIAutomation will continue to relaunch the simulator.

If you are on macOS Sierra or using Xcode >= 8.0, you are running
against DeviceAgent.  UIAutomation is only used on El Cap with Xcode <
8.0 and iOS < 10.

If your tests need the simulator to relaunch every time
`Launcher#relaunch` is called, you can pass the new `:relaunch_simulator =>
true` option.  This option is provided for backward compatibility.

* Improve Device#simulator\_wait\_for\_stable\_state for iOS <= 8 and iOS >=  10.1 #594
* CoreSimulator manages more processes for Xcode 8 and Sierra #593
* Stabilize integration tests for Xcode 8.2 #592
* Allow user to force simulator relaunch when running with DeviceAgent #591
* CoreSimulator relaunches the simulator if app state is not acceptable #590
* Use iOSDeviceManager arguments that are 1.0.4 and 1.0.5 compatible #589
* DA:Client: use a separate timeout for entering text #588
* DeviceAgent#Client: check if running DeviceAgent is stale #587
* Decouple simulator wait for stable state and CoreSim install and uninstall #586
* Add nl\_BE and Swedish localizations for privacy alerts #585
* Update iOSDeviceManager arguments for 1.0.5 #584
* Device: improve the wait-for-simulator-stable algorithm #582
* ProcessWaiter: improve process detection #581
* CoreSim: quit simulator only when necessary #580
* DeviceAgent::Client: check simulator/application architecture compatibility #579
* Stabilize integration tests for Xcode 8 #578
* OSS: update vendor licenses #576

#### DeviceAgent 1.0.6

DeviceAgent 1.0.5 was skipped.

Built from tag [1.0.6](https://github.com/calabash/DeviceAgent.iOS/releases/tag/1.0.6)

* Add mach clock and a simple waiter #202
* SpringBoard#queryForAlert: skip\_waitForQuiescence check #201
* Increase touch duration to 0.2 to match XCUITest #198
* Use CocoaLumberjack for logging #197
* Update CocoaLumberjack to 3.0.0 #196
* TestApp: update to calabash.framework 0.20.4 #194
* Improve hitpoint and visibility calculation #193
* Fix text entry for i386/armv7 devices #192
* Dismiss SpringBoard alerts by touching alert buttons with coordinates #191
* SpringBoard: ask UIApplication for SpringBoard alert before making an expensive XCUITest query #190
* POST /session raises when app is not installed and when app fails to launch #189

#### iOSDeviceManager 1.0.4

iOSDeviceManager is unchanged for this version.  See the 2.2.4 release
notes below for details about the iOSDeviceManager 1.0.4 release.

### 2.2.4

DeviceAgent 1.0.4 can dismiss SpringBoard alerts in any orientation.

* DeviceAgent: no longer requires CLI.json #574

#### DeviceAgent 1.0.4

Built from tag [1.0.4](https://github.com/calabash/DeviceAgent.iOS/releases/tag/1.0.4)

DeviceAgent can dismiss SpringBoard alerts in any orientation.

* Replace NSRunLoop runUntilDate: with CFRunLoopRunInMode to avoid
  unreliable NSDate behaviors #187
* SpringBoard: use XCUIElement#tap to dismiss alerts #186
* DeviceAgent: generate and distribute a dSYM #185

#### iOSDeviceManager 1.0.4

FBSimulatorControl was not updated.  See the 1.0.3 notes for details.

* Remove DeviceAgent.iOS.Deployment #99
* CLI.json is no longer necessary for the iOSDeviceManager binary #96

Built from tag [1.0.4](https://github.com/calabash/iOSDeviceManager/releases/tag/1.0.4)

### 2.2.3

* Update to DeviceAgent stack to 1.0.3 #572
* CODE\_SIGN\_IDENTITY is not longer required #570
* Increase DeviceAgent timeouts #569
* DA:Client: launch AUT with args and environment #567
* run-loop simctl tail shows all simulator logs #566
* App: fix TrueType font extension to avoid otool failures #565
* Added pt-BR translations for permissions alerts #563 @oscartanner
* Support Xcode 8.2 #561
* Turns enter text input parameter to string for numeric keyboards #560
* Gem: patch awesome\_print for BasicObject #559

#### DeviceAgent 1.0.3

Built from tag [1.0.3](https://github.com/calabash/DeviceAgent.iOS/releases/tag/1.0.3)

* Add iTunes and Apple Music SpringBoard alerts #183
* Add UITextView to TestApp #181
* Use Testmanagerd `XCT_sendString` to enter text except on i386/armv7 devices #178
* Fixes if statement in querying delete key for clear text #177
* Add GET environment and arguments #176
* Update SpringBoard alert definitions for iOS 10 #175
* clear\_text should tap keyboard delete key #170

DeviceAgent now dismisses the following US English SpringBoard alerts:

* Sign In to iTunes
* Access Apple Music And Your Media
* Health Access
* Enable Dictation
* pt\_BR localizations - thanks @oscartanner

#### iOSDeviceManager 1.0.3

Built from tag [1.0.3](https://github.com/calabash/iOSDeviceManager/releases/tag/1.0.3)

Includes [facebook/FBSimulatorControl 0.2.2 @
f0cc887](https://github.com/calabash/FBSimulatorControl/commit/f0cc8874a9fc1474e278db7571f8c35b9f88a354).

The corresponding calabash/FBSimulatorControl tag is
[fb-0.2.2-at-f0cc887](https://github.com/calabash/FBSimulatorControl/releases/tag/fb-0.2.2-at-f0cc887-iOSDeviceManager-1.0.3)

* Match array-based entitlements with * and <TEAM ID>. #95
* FB Frameworks 0.2.2 with Sierra + Xcode >= 8.1 support #94
* Fix timeout by using mach\_absolute\_time() #93
* Fix ShasumProvider generating strings with missing characters. #92
* Upload files to application's data container #91
* Update to Facebook frameworks to 0.2.2 #89
* Use CocoaLumberjack provided by FBSimulatorControl #85
* Fix cannot find XCTBootstrap.framework compile time errors #83
* Simplify how we get the common name for a certificate #82
* Use CommonCrypto to get SHA1 instead of shelling out #80

### 2.2.2

The DeviceAgent stack contains fixes for:

* Fixes for pan gesture
* Code signing improvements

#### run-loop

* DA:Client: increase timeouts for enter text calls #557
* Forward launch options to CoreSimulator #556 @MortenGregersen
* Gem: update the DeviceAgent stack to 1.0.2 #554
* Adds clear text for device agent #551 (not public yet)
* DeviceAgent::Client: add support for query("\*") and query("all \*") #550
* DeviceAgent::Client: enter text without keyboard check #548

#### DeviceAgent 1.0.2

**20fbc23ece073e5beea611a4aafae436ad78e54b**

* Drag avoid inertia #167
* Fix drag repetitions and correct duration from first point #164
* Touch: increase touch duration by 0.01 #161

#### iOSDeviceManager

**cd24f2078ddac8a6435c819b8b980023636d6108**

* Sign sim app bundles with the ad hoc signature '-' #63
* Make entitlement match robust to different entitlement formats #58
* Find usable codesign identity when not specified #53

### 2.2.1

The DeviceAgent stack contains fixes for:

* iOSDeviceManager crashes during DeviceAgent install (resigning)
* entering text causes app crashes

#### RunLoop

* DeviceAgent: update stack to 1.0.1 #545
* Support for Xcode 8.1 #543 @ark-konopacki
* flatten tree results - first step toward a replacement for query("\*")
  #542 @ark-konopacki
* CoreSim: waiting is necessary after simctl install #538
* Core: default sim for Xcode 8 is iPhone 7 iOS 10 #537
* Gem: force HTTPClient 2.7.1 or higher #536

#### DeviceAgent 1.0.1

**3ad75a33442a38cf1688ba705802c7de92a9fe9a**

* Server: branch on element and snapshot when computing visibility #163
* Remove exception handling when computing visibility attributes in
  JSONUtils #162
* Server: resolve application before entering text #160

#### iOSDeviceManager

**de929cdbbb1f8b46f8c300fd6a8ea3f03aa4182c**

* MobileProfile: synchronize NSMutableArray inserts #48
* FBSimulatorControl SHA: 49f35f46eee79ec6ba8c1a744c256073e819cece

### 2.2.0

* Fix retry with dylib injection and DeviceAgent #534 @MortenGregersen

* DeviceAgent 1.0.0 a87ab2fe62a7c80aca6dd69e75b1bf923a87b2ef
* iOSDeviceManager fe4942dc2ba245021f10ce7658235be31f25566b
* FBSimulatorControl e3971e6d8b79b551ba8f5e05b72d355e18d7bc96

### 2.1.11

#### DeviceAgent

* 0.1.2
* SHA: 1ec8d02c54868559b301c218bbcd870cb16c23d9
* Handle SpringBoard alerts: take 2 - update based on Chris F
  changes + POST /dismiss-springboard-alerts #157

#### iOSDeviceManager

* SHA: fe4942dc2ba245021f10ce7658235be31f25566b

#### FBSimulatorControl

* SHA: e3971e6d8b79b551ba8f5e05b72d355e18d7bc96

#### Gem

* Respond to DeviceAgent SpringBoard alert route changes #532
* Support LPServer dylib injection on Simulators when running with
  DeviceAgent #531

### 2.1.10

#### DeviceAgent

* 0.1.2
* SHA: 3f985f3b4fb8f986c7450bd4db60eb6bd10f9f80
* Add marked query specifier and add tests for /query API #152
* Server: disable automatic SpringBoard alert dismiss #155

#### iOSDeviceManager

* SHA: fe4942dc2ba245021f10ce7658235be31f25566b
* Resiging: be defensive when calling NSTask #47
* Use ditto instead of zip when generating nuget package #46
* Resigning: fix mobileprovision decode and import #45
* Make: copy FB Frameworks with ditto #44

#### FBSimulatorControl

* SHA: e3971e6d8b79b551ba8f5e05b72d355e18d7bc96
* Make: build the Frameworks like Facebook does #7
* Expose one-off check to see if test complete #6
* Bootstrap: log when a testCaseDidFailForTest #5

#### Gem

* Allow the user to increase the default DeviceAgent install time #529
* DA:Client: prototype API for SpringBoard alerts #528
* CoreSim: don't wait after simctl install #527
* Improve DeviceAgent::Client HTTP interactions #526
* DeviceAgent: Cleanup life cycle methods #525
* DA:Client: increase default timeouts for Xamarin Test Cloud #524
* DA:IDM: Disable is installed? check for physical devices
* DA:IDM: only restart the simulator if necessary
* CLI: simctl tail displays last 5000 lines
* Expand DeviceAgent#query and gestures #522

### 2.1.9

* DeviceAgent: replace :gesture\_performer with :automator #520

### 2.1.8

Many thanks to the crew on Gitter. Special thanks to:

* @JoeSSS, @TeresaP, @ark-konopacki, and @MortenGregersen

for beta testing.

* DeviceAgent 0.1.0 + code sign fix for physical devices #517
* Update to DeviceAgent 0.1.0 #516
* Update DeviceAgent stack in response to DeviceAgent.iOS name changes #515
* XCUITest #query filters by visibility #513

### 2.1.7

* XCUITest: add #pan\_between\_coordinates #511
* Respond to Xcode 8 otool changes #509
* Only launch CBX-Runner when necessary #508
* All simctl commands are performed through Simctl instance #507
* Device: assume PlistBuddy is not in PATH when setting the simulator
  language #506
* LifeCycle: IOSDeviceManager expands the Frameworks.zip if necessary
  #504
* Shell: raise the correct error when command fails #503
* Regex: expand VERSION\_REGEX to support iOS 10.0 #502
* Rake: add task for expanding device agent .zips #501
* Start PhysicalDevice::LifeCycle::IOSDeviceManager implementation #500

### 2.1.6

* Remove dnssd dependency #496
* Core.default\_tracetemplate raises on Xcode 8 #498

### 2.1.5

* Gem: require dnssd only on macOS #493
* iOSDeviceManager: wait for sim 'shutdown' state before launching #492

### 2.1.4

* RunLoop.run detects and respects gesture performer key #490
* run-loop cache needs to provide DeviceAgent details #489
* Don't call ps in the context of xcrun #488
* DeviceAgent: update to iOS 10 and Xcode 8 compatible binaries #486
* Travis uses macOS 10.11 and Xcode 7.3 #485
* XCUITest can use iOSDeviceManager binary to launch CBX-Runner and AUT
  #483
* Detecting and handling Xcode 8 and iOS 10 #482
* DetectAUT: increase search depth for AUT for Xamarin projects #481
* Rename exec methods in various classes #479
* XCUITest respects to DEVICE\_AGENT\_URL #477
* XCUITest: simplify the common gestures API #476
* XCUITest: support text entry #474

### 2.1.3

* Replace ~/ with Environment.user\_home\_directory #472
* Add CBXRunner and xctestctl #471
* Add more localizations for privacy alerts #469
* Catch invalid APP and device target settings #467
* XCUITest: progress on gesture API #466
* Physical device app LifeCycle API #458

### 2.1.2

* Fix :script and :uia\_strategy detection #460
* Shell: a mixin for executing shell commands safely #457
* Encoding: extract uft8 coercion method from Xcrun #456
* SpringBoard cannot detect app installed by simctl on iPad #455
* DetectAUT ignores UrbanAirship and Google iOS SDK .xcodeproj #453
* Gem: pin listen to 3.0.9 #451
* XCUITest can perform queries by id #446
* Env: improved windows env detection #445

### 2.1.1

* Expose color methods as public API #443
* Replace SimControl with Simctl #441
* Fixing syntax error in host script #438 @garyjohnson
* Improve retry strategy for app launch on simulators #436
* Fix instruments CLI rspec tests. #416
* CoreSim#launch: improve retrying #434
* Filter new Xcode 7.3 simctl stderr output from `simctl list devices`
  #433
* Simctl is responsible for collecting devices on Xcode > 6
* CoreSim: patch retry on failed app launch 5300542
* Restore UIALogger flushing and ensure variables are substituted
  properly. #430
* DotDir: symlink to current result #429
* Relax deprecation warnings @TeresaP, @jane-openreply, and others
* RESET\_BETWEEN\_SCENARIOS has stopped working #426 @ankurgamit

### 2.1.0

This release fixes a bug that might put the iOS Simulator into a bad state.
An iOS Simulator could potentially have a .app installed in its directory
structure, but the app would not appear in Springboard or be detected by
simctl.  We have fixed the bug for Xcode 7.  There is no possible fix for
Xcode 6.  In order to ensure that your iOS Simulators are in a good shape we
recommend that all users run:

```
# Will take ~10 minutes depending on the number of installed simulators.
#
# Don't forget to run this on your CI machines.
#
# You only have to run this command once!
$ DEBUG=1 run-loop simctl doctor
```

I apologize for the inconvenience, this mistake is on me. -jjm

* Experimental interface for launching CBX-Runner and sending commands
  #423
* App and Ipa can return version info #422
* CLI: simctl doctor erases sims first #421
* Improve installed app check for Xcode 7 simulators #420
* Instruments#kill\_instruments no longer branches on Xcode version #420
* CoreSim#launch - retry on errors #418
* Interface for launching CBX-Runner #417
* Core.run\_with\_options improve the way AUT and DUT are inferred #414
* Core.detecti\_uia\_strategy given options and RunLoop::Device #413
* DetectAUT.detect\_app\_under\_test #412
* Device is responsible for inferring which device to target #411
* Drop Xcode 5 checks #410
* Environment: handle empty strings for DEVICE\_TARGET, DEVICE\_ENDPOINT, and
  TRACE\_TEMPLATE #408
* Rescue pipe\_io if Errno::EPIPE error is encountered #407 @TeresaP

### 2.0.9

* Improve automatic .app detection #405

### 2.0.8

* App: improve executable detection in app bundles #401
* Automatic .app detection #396
* App: valid apps have an executable file (CFBundleExecutable) #393
* App and Ipa can return arches #392

### 2.0.7

* Obtaining codesigning information about App and Ipa #388
* Raise error if Xcode#developer\_dir path does not exist #387

### 2.0.6

* Xcrun: handle command output that contains non-UTF8 characters #382 @ark-konopacki
* Improve how App and Ipa instances detect the Calabash server version #379

### 2.0.5

* Refactor auto dismiss JavaScript methods #378
* JS: French localizations for privacy alerts #377

### 2.0.4

* Xcode 7.3 support #370
* Launch simulator with locale and language #367
* App and Ipa classes can report calabash\_server\_version #366
  @ark-konopacki

### 2.0.3

* Fix: Unable to find file: run\_loop\_fast\_uia.js #361
  - @NickLaMuro, @kyleect and everyone else who reported

### 2.0.2

* OnAlert: divide regexes by language #358
* HostCache can be used by `console_attach` for all strategies #357
* Xcode 7.2 support #355
* Add Gitlab as a supported CI #353
* \*\_ci? methods should return true/false #355
* Extract Logger and onAlert to a single JavaScript file using erb
  templates #261 @svevang

### 2.0.1

* Add Danish missing localization for Location alert #346
* Dutch APNS dialog is not automatically dismissed #337

### 2.0.0

* Core: prevent double launching of simulator #341 @fmuzf
* CoreSim: expose :wait_for_state_timeout option #340
* CoreSimulator can erase a simulator #339
* Core: prepare simulator responds to :reset launch arg #338
* Fix 'simctl manage processes' #336
* Increase simctl and sim stable timeouts in CI environments and expose
  options to users #334
* Find window with hitpoint #333 @krukow
* Improve Directory.directory_digest response to File.read errors #331
* Increase simctl install/launch app and simulator stable timeouts in CI
  environments #329
* Auto dismiss "nearby bluetooth devices" alert #326
* Simplify the detection of iOS Simulator #323
* Remove Retriable dependency #322
* Remove CAL_SIM_POST_LAUNCH_WAIT env var #321
* Remove XCTools #319
* Expose important timeouts as constant mutable hashes #315
* CoreSimulator#launch launches simulator even if app is installed #313
* Send KILL to lldb directly and don't wait as long for lldb to die #312
* Improve dylib injection for simulators #311 @MortenGregersen
* Standup Jenkins jobs #309
* Set minimum ruby version to 2.0 #308

The following have been removed from RunLoop in 2.0:

* RunLoop::XCTools; replaced with Xcode and Instruments
* RunLoop::Environment.sim_post_launch_wait; no replacement.
  Additionally, run-loop no longer responds to CAL_SIM_POST_LAUNCH_WAIT

### 1.5.6

Many thanks to everyone who filed issues for this release.

* Rotate /Library/Cache/com.app.dt.instruments directories #304
* By default, run-loop writes results to ~/.run-loop/results and manages
  these directories #299
* Fix CLI simctl install/uninstall: CoreSim manages stdio.pipe and
  'remembers' that it already launched the simulator #297
* Improve Directory.directory\_digest and
  Device#simulator\_wait\_for\_stable\_state interaction #296
* Xcode 7: command line tools that use Simctl::Bridge are broken
  (blocking) #289
* Device#simulator\_data\_dir\_size is timing out #287 @carmbruster
* Xcode 7.1 beta 2: instruments and simctl need to filter out Apple TV
  from known simulators #283
* Running out of disk space because of cached instruments files #276
  - @nfrydenholm, @TeresaP, @mholtman
* Expand APP (and APP\_BUNDLE\_PATH) path before launching instruments
  #255 @ark-konopacki

### 1.5.5

Many thanks to everyone who filed issues.  We really appreciate it.  If
I missed an attribution, let me know. -jjm

* Simulator: should manage the 'iproxy' process #279 @cryophobia
* Gem: ruby\_files glob should catch only ruby files #274 @svevang
* Fix blocking reads in Xcrun when consuming large output of commands #270
  - @kennethjiang, @kamstrup
* Instruments#version extracts version from Instruments.app Info.plist #269 @gdknutel
* Increase the default timeout for Xcrun.exec #268 @gdknutel
* Manage assetsd process #267
* Improve integration examples: part 1 #266
* Core.simulator\_target? should match simulators created by users #262

### 1.5.4

* Xcode 7: launch instruments with simulator UDID to avoid ambiguous
  matches #253 @sapieneptus
* Remove CoreSimulator LaunchServices csstore before during simulator
  preparation #252 @sapieneptus
* iOS9: dismiss Motion/Activity and Twitter permissions alerts #251
  @sapieneptus
* HOTFIX: backward compatibility for Calabash < 0.16.1 #248
  @ark-konopacki

### 1.5.3

* HOTFIX: backward compatibility for Calabash < 0.16.1 @ark-konopacki

### 1.5.2

* Use CoreSimulator to ensure target app is the same as installed app #244
* Core.prepare_simulator raises an error if app does not exist #236
* Fixup Core#simulator_target? for Xcode 7 #232
* Force UTF-8 encoding when reading the output of `instruments` Thanks to Magnús Magnússon
* Xcode 7.1 beta support
* CLI: simctl doctor [--device=DEVICE] - tool to prepare CoreSimulator environment EXPERIMENTAL
* CoreSimulator#launch_simulator waits for the simulator to install
* CoreSimulator App Life Cycle with direct file IO vs simctl
* Simulator devices can update their state
* Xcrun class for safely executing 'xcrun' commands

### 1.5.1

* Core.simulator\_target? - fixup for Xcode 7 #216
* JS: can dismiss iOS 9 APNS privacy alerts #214

### 1.5.0

* Deprecate optional argument in Device#instruments\_identifier
* Changes to prepare Calabash for Xcode 7/iOS 9 testing.
* Default sim for Xcode 7 is 'iPhone 5s (9.0)' #205
* Xcode 7 instruments support #204
* Expand the Instruments class behaviors
* Add L10N class
* Add Xcode class
* Deprecate XCTools class
* Add more privacy alert auto-dismiss regular expressions #199
* UIKit localization lookups in runloop #197 @svevang

### 1.4.1

* Fixed typo in Xcode 7 check #195 @krukow

### 1.4.0

* Add support for inspecting ipa app bundles #192
* Managing the CoreSimulator daemon #191
* Expect {} raise\_error should specify the error #190
* Xcode 7 beta support #189
* Prevent simulator from stealing focus between scenarios #188
  @michaelkirk
* Search for and validate gem version #187
* Add a generic file cache for hashes #185
* Move host cache from /tmp to ~/.run-loop #184

### 1.3.3

* Add Device.device\_with\_identifer method #181
* Simctl::Bridge should manage Xamarin's csproxy #180
* Remove LOAD\_PATH shifting; it is unnecessary #179

### 1.3.2

* 'run-loop simctl install' command line interface #175
* Retriable patch needs to retriable/version #173
* Xcode 6.4b support #172

### 1.3.1

This is a patch release for Xcode 6.3 + iOS 8.3 simulators.

##### Xcode 6.3 instruments cannot launch installed app on iOS 8.3 Simulator [calabash/#744](https://github.com/calabash/calabash-ios/issues/744)

* Refine accessibility and software keyboard enabling #168
* Implement fix for Xcode 6.3 + iOS 8.3 simulators #165
* Make simctl bridge production ready #164
* simctl bridge can UIAninstall an app #163

### 1.3.0

* Add command-line tool #157
* Avoid permission collision of parent temp folder when running multiple instances from different user accounts on the same machine #156 @benshan
* Support 1.3.3.1 <= Retriable < 2.1 #154
* Detect Xcode-beta.app (new in Xcode 6.3 beta 3) #153

### 1.2.9

* Can use simulator UDID for DEVICE\_TARGET #150
* SimControl should filter unavailable devices #148

### 1.2.8

* Support for providing a logger in the options parameter to most methods
* Non-blocking writes prevent occasional hang in run app

### 1.2.7

* Support raw JavaScript calls to UIPickerView classes #134
* Install and launch an app with simctl #132
* Xcode 6.3 beta support #127
* Better instruments process spawn/termination #123, #128, #129
* In multi-user environments, `/tmp/run_loop_host_cache` causes permissions issues #121 @onfoot

### 1.2.6

* #118 rollback awesome print dependency to match android

### 1.2.4

* Fix performance regression on :host strategy [calabash #670](https://github.com/calabash/calabash-ios/issues/670)

### 1.2.3

* #111 stable and pre-release comparison @spedepekka
* #109 Change Xcode 6 default simulator to iPhone 5s
* #107 enable host strategy caching for console attach

### 1.2.2

* #105 update awesome print to 1.6

### 1.2.1

* #101 Escape binary path in argument to lipo. @gredman

### 1.2.0

* Improved :host strategy.
* Improved :preferences strategy.
* Improved escaping across all strategies.
* Experimental support for Xcode 6.2 beta.
* #94 Round coordinates in uia
* #93 Allow dismissal of Location accuracy when bluetooth is disabled
* #91 Add updated CalabashScript to retry key entry if there is a failure
* #90 Updated Calabash Script to support swipe via drag
* #87 instruments process are becoming orphaned because the parent is killed before the child
* #84 Fix bad ref to logger
* #81 UITest: Fix querying Symbols and bump run loop prerelease version
* #80 Ensure compatible arch before launching on device
* #79 UIA strategy shared element
* #78 Default simulator for xcode 6.2 beta
* #76 Device class can provide instruments ready simulator names

### 1.1.0

* #69 Stability uia timeout/lost write/read
* #68 Raise an error with a helpful message when Instruments.app is open
* #61 After killing instruments, try Process.wait

### 1.0.9

* #57 Enable Xcode 6 simulator keyboards by default thanks @gwynantj
* #56 Default simulator for Xcode 6.1 GM seed 2 should be iPhone 5 iOS 8.1
* #55 Enabling accessibility on simulators can skip CoreSimulator directories
* #54 Fix default_tracetemplate for Xcode 6.1 GM seed 2

### 1.0.8

* #48 Fixes 'No such process (Errno::ESRCH)' error when terminating instruments
* #47 Yosemite support for Xcode 6.1 beta automation template

### 1.0.7

* #46 Handling "notifications" related dialogs which appear particularly on iOS 8 devices

### 1.0.6

* #41 Send 'QUIT' instead of `kill -9` or 'TERM' to halt instruments processes

### 1.0.5

* #42 Prelim. support for different privacy dialogs on iOS 8

### 1.0.4

* #38 Adds two missing DEBUG == '1' guards
* #39 SimControl can erase individual Xcode 6 simulators
