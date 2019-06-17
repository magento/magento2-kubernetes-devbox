#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")/../.." && devbox_dir=$PWD

source "${devbox_dir}/scripts/functions.sh"

status "Initializing instance '$(getContext)'"
incrementNestingLevel

config_path="${devbox_dir}/etc/instance/$(getContext).yaml"

if [[ ! -f "${config_path}" ]]; then
    status "Initializing etc/instance/$(getContext).yaml using defaults from etc/instance/config.yaml.dist"
    cp "${devbox_dir}/etc/instance/config.yaml.dist" "${config_path}"
fi

magento_ce_dir="${devbox_dir}/$(getContext)"
magento_ce_sample_data_dir="${magento_ce_dir}/magento2ce-sample-data"
magento_ee_dir="${magento_ce_dir}/magento2ee"
magento_ee_sample_data_dir="${magento_ce_dir}/magento2ee-sample-data"
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

function checkoutSourceCodeFromGit()
{
    if [[ ! -d ${magento_ce_dir} ]]; then
#        if [[ ${host_os} == "Windows" ]]; then
#            status "Configuring git for Windows host"
#            git config --global core.autocrlf false
#            git config --global core.eol LF
#            git config --global diff.renamelimit 5000
#        fi

        initMagentoCeGit

        # By default EE repository is not specified and EE project is not checked out
        if [[ -n "${repository_url_ee}" ]]; then
            initMagentoEeGit
        fi

        initAdditionalGitRepositories
    fi
}

function initMagentoCeGit()
{
    initGitRepository ${repository_url_ce} "CE" "${magento_ce_dir}"
}

function initMagentoEeGit()
{
    initGitRepository ${repository_url_ee} "EE" "${magento_ee_dir}"
}

function initMagentoCeSampleGit()
{
    repository_url_ce_sample_data="$(bash "${devbox_dir}/scripts/get_config_value.sh" "repository_url_ce_sample_data")"
    initGitRepository ${repository_url_ce_sample_data} "CE sample data" "${magento_ce_sample_data_dir}"
}

function initAdditionalGitRepositories()
{
    repository_url_ce_sample_data="$(bash "${devbox_dir}/scripts/get_config_value.sh" "repository_url_ce_sample_data")"

    additional_repository_index=1
    current_additional_repo_name="$(bash "${devbox_dir}/scripts/get_config_value.sh" "repository_url_additional_repositories_${additional_repository_index}")"
    while [[ ! -z "${current_additional_repo_name}" ]]
    do
        initGitRepository "${current_additional_repo_name}" "${current_additional_repo_name}"

        ((additional_repository_index++))
        current_additional_repo_name="$(bash "${devbox_dir}/scripts/get_config_value.sh" "repository_url_additional_repositories_${additional_repository_index}")"
    done
}

function initMagentoEeSampleGit()
{
    initGitRepository ${repository_url_ee_sample_data} "EE sample data" "${magento_ee_sample_data_dir}"
}

# Initialize the cloning and checkout of a git repository
# Arguments:
#   Url of repository
#   Name of repository (CE, EE)
#   Directory where the repository will be cloned to
function initGitRepository()
{
    local repository_url=${1}
    local repository_name=${2}
    local directory=${3}

    if [[ ${repository_url} == *"::"* ]]; then
        local branch=$(getGitBranch ${repository_url})
        local repo=$(getGitRepository ${repository_url})
    else
        local repo=${repository_url}
    fi

    status "Checking out ${repository_name} repository"
    if [[ -z "${directory}" ]]; then
        pattern=".*\/(.*)\.git"
        if [[ ! ${repository_url} =~ ${pattern} ]]; then
            error "Specified repository URL is invalid: '${repository_url}'"
            exit 1
        fi
        directory="${magento_ce_dir}/${BASH_REMATCH[1]}"
    fi

    if [[ ${use_git_shallow_clone} -eq 1 ]] ; then
        git clone --depth 1 ${repo} "${directory}" 2> >(logError) > >(log)
    else
        git clone ${repo} "${directory}" 2> >(logError) > >(log)
        if [[ -n ${branch} ]]; then
            status "Checking out branch ${branch} of ${repository_name} repository"
            cd "${directory}"
            git fetch 2> >(logError) > >(log)
            git checkout ${branch} 2> >(log) > >(log)
        fi
    fi
    cd "${devbox_dir}"
}

