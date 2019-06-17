#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")/../.." && devbox_dir=$PWD

source "${devbox_dir}/scripts/functions.sh"

cd "${devbox_dir}"
#if [[ ! -f "${devbox_dir}/$(getContext)/composer.json" ]]; then
#    error "Directory '${devbox_dir}/$(getContext)' was not mounted as expected by Devbox.
#        Please make sure that 'paliarush/magento2.ubuntu' Devbox box was downloaded successfully (if not, this may help http://stackoverflow.com/questions/35519389${devbox_dir}-cannot-find-box)
#        And that Devbox is able to mount VirtualBox shared folders on your environment (see https://www.devboxup.com/docs/synced-folders/basic_usage.html ).
#        Also remove any stale declarations from /etc/exports on the host."
#    exit 1
#fi
executeInMagento2Container bash -- "${devbox_dir}/scripts/guest/check_mounted_directories" 2> >(logError)
# Explicit exit is necessary to bypass incorrect output from devbox in case of errors
exit 0
