#!/bin/bash
set -e

echo "# Running Basic test suite"
bash ./testsuite-basic.sh
if [[ "${TRAVIS_EVENT_TYPE}" = "cron" ]] || [[ "${RUN_EXTENDED_TEST_SUITE}" = "true" ]]; then
    echo '# Running extended test suite'
    bash ./testsuite-extended.sh
fi
