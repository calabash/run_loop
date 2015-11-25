#!/usr/bin/env bash

# Fail if any command exits non-zero
set -e

function execute {
  echo "$(tput setaf 6)EXEC: $1 $(tput sgr0)"
  $1
}

execute "bundle exec run-loop simctl manage-processes"

