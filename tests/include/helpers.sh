#! /usr/bin/env bash

function installEnvironment()
{
    clearTestTmp
    downloadDevboxProject
    configureDevboxProject
    deployDevboxProject
}

function installEnvironmentWithUpgrade()
{
    clearTestTmp
    downloadBaseVersionOfDevboxProject
    configureDevboxProject
    deployDevboxProject
    upgradeDevboxProject
}

function downloadDevboxProject()
{
    cd ${tests_dir}
    if [[ ! -z "${devbox_project_local_path}" ]]; then
        echo "${grey}## copyDevboxProjectFromLocalPath${regular}"
        echo "## copyDevboxProjectFromLocalPath" >>${current_log_file_path}
        rm -rf "${devbox_dir}" && mkdir -p "${devbox_dir}"
        rsync -a --exclude=".git" --exclude="tests" --exclude="magento" "${devbox_project_local_path}/" "${devbox_dir}"
    else
        echo "${grey}## downloadDevboxProject${regular}"
        echo "## downloadDevboxProject" >>${current_log_file_path}
        git clone ${devbox_project_repository_url} "${devbox_dir}" >>${current_log_file_path} 2>&1
        cd "${devbox_dir}"
        git checkout ${devbox_project_branch} >>${current_log_file_path} 2>&1
    fi
}

function downloadBaseVersionOfDevboxProject()
{
    echo "${grey}## downloadBaseVersionOfDevboxProject${regular}"
    echo "## downloadBaseVersionOfDevboxProject" >>${current_log_file_path}
    cd ${tests_dir}
    git clone git@github.com:paliarush/magento2-vagrant-for-developers.git "${devbox_dir}" >>${current_log_file_path} 2>&1
    cd "${devbox_dir}"
    git checkout tags/v2.2.0 >>${current_log_file_path} 2>&1
    # Make sure that older box version is used
    sed -i.back 's|config.vm.box_version = "~> 1.0"|config.vm.box_version = "= 1.0"|g' "${devbox_dir}/Devboxfile" >>${current_log_file_path} 2>&1
    echo '{"github-oauth": {"github.com": "sampletoken"}}' >"${devbox_dir}/etc/composer/auth.json"
}

function upgradeDevboxProject()
{
    echo "${grey}## upgradeDevboxProject${regular}"
    echo "## upgradeDevboxProject" >>${current_log_file_path}
    # Reset changes done to box version requirements
    git checkout "${devbox_dir}/Devboxfile" >>${current_log_file_path} 2>&1
    cd "${devbox_dir}"
    git remote add repository-under-test ${devbox_project_repository_url} >>${current_log_file_path} 2>&1
    git fetch repository-under-test >>${current_log_file_path} 2>&1
    git checkout -b branch-under-test repository-under-test/${devbox_project_branch} >>${current_log_file_path} 2>&1
    devbox reload >>${current_log_file_path} 2>&1
}

function upgradeComposerBasedMagento()
{
    cd "${devbox_dir}"
    echo "${grey}## upgradeComposerBasedMagento (to 2.1.2)${regular}"
    echo "## upgradeComposerBasedMagento (to 2.1.2)" >>${current_log_file_path}
    bash m-composer require magento/product-community-edition 2.1.2 --no-update >>${current_log_file_path} 2>&1
    bash m-switch-to-ce -fu >>${current_log_file_path} 2>&1
    echo "${grey}## upgradeComposerBasedMagento (to 2.1.3)${regular}"
    echo "## upgradeComposerBasedMagento (to 2.1.3)" >>${current_log_file_path}
    bash m-composer require magento/product-community-edition 2.1.3 --no-update >>${current_log_file_path} 2>&1
    bash m-switch-to-ee -fu >>${current_log_file_path} 2>&1
}

function configureDevboxProject()
{
    echo "${grey}## configureDevboxProject${regular}"
    echo "## configureDevboxProject" >>${current_log_file_path}
    current_config_path="${test_config_dir}/etc/${current_config_name}"
    if [ -d "${current_config_path}" ]; then
        cp -a "${current_config_path}/." "${devbox_dir}/etc/"
    fi
    if [ -f ${tests_dir}/include/auth.json ]; then
        cp ${tests_dir}/include/auth.json "${devbox_dir}/etc/composer/auth.json"
    fi
}

