#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")/.." && devbox_dir=$PWD
source "${devbox_dir}/scripts/functions.sh"
variable_name=$1

# TODO: Avoid duplication with instance config parser
# Read configs
eval $(parse_yaml "${devbox_dir}/etc/env/config.yaml.dist")
if [[ -f "${devbox_dir}/etc/env/config.yaml" ]]; then
    eval $(parse_yaml "${devbox_dir}/etc/env/config.yaml")
fi

echo ${!variable_name}
