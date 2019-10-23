#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")/../.." && devbox_dir=$PWD

source "${devbox_dir}/scripts/functions.sh"

## TODO: Add status messages
cd "${devbox_dir}/scripts" && eval $(minikube docker-env --shell=bash) && docker build -t magento2-monolith:dev -f ../etc/docker/monolith/Dockerfile ../scripts
cd "${devbox_dir}/scripts" && eval $(minikube docker-env --shell=bash) && docker build -t magento2-monolith:dev-xdebug -f ../etc/docker/monolith-with-xdebug/Dockerfile ../scripts
cd "${devbox_dir}/scripts" && eval $(minikube docker-env --shell=bash) && docker build -t magento2-monolith:dev-xdebug-and-ssh -f ../etc/docker/monolith-with-xdebug-and-ssh/Dockerfile ../scripts

# TODO: Repeat for other deployments, not just Magento 2
# See https://github.com/kubernetes/kubernetes/issues/33664#issuecomment-386661882

nfs_server_ip="$(bash "${devbox_dir}/scripts/get_env_config_value.sh" "guest_nfs_server_ip")"
use_varnish="$(bash "${devbox_dir}/scripts/get_env_config_value.sh" "environment_use_varnish")"
use_nfs="$(bash "${devbox_dir}/scripts/get_env_config_value.sh" "guest_use_nfs")"

bash "${devbox_dir}/scripts/host/configure_nginx_servers.sh"

status "Upgrading cluster, it may take several minutes"

# TODO: Eliminate code duplication with k_install_environment
# Calculate coma-separated list of magento host names
etc_host_records=""
for instance_name in $(getInstanceList); do
    etc_host_records="${etc_host_records}\, \"$(getInstanceDomainName ${instance_name})\""
done
magentoHostnames="[$(echo "${etc_host_records}" | sed 's/^\\, //g')]"

cd "${devbox_dir}/etc/helm" && helm upgrade \
    --values values.yaml \
    --wait \
    --set global.persistence.nfs.serverIp="${nfs_server_ip}" \
    --set global.monolith.volumeHostPath="${devbox_dir}" \
    --set global.persistence.nfs.enabled="$(if [[ ${use_nfs} == "1" ]]; then echo "true"; else echo "false"; fi)" \
    --set global.caching.varnish.enabled="$(if [[ ${use_varnish} == "1" ]]; then echo "true"; else echo "false"; fi)" \
    --set global.dns.magentoHosts.ip="$(minikube ip)" \
    --set global.dns.magentoHosts.hostnames="${magentoHostnames}" \
    magento2 \
    .

exit 0
