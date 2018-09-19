| master  | develop | [versioning](VERSIONING.md) | [license](LICENSE) | [contributing](CONTRIBUTING.md)| dependencies|
|---------|---------|-----------------------------|--------------------|--------------------------------|----------------------|
|[![Build Status](https://travis-ci.org/calabash/run_loop.svg?branch=master)](https://travis-ci.org/calabash/run_loop)| [![Build Status](https://travis-ci.org/calabash/run_loop.svg?branch=develop)](https://travis-ci.org/calabash/crun_loop)| [![GitHub version](https://badge.fury.io/gh/calabash%2Frun_loop.svg)](http://badge.fury.io/gh/calabash%2Frun_loop) |[![License](https://img.shields.io/badge/licence-MIT-blue.svg)](http://opensource.org/licenses/MIT) | [![Contributing](https://img.shields.io/badge/contrib-gitflow-orange.svg)](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow/)|[![Dependency Status](https://gemnasium.com/calabash/run_loop.svg)](https://gemnasium.com/calabash/run_loop)|

## Run Loop

* [How to contribute.](CONTRIBUTING.md)
* [How to make a release.](CONTRIBUTING.md)

### Requirements

* at least Xcode 9.4.1
* ruby 2.3.*; ruby > 2.3 is not supported.

The most recent version of Xcode is strong recommended.

### License

Run Loop is available under the MIT license. See the LICENSE file for more info.

Licenses for third-party software can be found in `./vendor-licenses`.

### Versioning

Run Loop follows the spirit of Semantic Versioning. [1]  However, the semantic
versioning spec is incompatible with RubyGem's patterns for pre-release gems.[2]

_"But returning to the practical: No release version of SemVer is compatible with Rubygems."_ - David Kellum

If a method, class, or constant is marked with:

```
# @!visibility private
```

it is not part of the public API and the behavior is subject to change
at any time.

- [1] http://semver.org/
- [2] http://gravitext.com/2012/07/22/versioning.html


## For Run Loop Gem Developers

### IMPORTANT note to devs RE: udidetect submodule

The current head of the udidetect head does not include the udidetect binary.

If you are compelled to update, you _must rebuild and replace the scripts/udidetect_ binary.

At this time, there is no reason to update.

- [1] https://github.com/vaskas/udidetect/pull/3

## Building Device Agent Resources

It is your responsibility for checking the git branch.

```
$ rake device_agent:install
```

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

Take a break because these test launch and quit the simulator multiple
times.  You have enough time to take some deep breaths and do some
stretching.  You'll feel better afterward.

Make sure you have hardware keyboard disabled if testing on the simulator.

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
/Xcode/9.4.1/Xcode.app
/Xcode/10.0/Xcode.app
/Xcode/10.1/Xcode.app
/Xcode/10.2/Xcode-Beta.app
```

the rspec tests will do regression testing against each version.

##### Guard

Guard requires terminal-notifier-guard

https://github.com/Codaisseur/terminal-notifier-guard

```
$ brew install terminal-notifier-guard
$ be guard
```

Only the unit tests are run by guard.

