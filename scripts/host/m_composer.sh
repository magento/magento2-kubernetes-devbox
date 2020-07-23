#!/usr/bin/env bash

# Copyright © Magento, Inc. All rights reserved.
# See COPYING.txt for license details.

cd "$(dirname "${BASH_SOURCE[0]}")/../.." && devbox_dir=$PWD

source "${devbox_dir}/scripts/functions.sh"

cd "${devbox_dir}"

# TODO: parameterize container

arguments=$@
executeInMagento2Container -- "${devbox_dir}/scripts/guest/composer.sh" ${arguments}
