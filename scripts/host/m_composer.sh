#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")/../.." && devbox_dir=$PWD

source "${devbox_dir}/scripts/functions.sh"

cd "${devbox_dir}"

# TODO: parameterize container

arguments=$@
executeInMagento2Container -- "${devbox_dir}/scripts/guest/composer.sh" ${arguments}
