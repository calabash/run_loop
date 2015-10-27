#!/usr/bin/env bash

rbenv local 2.2.3
gem uninstall -Vax --force --no-abort-on-dependent run_loop
bundle update
rm -rf spec/reports
rbenv exec bundle exec rake spec

