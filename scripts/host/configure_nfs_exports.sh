#!/usr/bin/env bash

set -e

cd "$(dirname "${BASH_SOURCE[0]}")/../.." && devbox_dir=$PWD

source "${devbox_dir}/scripts/functions.sh"
resetNestingLevel
current_script_name=`basename "$0"`
initLogFile ${current_script_name}

debug_devbox_project="$(bash "${devbox_dir}/scripts/get_config_value.sh" "debug_devbox_project")"
if [[ ${debug_devbox_project} -eq 1 ]]; then
    set -x
fi

nfs_enabled="$(bash "${devbox_dir}/scripts/get_config_value.sh" "guest_use_nfs")"
if [[ ${nfs_enabled} -eq 0 ]]; then
    status "Skipping NFS configuration per config.yaml"
    exit 0
fi

userId=$(id -u)
if [[ ${userId} -eq 0 ]]; then
    error "${devbox_dir}/scripts/host/configure_nfs_exports.sh MUST NOT be run with sudo. Run it from unprivileged user and enter password when prompted."
    exit 1
fi

host_os="$(bash "${devbox_dir}/scripts/host/get_host_os.sh")"
nfs_exports_record="$(bash "${devbox_dir}/scripts/host/get_nfs_exports_record.sh")"
if [[ ${host_os} == "OSX" ]]; then
    if [[ -z "$(grep "${nfs_exports_record}" /etc/exports)" ]]; then
        status "Updating /etc/exports to enable codebase sharing with containers via NFS (${nfs_exports_record})"
        echo "${nfs_exports_record}" | sudo tee -a "/etc/exports" 2> >(logError) > >(log)
        sudo nfsd restart
        # TODO: Implement NFS exports clean up on project removal to prevent NFS mounting errors
    else
        warning "NFS exports are properly configured and do not need to be updated"
    fi
fi

if [[ ${host_os} == "Linux" ]]; then
    if [[ -z "$(grep "${nfs_exports_record}" /etc/exports)" ]]; then
        status "Updating /etc/exports to enable codebase sharing with containers via NFS (${nfs_exports_record})"
        echo "${nfs_exports_record}" | sudo tee -a "/etc/exports" 2> >(logError) > >(log)
        sudo service nfs-kernel-server restart
        # TODO: Implement NFS exports clean up on project removal to prevent NFS mounting errors
    else
        warning "NFS exports are properly configured and do not need to be updated"
    fi
fi

info "$(regular)See details in $(bold)${devbox_dir}/log/${current_script_name}.log$(regular). For debug output set $(bold)debug:devbox_project$(regular) to $(bold)1$(regular) in $(bold)etc/config.yaml$(regular)"
