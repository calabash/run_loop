| master  | develop | [versioning](VERSIONING.md) | [license](LICENSE) | [contributing](CONTRIBUTING.md)| dependencies|
|---------|---------|-----------------------------|--------------------|--------------------------------|----------------------|
|[![Build Status](https://travis-ci.org/calabash/run_loop.svg?branch=master)](https://travis-ci.org/calabash/run_loop)| [![Build Status](https://travis-ci.org/calabash/run_loop.svg?branch=develop)](https://travis-ci.org/calabash/crun_loop)| [![GitHub version](https://badge.fury.io/gh/calabash%2Frun_loop.svg)](http://badge.fury.io/gh/calabash%2Frun_loop) |[![License](https://img.shields.io/badge/licence-MIT-blue.svg)](http://opensource.org/licenses/MIT) | [![Contributing](https://img.shields.io/badge/contrib-gitflow-orange.svg)](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow/)|[![Dependency Status](https://gemnasium.com/calabash/run_loop.svg)](https://gemnasium.com/calabash/run_loop)|

## Run Loop

* [How to contribute.](CONTRIBUTING.md)
* [How to make a release.](CONTRIBUTING.md)

### Requirements

* Xcode 6 and 7.
* ruby >= 2.0

The most recent versions of Xcode and ruby are strongly recommended.

### License

Run Loop is available under the MIT license. See the LICENSE file for more info.

### Versioning

Run Loop follows the spirit of Semantic Versioning. [1]  However, the semantic versioning spec is incompatible with RubyGem's patterns for pre-release gems. [2]

_"But returning to the practical: No release version of SemVer is compatible with Rubygems."_ - David Kellum

- [1] http://semver.org/
- [2] http://gravitext.com/2012/07/22/versioning.html

## For Run Loop Gem Developers

### IMPORTANT note to devs RE: udidetect submodule

The current head of the udidetect head does not include the udidetect binary.

If you are compelled to update, you _must rebuild and replace the scripts/udidetect_ binary.

At this time, there is no reason to update.

- [1] https://github.com/vaskas/udidetect/pull/3


### Tests

#### CI

* https://travis-ci.org/calabash/calabash-ios
* https://travis-ci.org/calabash/run\_loop
* https://travis-ci.org/calabash/calabash-ios-server
* http://calabash-ci.macminicolo.net:8080/

#### Unit Tests

```
$ be rake unit
```

#### Integration Tests

Take a break because these test launch and quit the simulator multiple times
which hijacks your machine.  You have enough time to take some deep breaths
and do some stretching.  You'll feel better afterward.

For continuous TDD/BDD see the Guard section below.

```
$ be rake integration
```

##### Device Testing

* Requires ideviceinstaller.
* Requires devices to be connected with USB.
* Each compatible device will be targeted with tests.
* These are _integration_ tests

##### Regression vs. Xcode version

If you have alternative Xcode installs that look like this:

```
/Xcode/5.1/Xcode.app
/Xcode/5.1.1/Xcode.app
/Xcode/6.1.1/Xcode.app
/Xcode/6.2/Xcode-Beta.app
/Xcode/6.3/Xcode-Beta.app
```

the rspec tests will do regression testing against each version.

##### Guard

Requires MacOS Growl - available in the AppStore.

```
$ be guard
```

Only the unit tests are run by guard.

