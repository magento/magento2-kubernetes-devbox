#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")/../.." && devbox_dir=$PWD

source "${devbox_dir}/scripts/functions.sh"

magento_app_code_dir="${devbox_dir}/magento/app/code/Magento"

if [[ -d "${magento_app_code_dir}" ]]; then
    cd "${magento_app_code_dir}"
    status "Deleting TestModule directories"
    ls | grep "TestModule" | xargs rm -rf
fi

cd "${devbox_dir}"

# TODO: parameterize container

executeInMagento2Container "${devbox_dir}/scripts/guest/m-reinstall" 2> >(logError)
# Explicit exit is necessary to bypass incorrect output from devbox in case of errors
exit 0
