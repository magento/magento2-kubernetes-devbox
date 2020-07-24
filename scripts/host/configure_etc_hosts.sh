#!/usr/bin/env bash

# Copyright © Magento, Inc. All rights reserved.
# See COPYING.txt for license details.

set -e

cd "$(dirname "${BASH_SOURCE[0]}")/../.." && devbox_dir=$PWD

source "${devbox_dir}/scripts/functions.sh"
resetNestingLevel
current_script_name=`basename "$0"`
initLogFile ${current_script_name}

debug_devbox_project="$(bash "${devbox_dir}/scripts/get_env_config_value.sh" "debug_devbox_project")"
if [[ ${debug_devbox_project} -eq 1 ]]; then
    set -x
fi

# remove potentially stale configuration of the hosts configured by the dev box
for instance_name in $(getInstanceList); do
    domain_name="$(getInstanceDomainName ${instance_name})"
    sudo sed -ie "/.*${domain_name}.*/d" /etc/hosts
done

etc_hosts_records="$(bash "${devbox_dir}/scripts/host/get_etc_hosts_records.sh")"
# only split with new lines
IFS=$'\n'
for etc_hosts_record in $(bash "${devbox_dir}/scripts/host/get_etc_hosts_records.sh"); do
    if [[ -z "$(grep "${etc_hosts_record}" /etc/hosts)" ]]; then
        status "Adding '${etc_hosts_record}' to '/etc/hosts'"
        echo -e "${etc_hosts_record}\n$(cat /etc/hosts)" | sudo tee "/etc/hosts" 2> >(logError) > >(log)
    else
        warning "'${etc_hosts_record}' has already been added to '/etc/hosts' previously"
    fi
done
unset IFS

info "$(regular)See details in $(bold)${devbox_dir}/log/${current_script_name}.log$(regular). For debug output set $(bold)debug:devbox_project$(regular) to $(bold)1$(regular) in $(bold)etc/config.yaml$(regular)"
