#!/bin/bash
set -ev

bash ./testsuite.sh

if [ "${TRAVIS_PULL_REQUEST}" = "false" ]; then
  bundle exec rake test:integration
fi
