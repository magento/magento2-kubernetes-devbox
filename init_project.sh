#!/usr/bin/env bash

# Copyright © Magento, Inc. All rights reserved.
# See COPYING.txt for license details.

set -e

devbox_dir=$PWD

source "${devbox_dir}/scripts/functions.sh"
resetNestingLevel
current_script_name=`basename "$0"`
initLogFile ${current_script_name}

config_path="${devbox_dir}/etc/env/config.yaml"
if [[ ! -f "${config_path}" ]]; then
    status "Initializing etc/env/config.yaml using defaults from etc/env/config.yaml.dist"
    cp "${devbox_dir}/etc/env/config.yaml.dist" "${config_path}"
fi

debug_devbox_project="$(bash "${devbox_dir}/scripts/get_env_config_value.sh" "debug_devbox_project")"
if [[ ${debug_devbox_project} -eq 1 ]]; then
    set -x
fi

# Copyright © Magento, Inc. All rights reserved.
# See COPYING.txt for license details.

# TODO: remove references to context
host_os="$(bash "${devbox_dir}/scripts/host/get_host_os.sh")"
use_nfs="$(bash "${devbox_dir}/scripts/get_env_config_value.sh" "guest_use_nfs")"
nfs_server_ip="$(bash "${devbox_dir}/scripts/get_env_config_value.sh" "guest_nfs_server_ip")"
repository_url_ce="$(bash "${devbox_dir}/scripts/get_config_value.sh" "repository_url_ce")"
#repository_url_checkout="$(bash "${devbox_dir}/scripts/get_config_value.sh" "repository_url_checkout")"
repository_url_ee="$(bash "${devbox_dir}/scripts/get_config_value.sh" "repository_url_ee")"
composer_project_name="$(bash "${devbox_dir}/scripts/get_config_value.sh" "composer_project_name")"
composer_project_url="$(bash "${devbox_dir}/scripts/get_config_value.sh" "composer_project_url")"
checkout_source_from="$(bash "${devbox_dir}/scripts/get_config_value.sh" "checkout_source_from")"
use_git_shallow_clone="$(bash "${devbox_dir}/scripts/get_config_value.sh" "repository_url_shallow_clone")"

bash "${devbox_dir}/scripts/host/check_requirements.sh"

# Clean up the project before initialization if "-f" option was specified. Remove codebase if "-fc" is used.
force_project_cleaning=0
force_instance_cleaning=0
force_codebase_cleaning=0
force_phpstorm_config_cleaning=0
while getopts 'ficp' flag; do
  case "${flag}" in
    f) force_project_cleaning=1 ;;
    i) force_instance_cleaning=1 ;;
    c) force_codebase_cleaning=1 ;;
    p) force_phpstorm_config_cleaning=1 ;;
    *) error "Unexpected option" && exit 1;;
  esac
done

## Cleaning Environment
if [[ ${force_project_cleaning} -eq 1 ]]; then
    status "Cleaning up the project before initialization since '-f' option was used"

    if [[ $(isMinikubeRunning) -eq 1 ]]; then
        minikube stop 2> >(logError) | {
          while IFS= read -r line
          do
            filterDevboxOutput "${line}"
            lastline="${line}"
          done
          filterDevboxOutput "${lastline}"
        }
    fi
    if [[ $(isMinikubeStopped) -eq 1 ]]; then
        minikube delete 2> >(logError) | {
          while IFS= read -r line
          do
            filterDevboxOutput "${line}"
            lastline="${line}"
          done
          filterDevboxOutput "${lastline}"
        }
    fi

    cd "${devbox_dir}/log" && mv email/.gitignore email_gitignore.back && rm -rf email && mkdir email && mv email_gitignore.back email/.gitignore
fi

status "Initializing dev box"
cd "${devbox_dir}"

#if [[ $(isMinikubeInitialized) -eq 1 ]]; then
#    warning "The project has already been initialized.
#    To re-initialize the project add the '-f' flag (using just '-f' will not affect Magento codebase or PHP Storm settings).
#    To delete Magento codebase and initialize it from scratch based on etc/instance/$(getContext).yaml add '-c' flag.
#    To reconfigure PHP Storm add '-p' flag."
#    exit 0
#fi

