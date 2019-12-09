#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")/../.." && devbox_dir=$PWD

cd "${devbox_dir}"
cp ./tests/include/configuration.sh.dist ./tests/include/configuration.sh
sed -i "s|git@github.com:|https://github.com/|g" ./etc/instance/config.yaml.dist
find ./tests/_files/ -type f | xargs sed -i "s|git@github.com:|https://github.com/|g"
sed -i "s|php_executable=\"php\"|php_executable=\"/home/travis/.phpenv/shims/php\"|g" ./scripts/host/get_path_to_php.sh
# TODO: Make configurable and enable for specific tests
# sed -i "s|git clone|git clone --depth 1 |g" ./init_project.sh
sed -i "s|minikube start --kubernetes-version=v1.15.6 -v=0 --cpus=2 --memory=4096|sudo minikube start --kubernetes-version=v1.15.6 -v=0 --cpus=2 --memory=4096  --vm-driver=none --bootstrapper=kubeadm|g" ./init_project.sh
sed -i "s|&& eval \$(minikube docker-env) ||g" ./scripts/host/k_install_environment.sh
sed -i "s|&& eval \$(minikube docker-env) ||g" ./scripts/host/k_upgrade_environment.sh
sed -i "s/use_nfs:\ 1/use_nfs:\ 0/g" ./etc/env/config.yaml.dist
sed -i "s/nfs_server_ip:\ \"0\.0\.0\.0\"/nfs_server_ip:\ \"$(ip -4 addr show docker0 | grep -Po 'inet \K[\d.]+')\"/g" ./etc/env/config.yaml.dist
echo "${COMPOSER_AUTH}" > ./etc/composer/auth.json
