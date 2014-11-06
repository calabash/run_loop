## Contributing

***All pull requests should be based off the `develop` branch.***

The Calabash iOS Toolchain uses git-flow.

See these links for information about git-flow and git best practices.

##### Git Flow Step-by-Step guide

* https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow

##### Git Best Practices

* http://justinhileman.info/article/changing-history/

##### git-flow command line tool

We don't use the git-flow tools, but this is useful anyway.

* http://danielkummer.github.io/git-flow-cheatsheet/

## Start a Feature

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

### Create the release branch

```
$ git co develop
$ git pull
$ git checkout -b release-<next number> develop
```

No more features can be added.  All in-progress features and un-merged pull-requests must wait for the next release.

You can, and should, make changes to the documentation.  You can bump the gem version.

### Create a pull request for the release branch

Do this very soon after you make the release branch to notify the team that you are planning a release.

```
$ git push -u origin release-<next number>
```

Again, no more features can be added to this pull request.  Only changes to documentation are allowed.  You can bump the gem version.

### Cut a new release

```
# Make sure all pull requests have been merged to `develop`
# Check CI!
# * https://travis-ci.org/calabash/run_loop
# * http://ci.endoftheworl.de:8080/ # Briar jobs.

# Get the latest develop.

$ git fetch
$ git co develop
$ git pull origin develop

# Make a release branch.

$ git co develop
$ git co -b release/1.1.0

# *** Bump the version in lib/version! ***
# *** Add changes to CHANGELOG.md ***
$ git push -u origin release

# *** Make pull request targeting _master_ (not develop) ***
# *** Let CI run. ***
# *** Merge the PR. ***

$ git co master
$ git pull
$ gem update --system
$ rake release

# Clean up.

$ git co develop
$ git merge --no-ff release/1.1.0
$ git push
$ git br -d release/1.1.0

# Celebrate.
```