# TODO: Verify that this condition works as expected
if [[ ! $(isMinikubeRunning) -eq 1 ]]; then
    status "Starting minikube"
    minikube start --kubernetes-version=v1.15.6 -v=0 --cpus=2 --memory=4096
    minikube config set kubernetes-version v1.15.6
    minikube addons enable ingress
fi

config_content="$(cat ${config_path})"
default_nfs_server_ip_pattern="nfs_server_ip: \"0\.0\.0\.0\""
if [[ ! ${config_content} =~ ${default_nfs_server_ip_pattern} ]]; then
    status "Custom NFS server IP is already specified in '${config_path}' (${nfs_server_ip})"
else
    nfs_server_ip="$(minikube ip | grep -oh ^[0-9]*\.[0-9]*\.[0-9]*\. | head -1 | awk '{print $1"1"}')"
    status "Saving NFS server IP to '${config_path}' (${nfs_server_ip})"
    sed -i.back "s|${default_nfs_server_ip_pattern}|nfs_server_ip: \"${nfs_server_ip}\"|g" "${config_path}"
    rm -f "${config_path}.back"
fi

# Hosts must be configured before cluster is started
instance_names=$(getInstanceList)
if [[ -z ${instance_names} ]]; then
    instance_names="default"
fi
bash "${devbox_dir}/scripts/host/configure_etc_hosts.sh"

status "Configuring kubernetes cluster on the minikube"
# TODO: Optimize. Helm tiller must be initialized and started before environment configuration can begin
helm init --wait
#waitForKubernetesPodToRun 'tiller-deploy'

# TODO: Do not clean up environment when '-f' flag was not specified
bash "${devbox_dir}/scripts/host/k_install_environment.sh"

if [[ ${force_project_cleaning} -eq 1 ]] && [[ ${force_phpstorm_config_cleaning} -eq 1 ]]; then
    status "Resetting PhpStorm configuration since '-p' option was used"
    rm -rf "${devbox_dir}/.idea"
fi

#if [[ ! -f "${devbox_dir}/.idea/deployment.xml" ]]; then
# TODO: Implement PhpStorm configuration
#    bash "${devbox_dir}/scripts/host/configure_php_storm.sh"
#fi

# Iterate over all requested instances and initialize them
for instance_name in ${instance_names}; do
    setContext ${instance_name}

    bash "${devbox_dir}/scripts/host/m_composer.sh" global require "hirak/prestissimo"

    flags=""
    if [[ ${force_instance_cleaning} -eq 1 ]]; then
        flags="${flags}i"
    fi
    if [[ ${force_codebase_cleaning} -eq 1 ]]; then
        flags="${flags}c"
    fi
    if [[ ! -z ${flags} ]]; then
        flags="-${flags}"
    fi

    bash "${devbox_dir}/scripts/host/init_instance.sh" "${flags}"
done

success "Project initialization completed (make sure there are no errors in the log above)"

info "$(bold)[Important]$(regular)
    Please use $(bold)${devbox_dir}$(regular) directory as PhpStorm project root, NOT $(bold)${devbox_dir}/$(getContext)$(regular)."

#if [[ ${host_os} == "Windows" ]] || [[ ${use_nfs} == 0 ]]; then
#    info "$(bold)[Optional]$(regular)
#    To verify that deployment configuration for $(bold)${magento_ce_dir}$(regular) in PhpStorm is correct,
#        use instructions provided here: $(bold)https://github.com/paliarush/magento2-vagrant-for-developers/blob/2.0/docs/phpstorm-configuration-windows-hosts.md$(regular).
#    If not using PhpStorm, you can set up synchronization using rsync"
#fi

info "$(regular)See details in $(bold)${devbox_dir}/log/${current_script_name}.log$(regular). For debug output set $(bold)debug:devbox_project$(regular) to $(bold)1$(regular) in $(bold)etc/config.yaml$(regular)"
