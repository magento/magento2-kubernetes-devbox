#!/usr/bin/env bash

# Copyright © Magento, Inc. All rights reserved.
# See COPYING.txt for license details.

cd "$(dirname "${BASH_SOURCE[0]}")/../.." && devbox_dir=$PWD

source "${devbox_dir}/scripts/functions.sh"

status "Checking requirements"
incrementNestingLevel

# Verify /etc/exports configuration for NFS
nfs_enabled="$(bash "${devbox_dir}/scripts/get_env_config_value.sh" "guest_use_nfs")"
nfs_exports_record="$(bash "${devbox_dir}/scripts/host/get_nfs_exports_record.sh")"
if [[ ${nfs_enabled} -eq 1 ]] && [[ -z "$(grep "${nfs_exports_record}" /etc/exports)" ]]; then
    warning "NFS exports configuration required on the host. Please execute 'bash ${devbox_dir}/scripts/host/configure_nfs_exports.sh' first."
    exit 1
fi

## Verify /etc/hosts configuration
#etc_hosts_records="$(bash "${devbox_dir}/scripts/host/get_etc_hosts_records.sh")"
## only split with new lines
#IFS=$'\n'
#for etc_hosts_record in $(bash "${devbox_dir}/scripts/host/get_etc_hosts_records.sh"); do
#    if [[ -z "$(grep "${etc_hosts_record}" /etc/hosts)" ]]; then
#        warning "'${etc_hosts_record}' record is missing in '/etc/hosts'. Please execute 'bash ${devbox_dir}/scripts/host/configure_etc_hosts.sh' first."
#        exit 1
#    fi
#done
#unset IFS

decrementNestingLevel
