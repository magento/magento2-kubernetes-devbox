#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")/../.." && vagrant_dir=$PWD

source "${vagrant_dir}/scripts/functions.sh"

status "Checking requirements"
incrementNestingLevel

nfs_enabled="$(bash "${vagrant_dir}/scripts/get_config_value.sh" "guest_use_nfs")"
nfs_exports_record="$(bash "${vagrant_dir}/scripts/host/get_nfs_exports_record.sh")"
if [[ ${nfs_enabled} -eq 1 ]] && [[ -z "$(grep "${nfs_exports_record}" /etc/exports)" ]]; then
    warning "NFS exports configuration required on the host. Please execute 'bash ${vagrant_dir}/scripts/host/configure_nfs_exports.sh' first."
    exit 1
fi

decrementNestingLevel
