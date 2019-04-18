#! /usr/bin/env bash

function installEnvironment()
{
    stashMagentoCodebase
    clearTestTmp
    downloadVagrantProject
    unstashMagentoCodebase
    configureVagrantProject
    deployVagrantProject
}

function installEnvironmentWithUpgrade()
{
    stashMagentoCodebase
    clearTestTmp
    downloadBaseVersionOfVagrantProject
    unstashMagentoCodebase
    configureVagrantProject
    deployVagrantProject
    upgradeVagrantProject
}

function downloadVagrantProject()
{
    cd ${tests_dir}
    if [[ ! -z "${vagrant_project_local_path}" ]]; then
        echo "${grey}## copyVagrantProjectFromLocalPath${regular}"
        echo "## copyVagrantProjectFromLocalPath" >>${current_log_file_path}
        rm -rf "${vagrant_dir}" && mkdir -p "${vagrant_dir}"
        rsync -a --exclude=".git" --exclude="tests" --exclude="magento" "${vagrant_project_local_path}/" "${vagrant_dir}"
    else
        echo "${grey}## downloadVagrantProject${regular}"
        echo "## downloadVagrantProject" >>${current_log_file_path}
        git clone ${vagrant_project_repository_url} "${vagrant_dir}" >>${current_log_file_path} 2>&1
        cd "${vagrant_dir}"
        git checkout ${vagrant_project_branch} >>${current_log_file_path} 2>&1
    fi
}

function downloadBaseVersionOfVagrantProject()
{
    echo "${grey}## downloadBaseVersionOfVagrantProject${regular}"
    echo "## downloadBaseVersionOfVagrantProject" >>${current_log_file_path}
    cd ${tests_dir}
    git clone git@github.com:paliarush/magento2-vagrant-for-developers.git "${vagrant_dir}" >>${current_log_file_path} 2>&1
    cd "${vagrant_dir}"
    git checkout tags/v2.2.0 >>${current_log_file_path} 2>&1
    # Make sure that older box version is used
    sed -i.back 's|config.vm.box_version = "~> 1.0"|config.vm.box_version = "= 1.0"|g' "${vagrant_dir}/Vagrantfile" >>${current_log_file_path} 2>&1
    echo '{"github-oauth": {"github.com": "sampletoken"}}' >"${vagrant_dir}/etc/composer/auth.json"
}

function upgradeVagrantProject()
{
    echo "${grey}## upgradeVagrantProject${regular}"
    echo "## upgradeVagrantProject" >>${current_log_file_path}
    # Reset changes done to box version requirements
    git checkout "${vagrant_dir}/Vagrantfile" >>${current_log_file_path} 2>&1
    cd "${vagrant_dir}"
    git remote add repository-under-test ${vagrant_project_repository_url} >>${current_log_file_path} 2>&1
    git fetch repository-under-test >>${current_log_file_path} 2>&1
    git checkout -b branch-under-test repository-under-test/${vagrant_project_branch} >>${current_log_file_path} 2>&1
    vagrant reload >>${current_log_file_path} 2>&1
}

function upgradeComposerBasedMagento()
{
    cd "${vagrant_dir}"
    echo "${grey}## upgradeComposerBasedMagento (to 2.1.2)${regular}"
    echo "## upgradeComposerBasedMagento (to 2.1.2)" >>${current_log_file_path}
    bash m-composer require magento/product-community-edition 2.1.2 --no-update >>${current_log_file_path} 2>&1
    bash m-switch-to-ce -fu >>${current_log_file_path} 2>&1
    echo "${grey}## upgradeComposerBasedMagento (to 2.1.3)${regular}"
    echo "## upgradeComposerBasedMagento (to 2.1.3)" >>${current_log_file_path}
    bash m-composer require magento/product-community-edition 2.1.3 --no-update >>${current_log_file_path} 2>&1
    bash m-switch-to-ee -fu >>${current_log_file_path} 2>&1
}

