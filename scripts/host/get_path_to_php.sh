#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")/../.." && devbox_dir=$PWD

source "${devbox_dir}/scripts/functions.sh"
incrementNestingLevel

# Find path to available PHP
if [[ -f "${devbox_dir}/lib/php/php.exe" ]]; then
    php_executable="${devbox_dir}/lib/php/php"
else
    php_executable="php"
fi
echo ${php_executable}

decrementNestingLevel
