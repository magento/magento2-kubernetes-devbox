#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")/../.." && vagrant_dir=$PWD

source "${vagrant_dir}/scripts/functions.sh"

cd "${vagrant_dir}"

# TODO: parameterize container

arguments=$@
executeInMagento2CheckoutContainer -- "${vagrant_dir}/scripts/guest/composer_checkout.sh" ${arguments} 2> >(logError)
