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

nginx_servers_config_file="${devbox_dir}/etc/helm/templates/_nginx-servers.tpl"

status "Regenerating '${nginx_servers_config_file}'"

rm -f "${nginx_servers_config_file}"

echo '{{- define "common.nginx.servers.config" -}}' >> "${nginx_servers_config_file}"
echo '{{/* WARNING: Do not modify this file directly, it is auto-generated and any changes will be overwritten. */}}' >> "${nginx_servers_config_file}"

for instance_name in $(getInstanceList); do
    cat >> "${nginx_servers_config_file}" <<- LITERAL
server {
  listen "{{ .Values.global.monolith.service.nginxPort }}";
  server_name $(getInstanceDomainName ${instance_name});
  set \$MAGE_ROOT {{.Values.global.monolith.volumeHostPath}}/${instance_name};
  {{- include "common.nginx.config" . | nindent 2 }}
}
LITERAL
done
echo '{{- end -}}' >> "${nginx_servers_config_file}"

info "$(regular)See details in $(bold)${devbox_dir}/log/${current_script_name}.log$(regular). For debug output set $(bold)debug:devbox_project$(regular) to $(bold)1$(regular) in $(bold)etc/config.yaml$(regular)"
