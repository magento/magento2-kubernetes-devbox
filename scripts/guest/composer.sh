#!/usr/bin/env bash

# This script allows to use credentials specified in etc/composer/auth.json without declaring them globally

cd "$(dirname "${BASH_SOURCE[0]}")/../.." && devbox_dir=$PWD

source "${devbox_dir}/scripts/functions.sh"

status "Executing composer command"
incrementNestingLevel

composer_auth_json="${devbox_dir}/etc/composer/auth.json"

if [[ -f ${composer_auth_json} ]]; then
    status "Exporting etc/auth.json to environment variable"
    export COMPOSER_AUTH="$(cat "${composer_auth_json}")"
fi

if [[ -d "${DEVBOX_ROOT}/$(getContext)" ]]; then
    cd "${DEVBOX_ROOT}/$(getContext)"
fi

status "composer --no-interaction "$@""
composer --no-interaction "$@"

decrementNestingLevel
