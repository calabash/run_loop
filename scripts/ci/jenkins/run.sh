#!/usr/bin/env bash

bundle update
bundle exec run-loop simctl manage-processes
scripts/ci/jenkins/rspec-unit.sh
scripts/ci/jenkins/cli.sh

