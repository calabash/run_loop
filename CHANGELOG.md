## Change Log

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