function deployDevboxProject()
{
    echo "${grey}## deployDevboxProject${regular}"
    echo "## deployDevboxProject" >>${current_log_file_path}
    cd "${devbox_dir}"
    sudo bash "${devbox_dir}/scripts/host/configure_nfs_exports.sh"
    bash init_project.sh -fc 2> >(logAndEcho) | {
      while IFS= read -r line
      do
        logAndEcho "${line}"
        lastline="${line}"
      done
      logAndEcho "${lastline}"
    }
}

function hardReboot()
{
    echo "${grey}## hardReboot${regular}"
    echo "## hardReboot" >>${current_log_file_path}
    cd "${devbox_dir}"
    devbox halt --force >>${current_log_file_path} 2>&1
    devbox up >>${current_log_file_path} 2>&1
}

function virtualMachineSuspendAndResume()
{
    echo "${grey}## virtualMachineSuspendAndResume${regular}"
    echo "## virtualMachineSuspendAndResume" >>${current_log_file_path}
    cd "${devbox_dir}"
    devbox suspend >>${current_log_file_path} 2>&1
    devbox resume >>${current_log_file_path} 2>&1
}

function stashLogs()
{
    log_file_path="${logs_dir}/${current_config_name}.log"
    cp ${current_log_file_path} ${logs_dir}/${current_config_name}.log
}

function clearLogs()
{
    rm -f ${logs_dir}/*
}

function clearTestTmp()
{
    echo "${grey}## clearTestTmp${regular}"
    echo "## clearTestTmp" >>${current_log_file_path}
    if [ -e "${devbox_dir}" ]; then
        cd "${devbox_dir}"
        minikube delete &>/dev/null
        cd ${tests_dir}
        rm -rf "${devbox_dir}"
    fi
    rm -f ${current_log_file_path}
}

function createSimpleProduct()
{
    echo "${grey}## createSimpleProduct${regular}"
    echo "## createSimpleProduct" >>${current_log_file_path}

    adminToken=$(curl -sb -X POST "${current_magento_base_url}/rest/V1/integration/admin/token" \
        -H "Content-Type:application/json" \
        -d '{"username":"admin", "password":"123123q"}')
    adminToken=$(echo ${adminToken} | sed -e 's/"//g')

    curl -sb -X POST "${current_magento_base_url}/rest/V1/products" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${adminToken}" \
        -d '{"product":{"sku":"testSimpleProduct", "name":"Test Simple Product", "attribute_set_id":4, "price":22, "status":1, "visibility":4, "type_id":"simple", "extension_attributes":{"stock_item":{"qty": 12345,"is_in_stock": true}}}}' \
        >>${current_log_file_path} 2>&1
}

function refreshSearchIndexes()
{
    echo "${grey}## deleteElasticSearchIndexes${regular}"
    echo "## deleteElasticSearchIndexes" >>${current_log_file_path}

    cd "${devbox_dir}"
    executeInMagento2Container curl -- '-X' 'DELETE' '-i' 'http://elasticsearch-master:9200/_all' >>${current_log_file_path} 2>&1
    bash m-bin-magento indexer:reindex catalogsearch_fulltext >>${current_log_file_path} 2>&1
}

function emulateEeRepoCloning()
{
    echo "${grey}## emulateEeDownloading${regular}"
    echo "## emulateEeDownloading" >>${current_log_file_path}

    cp -r "${tests_dir}/_files/magento2ee" "${devbox_dir}/$(getDevBoxContext)/"
    cp "${devbox_dir}/$(getDevBoxContext)/composer.lock" "${devbox_dir}/$(getDevBoxContext)/magento2ee/composer.lock"
    sed -i.back 's|Composer installer for Magento modules|Composer installer for Magento modules EE MARK FOR TESTS|g' "${devbox_dir}/$(getDevBoxContext)/magento2ee/composer.lock" >>${current_log_file_path} 2>&1
}

function logAndEcho() {
    if [[ -n "${1}" ]]; then
        input="${1}"
    else
        input="$(cat)"
    fi
    if [[ -n "${input}" ]]; then
        echo "${input}"
        echo "${input}" >> "${current_log_file_path}"
    fi
}

function setDevBoxContext()
{
    echo "${grey}## setDevBoxContext${regular}"
    echo "## setDevBoxContext" >>${current_log_file_path}

    context=${1}
    bash "${devbox_dir}/k-set-context" ${context} >>${current_log_file_path} 2>&1
}


function getDevBoxContext()
{
    bash "${devbox_dir}/k-get-context"
}
