#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")/../.." && devbox_dir=$PWD

source "${devbox_dir}/scripts/functions.sh"

## TODO: Add status messages
cd "${devbox_dir}/scripts" && eval $(minikube docker-env) && docker build -t magento2-monolith:dev -f ../etc/docker/monolith/Dockerfile ../scripts
cd "${devbox_dir}/scripts" && eval $(minikube docker-env) && docker build -t magento2-monolith:dev-xdebug -f ../etc/docker/monolith-with-xdebug/Dockerfile ../scripts

# TODO: Repeat for other deployments, not just Magento 2
# See https://github.com/kubernetes/kubernetes/issues/33664#issuecomment-386661882


# TODO: Delete does not work when no releases created yet
cd "${devbox_dir}/etc/helm"
set +e
helm list -q | xargs helm delete --purge 2>/dev/null
set -e

# TODO: Need to make sure all resources have been successfully deleted before the attempt of recreating them
#sleep 20
enable_checkout="false"
while getopts 'e' flag; do
  case "${flag}" in
    e) enable_checkout="true" ;;
    *) error "Unexpected option" && exit 1;;
  esac
done

nfs_server_ip="$(bash "${devbox_dir}/scripts/get_config_value.sh" "guest_nfs_server_ip")"
echo "NFS server IP: ${nfs_server_ip}"
use_nfs="$(bash "${devbox_dir}/scripts/get_config_value.sh" "guest_use_nfs")"
cd "${devbox_dir}/etc/helm" && helm install \
    --name magento2 \
    --values values.yaml \
    --wait \
    --set global.persistence.nfs.serverIp="${nfs_server_ip}" \
    --set global.monolith.volumeHostPath="${devbox_dir}" \
    --set global.persistence.nfs.enabled="$(if [[ ${use_nfs} == "1" ]]; then echo "true"; else echo "false"; fi)" \
    --set global.checkout.enabled="${enable_checkout}" \
    --set global.checkout.volumeHostPath="${devbox_dir}" .

# TODO: Waiting for containers to initialize before proceeding
#waitForKubernetesPodToRun 'tiller-deploy'
#waitForKubernetesPodToRun 'magento2-monolith'
#waitForKubernetesPodToRun 'magento2-mysql'
#waitForKubernetesPodToRun 'magento2-redis-master'

#sleep 20

exit 0
