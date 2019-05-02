#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")/../.." && devbox_dir=$PWD

source "${devbox_dir}/scripts/functions.sh"
incrementNestingLevel

# TODO: Calculate network IP
host_os="$(bash "${devbox_dir}/scripts/host/get_host_os.sh")"
if [[ ${host_os} == "OSX" ]]; then
    nfs_exports_record="\"${devbox_dir}\" -alldirs -mapall=$(id -u):$(id -g) -mask 255.0.0.0 -network 192.0.0.0"
elif [[ ${host_os} == "Linux" ]]; then
    nfs_exports_record="\"${devbox_dir}\" 172.17.0.0/255.255.0.0(rw,no_subtree_check,all_squash,anonuid=$(id -u),anongid=$(id -g))"
else
    error "Host OS is not supported"
    exit 1
fi

echo "${nfs_exports_record}"

decrementNestingLevel