# Get the git repository from a repository_url setting in $(getContext).yaml
function getGitRepository()
{
    local repo="${1%::*}" # Gets the substring before the '::' characters
    echo ${repo}
}

# Get the git branch from a repository_url setting in $(getContext).yaml
function getGitBranch()
{
    local branch="${1#*::}" # Gets the substring after the '::' characters
    echo ${branch}
}

function composerCreateProject()
{
    if [[ ! -d ${magento_ce_dir} ]]; then
        status "Downloading Magento codebase using 'composer create-project'"
        bash "${devbox_dir}/scripts/host/m_composer.sh" create-project ${composer_project_name} "${magento_ce_dir}" --repository-url=${composer_project_url}

#        # TODO: Workaround for Magento 2.2+ until PHP is upgraded to 7.1 on the guest
#        cd "${magento_ce_dir}"
#        composer_dir="${devbox_dir}/scripts/host"
#        composer_phar="${composer_dir}/composer.phar"
#        php_executable="$(bash "${devbox_dir}/scripts/host/get_path_to_php.sh")"
#        project_version="$("${php_executable}" "${composer_phar}" show --self | grep version)"
#        matching_version_pattern='2.[23].[0-9]+'
#        if [[ ${project_version} =~ ${matching_version_pattern} ]]; then
#            status "Composer require zendframework/zend-code:~3.1.0 (needed for Magento 2.2+ only)"
#            cd "${magento_ce_dir}"
#            bash "${devbox_dir}/scripts/host/m_composer.sh" require "zendframework/zend-code:~3.1.0"
#        fi
    fi
}

force_instance_cleaning=0
force_codebase_cleaning=0
while getopts 'ic' flag; do
  case "${flag}" in
    i) force_instance_cleaning=1 ;;
    c) force_codebase_cleaning=1 ;;
    *) error "Unexpected option" && exit 1;;
  esac
done

## Cleaning Magento instance
if [[ ${force_instance_cleaning} -eq 1 ]]; then
    if [[ ${force_codebase_cleaning} -eq 1 ]]; then
        status "Removing current Magento codebase before initialization since '-c' option was used"
        rm -rf "${magento_ce_dir}"
    fi
fi

cd "${devbox_dir}"

status "Configuring kubernetes cluster on the minikube"
# TODO: Optimize. Helm tiller must be initialized and started before environment configuration can begin
helm init --wait
#waitForKubernetesPodToRun 'tiller-deploy'

# TODO: Check if environment upgrade can be safely removed
bash "${devbox_dir}/scripts/host/k_upgrade_environment.sh"

if [[ ! -d ${magento_ce_dir} ]]; then
    if [[ "${checkout_source_from}" == "composer" ]]; then
        composerCreateProject
    elif [[ "${checkout_source_from}" == "git" ]]; then
        checkoutSourceCodeFromGit
    else
        error "Value specified for 'checkout_source_from' is invalid. Supported options: composer OR git"
        exit 1
    fi
fi

monolith_ip="$(minikube service magento2-monolith --url | grep -oE '[0-9][^:]+' | head -1)"
status "Saving Magento monolith container IP to etc/instance/$(getContext).yaml (${monolith_ip})"
sed -i.back "s|ip_address: \".*\"|ip_address: \"${monolith_ip}\"|g" "${config_path}"
sed -i.back "s|host_name: \".*\"|host_name: \"magento.$(getContext)\"|g" "${config_path}"
rm -f "${config_path}.back"

bash "${devbox_dir}/scripts/host/configure_etc_hosts.sh"

bash "${devbox_dir}/scripts/host/check_mounted_directories.sh"

bash "${devbox_dir}/scripts/host/configure_tests.sh"

#if [[ ${host_os} == "Windows" ]] || [[ ${use_nfs} == 0 ]]; then
#    # Automatic switch to EE during project initialization cannot be supported on Windows
#    status "Installing Magento CE"
#    bash "${devbox_dir}/scripts/host/m_reinstall.sh" 2> >(logError)
#else
    if [[ -n "${repository_url_ee}" ]]; then
        bash "${devbox_dir}/scripts/host/m_switch_to_ee.sh" -f 2> >(logError)
    else
        bash "${devbox_dir}/scripts/host/m_switch_to_ce.sh" -f 2> >(logError)
    fi
#fi

success "'$(getContext)' instance initialization completed"
