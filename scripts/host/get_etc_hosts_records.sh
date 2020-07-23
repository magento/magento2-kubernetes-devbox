#!/usr/bin/env bash

# Copyright © Magento, Inc. All rights reserved.
# See COPYING.txt for license details.

cd "$(dirname "${BASH_SOURCE[0]}")/../.." && devbox_dir=$PWD

source "${devbox_dir}/scripts/functions.sh"
incrementNestingLevel

# TODO: Calculate network IP
host_os="$(bash "${devbox_dir}/scripts/host/get_host_os.sh")"
if [[ ${host_os} == "OSX" ]] || [[ ${host_os} == "Linux" ]]; then
    host_ip="$(minikube ip)"
    etc_host_records=""
    for instance_name in $(getInstanceList); do
        etc_host_records="${etc_host_records}\n${host_ip} $(getInstanceDomainName ${instance_name})"
    done
    # Using sed to remove empty lines if any
    echo -e "${etc_host_records}" | sed '/^$/d'
else
    error "Host OS is not supported"
    exit 1
fi

decrementNestingLevel
