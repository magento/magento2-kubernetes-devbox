#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")/.." && devbox_dir=$PWD
source "${devbox_dir}/scripts/functions.sh"
variable_name=$1

# Read configs
eval $(parse_yaml "${devbox_dir}/etc/instance/config.yaml.dist")
if [[ -f "${devbox_dir}/etc/instance/$(getContext).yaml" ]]; then
    eval $(parse_yaml "${devbox_dir}/etc/instance/$(getContext).yaml")
fi

echo ${!variable_name}