function configureVagrantProject()
{
    echo "${grey}## configureVagrantProject${regular}"
    echo "## configureVagrantProject" >>${current_log_file_path}
    current_config_path="${test_config_dir}/${current_config_name}_config.yaml"
    if [ -f ${current_config_path} ]; then
        cp ${current_config_path} "${vagrant_dir}/etc/config.yaml"
    fi
    if [ -f ${tests_dir}/include/auth.json ]; then
        cp ${tests_dir}/include/auth.json "${vagrant_dir}/etc/composer/auth.json"
    fi
}

function deployVagrantProject()
{
    echo "${grey}## deployVagrantProject${regular}"
    echo "## deployVagrantProject" >>${current_log_file_path}
    cd "${vagrant_dir}"
    sudo bash "${vagrant_dir}/scripts/host/configure_nfs_exports.sh"
    bash init_project.sh -fcd 2> >(logAndEcho) | {
      while IFS= read -r line
      do
        logAndEcho "${line}"
        lastline="${line}"
      done
      logAndEcho "${lastline}"
    }
}

function stashMagentoCodebase()
{
    if [[ ${skip_codebase_stash} == 0 ]] && [[ -d "${vagrant_dir}/magento" ]]; then
        echo "${grey}## stashMagentoCodebase${regular}"
        echo "## stashMagentoCodebase" >>${current_log_file_path}
        magento_stash_dir="${magento_codebase_stash_dir}/${current_codebase}"
        rm -rf "${magento_stash_dir}"
        mkdir -p "${magento_stash_dir}"
        mv "${vagrant_dir}/magento" "${magento_stash_dir}/magento"
        rm -rf "${magento_stash_dir}/magento/var/*"
        rm -rf "${magento_stash_dir}/magento/vendor/*"
        rm -rf "${magento_stash_dir}/magento/pub/static/*"
        rm -f "${magento_stash_dir}/magento/app/etc/config.php"
        rm -f "${magento_stash_dir}/magento/dev/tests/api-functional/soap.xml"
        rm -f "${magento_stash_dir}/magento/dev/tests/api-functional/rest.xml"
        rm -f "${magento_stash_dir}/magento/dev/tests/functional/phpunit.xml"
        rm -f "${magento_stash_dir}/magento/dev/tests/functional/etc/config.xml"
        rm -f "${magento_stash_dir}/magento/dev/tests/integration/phpunit.xml"
        rm -f "${magento_stash_dir}/magento/dev/tests/integration/etc/install-config-mysql.php"
        rm -f "${magento_stash_dir}/magento/dev/tests/unit/phpunit.xml"
    fi
}

function unstashMagentoCodebase()
{
    magento_stash_dir="${magento_codebase_stash_dir}/${current_codebase}/magento"
    if [[ ${skip_codebase_stash} == 0 ]] && [[ -d "${magento_stash_dir}" ]]; then
        echo "${grey}## unstashMagentoCodebase${regular}"
        echo "## unstashMagentoCodebase" >>${current_log_file_path}
        mv "${magento_stash_dir}" "${vagrant_dir}/magento"
    fi
}

function hardReboot()
{
    echo "${grey}## hardReboot${regular}"
    echo "## hardReboot" >>${current_log_file_path}
    cd "${vagrant_dir}"
    vagrant halt --force >>${current_log_file_path} 2>&1
    vagrant up >>${current_log_file_path} 2>&1
}

function virtualMachineSuspendAndResume()
{
    echo "${grey}## virtualMachineSuspendAndResume${regular}"
    echo "## virtualMachineSuspendAndResume" >>${current_log_file_path}
    cd "${vagrant_dir}"
    vagrant suspend >>${current_log_file_path} 2>&1
    vagrant resume >>${current_log_file_path} 2>&1
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
    if [ -e "${vagrant_dir}" ]; then
        cd "${vagrant_dir}"
        vagrant destroy -f &>/dev/null
        cd ${tests_dir}
        rm -rf "${vagrant_dir}"
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

    cd "${vagrant_dir}"
    vagrant ssh -c 'curl -X DELETE -i http://127.0.0.1:9200/_all' >>${current_log_file_path} 2>&1
    bash m-bin-magento indexer:reindex catalogsearch_fulltext >>${current_log_file_path} 2>&1
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
