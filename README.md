[![Build Status](https://travis-ci.org/calabash/run_loop.svg?branch=master)](https://travis-ci.org/calabash/run_loop) [![License](https://go-shields.herokuapp.com/license-MIT-blue.png)](http://opensource.org/licenses/MIT)

## run_loop

### Supported Xcode Versions

* Xcode >= 5.0
* RECOMMEND - Xcode >= 5.1

### License

run_loop is available under the MIT license. See the LICENSE file for more info.

### Versioning

run_loop follows the spirit of Semantic Versioning. [1]  However, the semantic versioning spec is incompatible with RubyGem's patterns for pre-release gems. [2]

_"But returning to the practical: No release version of SemVer is compatible with Rubygems."_ - David Kellum

- [1] http://semver.org/
- [2] http://gravitext.com/2012/07/22/versioning.html

### IMPORTANT note to devs RE: udidetect submodule

The current head of the udidetect head does not include the udidetect binary.

If you are compelled to update, you _must rebuild and replace the scripts/udidetect_ binary.

At this time, there is no reason to update.

- [1] https://github.com/vaskas/udidetect/pull/3

### possibily helpful tools

* simctl
* sim
* projectInfo

### Guard

Requires MacOS Growl - available in the AppStore.

Will run the rspec tests automatically when files change.

```
$ bundle exec guard  start --no-interactions
```