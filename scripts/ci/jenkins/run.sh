#!/usr/bin/env bash

if [ -n "${JENKINS_HOME}" ]; then
  rbenv local 2.3.0
  gem uninstall -Vax --force --no-abort-on-dependent run_loop
fi

rm -rf spec/reports

if [ -n "${JENKINS_HOME}" ]; then
  RBENV_EXEC="rbenv exec"
else
  RBENV_EXEC=
fi

$RBENV_EXEC bundle update

# Unit tests
$RBENV_EXEC bundle exec run-loop simctl manage-processes
$RBENV_EXEC bundle exec rspec spec/lib

# Integration tests
$RBENV_EXEC bundle exec run-loop simctl manage-processes
$RBENV_EXEC bundle exec rspec \
  spec/integration/core_simulator_spec.rb \
  spec/integration/xcode_spec.rb \
  spec/integration/otool_spec.rb \
  spec/integration/strings_spec.rb

# CLI tests

# Fail if any command exits non-zero
set -e

function execute {
  echo "$(tput setaf 6)EXEC: $1 $(tput sgr0)"
  $1
}

execute "$RBENV_EXEC bundle exec run-loop version"
execute "$RBENV_EXEC bundle exec run-loop help"
execute "$RBENV_EXEC bundle exec run-loop instruments help"
execute "$RBENV_EXEC bundle exec run-loop simctl help"


