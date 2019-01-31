#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")/../.." && vagrant_dir=$PWD

source "${vagrant_dir}/scripts/functions.sh"

## TODO: Add status messages
cd "${vagrant_dir}/scripts" && eval $(minikube docker-env) && docker build -t magento2-monolith:dev -f ../etc/docker/monolith/Dockerfile ../scripts
cd "${vagrant_dir}/scripts" && eval $(minikube docker-env) && docker build -t magento2-monolith:dev-xdebug -f ../etc/docker/monolith-with-xdebug/Dockerfile ../scripts

# TODO: Repeat for other deployments, not just Magento 2
# See https://github.com/kubernetes/kubernetes/issues/33664#issuecomment-386661882


# TODO: Delete does not work when no releases created yet
cd "${vagrant_dir}/etc/helm"
set +e
helm list -q | xargs helm delete --purge
set -e

# TODO: Need to make sure all resources have been successfully deleted before the attempt of recreating them
sleep 7
enable_nfs="true"
enable_checkout="false"
while getopts 'de' flag; do
  case "${flag}" in
    d) enable_nfs="false" ;;
    e) enable_checkout="true" ;;
    *) error "Unexpected option" && exit 1;;
  esac
done
cd "${vagrant_dir}/etc/helm" && helm install \
    --name magento2 \
    --values values.yaml \
    --set global.monolith.volumeHostPath="${vagrant_dir}" \
    --set global.persistence.nfs.enabled="${enable_nfs}" \
    --set global.checkout.enabled="${enable_checkout}" \
    --set global.checkout.volumeHostPath="${vagrant_dir}" .

# TODO: Waiting for containers to initialize before proceeding
waitForKubernetesPodToRun 'magento2-monolith'
waitForKubernetesPodToRun 'magento2-mysql'
waitForKubernetesPodToRun 'magento2-redis-master'

exit 0
