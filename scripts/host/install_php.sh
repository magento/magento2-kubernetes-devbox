#!/usr/bin/env bash

# Copyright © Magento, Inc. All rights reserved.
# See COPYING.txt for license details.

cd "$(dirname "${BASH_SOURCE[0]}")/../.." && devbox_dir=$PWD

source "${devbox_dir}/scripts/functions.sh"

status "Installing PHP"
incrementNestingLevel

host_os="$(bash "${devbox_dir}/scripts/host/get_host_os.sh")"

#if [[ ${host_os} == "Windows" ]]; then
#    curl http://windows.php.net/downloads/releases/archives/php-5.6.9-nts-Win32-VC11-x86.zip -o "${devbox_dir}/lib/php.zip" 2> >(log) > >(log)
#    unzip -q "${devbox_dir}/lib/php.zip" -d "${devbox_dir}/lib/php" 2> >(log) > >(log)
#    rm -f "${devbox_dir}/lib/php.zip"
#    cp "${devbox_dir}/lib/php/php.ini-development" "${devbox_dir}/lib/php/php.ini"
#    sed -i.back 's|; extension_dir = "ext"|extension_dir = "ext"|g' "${devbox_dir}/lib/php/php.ini"
#    sed -i.back 's|;extension=php_openssl.dll|extension=php_openssl.dll|g' "${devbox_dir}/lib/php/php.ini"
#    rm -rf "${devbox_dir}/lib/php/*.back"
#fi

php_executable="$(bash "${devbox_dir}/scripts/host/get_path_to_php.sh")"
if ! ${php_executable} -v 2> >(log) | grep -q 'Copyright' ; then
    error "Automatic PHP installation is not available for your host OS. Please install any version of PHP to allow Magento dependencies management using Composer. Check out http://php.net/manual/en/install.php"
    decrementNestingLevel
    exit 1
else
    success "PHP installed successfully"
fi

decrementNestingLevel
