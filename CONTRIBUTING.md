## Contributing

***All pull requests should be based off the `develop` branch.***

The Calabash iOS Toolchain uses git-flow.

See these links for information about git-flow and git best practices.

* http://danielkummer.github.io/git-flow-cheatsheet/
* https://www.atlassian.com/git/workflows#!workflow-gitflow
* http://justinhileman.info/article/changing-history/

All pull requests should be based off the `develop` branch.

Start your work on a feature branch based off develop.

```
# If you don't already have the develop branch
$ git fetch origin
$ git co -t origin/develop

# If you already have the develop branch
$ git co develop
$ git pull origin develop
$ git co -b feature/my-new-feature

# Publish your branch and make a pull-request on `develop`
$ git push -u origin feature/my-new-feature
```

## Releasing

At the moment we are not using release branches; we will cut releases by merging develop into master.

```
# Make sure all pull requests have been merged to `develop`
# Check CI!
# * https://travis-ci.org/calabash/run_loop
# * http://ci.endoftheworl.de:8080/ # Briar jobs.

# Get the latest develop.
$ git co develop
$ git pull origin develop

# Get the latest master. If all is well, there should be no changes in master!
$ git co master
$ git pull origin master

# Merge develop into master, run the tests and push.
$ git merge develop
$ be rake rspec

# All is well!
$ git push origin master
$ gem update --system
$ rake release
```




