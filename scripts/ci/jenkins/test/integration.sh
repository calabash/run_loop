#!/usr/bin/env bash

set -e

# Integration tests
bundle exec run-loop simctl manage-processes
bundle exec rspec \
  spec/integration/core_simulator_spec.rb \
  spec/integration/xcode_spec.rb \
  spec/integration/otool_spec.rb \
  spec/integration/strings_spec.rb \
  spec/integration/app_spec.rb \
  spec/integration/codesign_spec.rb \
  spec/integration/core_spec.rb \
  spec/integration/simctl_spec.rb \
  spec/integration/device_agent/client_spec.rb
