#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")/../.." && vagrant_dir=$PWD

source "${vagrant_dir}/scripts/functions.sh"

magento_app_code_dir="${vagrant_dir}/checkout/app/code/Magento"

cd "${magento_app_code_dir}"

status "Deleting TestModule directories"
ls | grep "TestModule" | xargs rm -rf

cd "${vagrant_dir}"

# TODO: parameterize container

executeInMagento2CheckoutContainer "${vagrant_dir}/scripts/guest/m-checkout-reinstall" 2> >(logError)
# TODO: run config set for checkout
# Explicit exit is necessary to bypass incorrect output from vagrant in case of errors
exit 0
