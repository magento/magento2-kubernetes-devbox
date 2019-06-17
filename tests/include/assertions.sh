#! /usr/bin/env bash

## Assertion groups

function executeBasicCommonAssertions()
{
    # Make sure Magento was installed and is accessible
    assertMagentoInstalledSuccessfully
    assertMagentoFrontendAccessible
    assertMagentoCliWorks
}

function executeExtendedCommonAssertions()
{
    assertTestsConfigured
    assertDebugConfigurationWork
    # TODO: Implement functionality and uncomment assertions
#    assertPhpStormConfigured

#    # Make sure Magento is still accessible after restarting services
#    assertMysqlRestartWorks
#    assertApacheRestartWorks
#    assertMagentoFrontendAccessible

    # Make sure Magento reinstall script works
    assertMagentoReinstallWorks
    assertMagentoFrontendAccessible

#    assertEmailLoggingWorks

#    # Check if varnish can be enabled/disabled
#    assertVarnishEnablingWorks
#    assertVarnishDisablingWorks

    # Test search
    createSimpleProduct
    assertSearchWorks

    assertElasticSearchEnabled
    assertElasticSearchDisablingWorks
    assertElasticSearchEnablingWorks
}

## Assertions

function assertMagentoInstalledSuccessfully()
{
    echo "${blue}## assertMagentoInstalledSuccessfully${regular}"
    echo "## assertMagentoInstalledSuccessfully" >>${current_log_file_path}
    cd ${tests_dir}
    output_log="$(cat ${current_log_file_path})"
    pattern="Access storefront at .*(http\://magento[^/]*)/.*"
    if [[ ! ${output_log} =~ ${pattern} ]]; then
        fail "Magento was not installed successfully (Frontend URL is not available in the init script output)"
    fi
    current_magento_base_url=${BASH_REMATCH[1]}
}

function assertMagentoFrontendAccessible()
{
    echo "${blue}## assertMagentoFrontendAccessible${regular}"
    echo "## assertMagentoFrontendAccessible" >>${current_log_file_path}
    cd ${tests_dir}
    magento_home_page_content="$(curl -sL ${current_magento_base_url})"
    pattern="Magento.* All rights reserved."
    assertTrue "Magento was installed but main page is not accessible. URL: '${current_magento_base_url}'" '[[ ${magento_home_page_content} =~ ${pattern} ]]'
}

function assertMagentoEditionIsCE()
{
    echo "${blue}## assertMagentoEditionIsCE${regular}"
    echo "## assertMagentoEditionIsCE" >>${current_log_file_path}
    cd ${tests_dir}
    admin_token="$(curl -sb -X POST "${current_magento_base_url}/rest/V1/integration/admin/token" \
        -H "Content-Type:application/json" \
        -d '{"username":"admin", "password":"123123q"}')"
    rest_schema="$(curl -sb -x GET "${current_magento_base_url}/rest/default/schema" -H "Authorization:Bearer ${admin_token}")"
    pattern='"title":"Magento Community"'
    assertTrue 'Current edition is not Community.' '[[ ${rest_schema} =~ ${pattern} ]]'
}

function assertMagentoEditionIsEE()
{
    echo "${blue}## assertMagentoEditionIsEE${regular}"
    echo "## assertMagentoEditionIsEE" >>${current_log_file_path}
    cd ${tests_dir}
    admin_token="$(curl -sb -X POST "${current_magento_base_url}/rest/V1/integration/admin/token" \
        -H "Content-Type:application/json" \
        -d '{"username":"admin", "password":"123123q"}')"
    rest_schema="$(curl -sb -x GET "${current_magento_base_url}/rest/default/schema" -H "Authorization:Bearer ${admin_token}")"
    pattern='"title":"Magento Enterprise"'
    assertTrue 'Current edition is not Enterprise.' '[[ ${rest_schema} =~ ${pattern} ]]'
}

function assertMysqlRestartWorks()
{
    echo "${blue}## assertMysqlRestartWorks${regular}"
    echo "## assertMysqlRestartWorks" >>${current_log_file_path}
    cd "${devbox_dir}"
    cmd_output="$(devbox ssh -c 'sudo service mysql restart' >>${current_log_file_path} 2>&1)"
    pattern="mysql start/running, process [0-9]+"
    output_log="$(tail -n2 ${current_log_file_path})"
    assertTrue 'MySQL server restart attempt failed' '[[ ${output_log} =~ ${pattern} ]]'
}

function assertApacheRestartWorks()
{
    echo "${blue}## assertApacheRestartWorks${regular}"
    echo "## assertApacheRestartWorks" >>${current_log_file_path}
    cd "${devbox_dir}"
    cmd_output="$(devbox ssh -c 'sudo service apache2 restart' >>${current_log_file_path} 2>&1)"
    pattern="\[ OK \]"
    output_log="$(tail -n2 ${current_log_file_path})"
    assertTrue 'Apache restart attempt failed' '[[ ${output_log} =~ ${pattern} ]]'
}

function assertMagentoReinstallWorks()
{
    echo "${blue}## assertMagentoReinstallWorks${regular}"
    echo "## assertMagentoReinstallWorks" >>${current_log_file_path}
    cd "${devbox_dir}"
    bash m-reinstall >>${current_log_file_path} 2>&1
    pattern="Access storefront at .*(http\://magento[^/]*)/.*"
    if [[ ${debug_devbox_project} -eq 1 ]]; then
        tail_number=300
    else
        tail_number=5
    fi
    output_log="$(tail -n${tail_number} ${current_log_file_path})"
    assertTrue 'Magento reinstallation failed (Frontend URL is not available in the output)' '[[ ${output_log} =~ ${pattern} ]]'
}

function assertMagentoSwitchToEeWorks()
{
    echo "${blue}## assertMagentoSwitchToEeWorks${regular}"
    echo "## assertMagentoSwitchToEeWorks" >>${current_log_file_path}

    cd "${devbox_dir}"
    bash m-switch-to-ee -f >>${current_log_file_path} 2>&1
    pattern="Access storefront at .*(http\://magento[^/]*)/.*"
    output_log="$(tail -n5 ${current_log_file_path})"
    assertTrue 'Magento switch to EE failed (Frontend URL is not available in the output)' '[[ ${output_log} =~ ${pattern} ]]'
}

function assertMagentoSwitchToCeWorks()
{
    echo "${blue}## assertMagentoSwitchToCeWorks${regular}"
    echo "## assertMagentoSwitchToCeWorks" >>${current_log_file_path}
    cd "${devbox_dir}"
    bash m-switch-to-ce -f >>${current_log_file_path} 2>&1
    pattern="Access storefront at .*(http\://magento[^/]*)/.*"
    output_log="$(tail -n5 ${current_log_file_path})"
    assertTrue 'Magento switch to CE failed (Frontend URL is not available in the output)' '[[ ${output_log} =~ ${pattern} ]]'
}

function assertMagentoCliWorks()
{
    echo "${blue}## assertMagentoCliWorks${regular}"
    echo "## assertMagentoCliWorks" >>${current_log_file_path}
    cd "${devbox_dir}"
    bash m-bin-magento list >>${current_log_file_path} 2>&1
    pattern="theme:uninstall"
    if [[ ${debug_devbox_project} -eq 1 ]]; then
        tail_number=75
    else
        tail_number=10
    fi
    output_log="$(tail -n${tail_number} ${current_log_file_path})"
    assertTrue "${red}Magento CLI does not work.${regular}" '[[ ${output_log} =~ ${pattern} ]]'
}

function assertEmailLoggingWorks()
{
    echo "${blue}## assertEmailLoggingWorks${regular}"
    echo "## assertEmailLoggingWorks" >>${current_log_file_path}
    curl -X POST -F 'email=subscriber@example.com' "${current_magento_base_url}/newsletter/subscriber/new/"

    # Check if email is logged and identify its path
    list_of_logged_emails="$(ls -l "${devbox_dir}/log/email")"
    pattern="([^ ]+Newsletter subscription success\.html)"
    if [[ ! ${list_of_logged_emails} =~ ${pattern} ]]; then
        fail "Email logging is broken (newsletter subscription email is not logged to 'devbox-magento/log/email')"
    fi
    email_file_name=${BASH_REMATCH[1]}
    email_file_path="${devbox_dir}/log/email/${email_file_name}"

    # Make sure content of the email is an HTML
    email_content="$(cat "${email_file_path}")"
    pattern="^<!DOCTYPE html PUBLIC.*</html>$"
    assertTrue 'Email is logged, but content is invalid' '[[ ${email_content} =~ ${pattern} ]]'
}

function assertVarnishEnablingWorks()
{
    echo "${blue}## assertVarnishEnablingWorks${regular}"
    echo "## assertVarnishEnablingWorks" >>${current_log_file_path}

    cd "${devbox_dir}"
    bash m-varnish enable >>${current_log_file_path} 2>&1
    assertMagentoFrontendAccessible
    assertMainPageServedByVarnish
}

function assertMainPageServedByVarnish()
{
    echo "${blue}## assertMainPageServedByVarnish${regular}"
    echo "## assertMainPageServedByVarnish" >>${current_log_file_path}

    curl "${current_magento_base_url}" > /dev/null 2>&1
    is_cache_hit="$(curl "${current_magento_base_url}" -v 2>&1 | grep "X-Magento-Cache-Debug: HIT")"
    if [[ ${is_cache_hit} == '' ]]; then
        fail 'Main page is not served from cache (or Magento is not in Developer mode)'
    else
        # "Age:" header is available when Varnish is on, however it is not available when built-cache is enabled
        cache_tags_available="$(curl "${current_magento_base_url}" -v 2>&1 | grep "Age:")"
        if [[ ${cache_tags_available} == '' ]]; then
            fail 'Built-in cache seems to be enabled instead of Varnish'
        fi
    fi
}

function assertMainPageServedByBuiltInCache()
{
    echo "${blue}## assertMainPageServedByBuiltInCache${regular}"
    echo "## assertMainPageServedByBuiltInCache" >>${current_log_file_path}

    curl "${current_magento_base_url}" > /dev/null 2>&1
    is_cache_hit="$(curl "${current_magento_base_url}" -v 2>&1 | grep "X-Magento-Cache-Debug: HIT")"
    if [[ ${is_cache_hit} == '' ]]; then
        fail 'Main page is not served from cache (or Magento is not in Developer mode)'
    else
        # "Age:" header is available when Varnish is on, however it is not available when built-cache is enabled
        cache_tags_available="$(curl "${current_magento_base_url}" -v 2>&1 | grep "Age:")"
        if [[ ${cache_tags_available} != '' ]]; then
            fail 'Varnish cache seems to be enabled instead of built-in cache'
        fi
    fi
}

function assertVarnishDisablingWorks()
{
    echo "${blue}## assertVarnishDisablingWorks${regular}"
    echo "## assertVarnishDisablingWorks" >>${current_log_file_path}

    cd "${devbox_dir}"
    bash m-varnish disable >>${current_log_file_path} 2>&1

    assertMagentoFrontendAccessible
    assertMainPageServedByBuiltInCache
}

function assertNoErrorsInLogs()
{
    echo "${blue}## assertNoErrorsInLogs${regular}"
    echo "## assertNoErrorsInLogs" >>${current_log_file_path}

    grep_cannot="$(cat "${current_log_file_path}" | grep -i "cannot" | grep -iv "unload module vboxguest" | grep -iv "load Xdebug - it was already loaded" | grep -iv "Directory not empty")"
    count_cannot="$(echo ${grep_cannot} | grep -ic "cannot")"
    assertTrue "Errors found in log file:
        ${grep_cannot}" '[[ ${count_cannot} -eq 0 ]]'

    grep_error="$(cat "${current_log_file_path}" | grep -i "error" | grep -iv "errors = Off|display" | grep -iv "error_reporting = E_ALL" | grep -iv "assertNoErrorsInLogs" | grep -iv "shared folder errors" | grep -iv "\+\+ logError" | grep -iv "\+\+ outputErrorsOnly" | grep -iv "\+\+ errors=" | grep -iv "\+\+ which bash" | grep -iv "make sure there are no errors")"
    count_error="$(echo ${grep_error} | grep -ic "error")"
    assertTrue "Errors found in log file:
        ${grep_error}" '[[ ${count_error} -eq 0 ]]'

    grep_exception="$(cat "${current_log_file_path}" | grep -i "exception")"
    count_exception="$(echo ${grep_error} | grep -ic "exception")"
    assertTrue "Errors found in log file:
        ${grep_exception}" '[[ ${count_exception} -eq 0 ]]'
}

function assertPhpStormConfigured()
{
    echo "${blue}## assertPhpStormConfigured${regular}"
    echo "## assertPhpStormConfigured" >>${current_log_file_path}

    deployment_config_path="${devbox_dir}/.idea/deployment.xml"
    misc_config_path="${devbox_dir}/.idea/misc.xml"
    assertTrue 'PhpStorm was not configured (deployment.xml is missing)' '[[ -f ${deployment_config_path} ]]'
    assertTrue 'PhpStorm was not configured (misc.xml is missing)' '[[ -f ${misc_config_path} ]]'
    assertTrue 'PhpStorm was not configured (php.xml is missing)' '[[ -f "${devbox_dir}/.idea/php.xml" ]]'
    assertTrue 'PhpStorm was not configured (vcs.xml is missing)' '[[ -f "${devbox_dir}/.idea/vcs.xml" ]]'
    assertTrue 'PhpStorm was not configured (webServers.xml is missing)' '[[ -f "${devbox_dir}/.idea/webServers.xml" ]]'

    deployment_config_content="$(cat "${deployment_config_path}")"
    assertTrue 'PhpStorm configured incorrectly. deployment.xml config is invalid' '[[ ${deployment_config_content} =~ \$PROJECT_DIR\$/magento/app/etc ]]'

    misc_config_content="$(cat "${misc_config_path}")"
    assertTrue 'PhpStorm configured incorrectly. misc.xml config is invalid' '[[ ${misc_config_content} =~ urn:magento:module:Magento_Cron:etc/crontab.xsd ]]'
}

function assertElasticSearchEnabled()
{
    echo "${blue}## assertElasticSearchEnabled${regular}"
    echo "## assertElasticSearchEnabled" >>${current_log_file_path}

    cd "${devbox_dir}"

    elasticSearchHealth="$(executeInMagento2Container curl -- '-i' 'http://elasticsearch-master:9200/_cluster/health')"

    assertTrue "ElasticSearch server is down:
        ${elasticSearchHealth}" '[[ ${elasticSearchHealth} =~ \"status\":\"(green|yellow)\" ]]'

    listOfIndexes="$(executeInMagento2Container curl -- '-i' 'http://elasticsearch-master:9200/_cat/indices?v')"
    assertTrue "Products index is not available in ElasticSearch:
        ${listOfIndexes}" '[[ ${listOfIndexes} =~ magento2_product ]]'

    assertSearchWorks
}

function assertElasticSearchDisabled()
{
    echo "${blue}## assertElasticSearchDisabled${regular}"
    echo "## assertElasticSearchDisabled" >>${current_log_file_path}

    cd "${devbox_dir}"
    elasticSearchHealth="$(executeInMagento2Container curl -- '-i' 'http://elasticsearch-master:9200/_cluster/health')"
    assertTrue "ElasticSearch server is down:
        ${elasticSearchHealth}" '[[ ${elasticSearchHealth} =~ \"status\":\"(green|yellow)\" ]]'

    listOfIndexes="$(executeInMagento2Container curl -- '-i' 'http://elasticsearch-master:9200/_cat/indices?v')"
    assertTrue "Products index must not be available in ElasticSearch:
        ${listOfIndexes}" '[[ ! ${listOfIndexes} =~ magento2_product ]]'

    assertSearchWorks
}

function assertSearchWorks()
{
    echo "${blue}## assertSearchWorks${regular}"
    echo "## assertSearchWorks" >>${current_log_file_path}

    cd "${devbox_dir}"
    productSearchResult="$(curl -sb -x GET "${current_magento_base_url}/catalogsearch/result/?q=Test")"
    # Search for test product price on the page
    pattern="$22.00"
    assertTrue "Catalog search does not work." '[[ ${productSearchResult} =~ ${pattern} ]]'
}

function assertElasticSearchEnablingWorks()
{
    echo "${blue}## assertElasticSearchEnablingWorks${regular}"
    echo "## assertElasticSearchEnablingWorks" >>${current_log_file_path}

    cd "${devbox_dir}"
    bash m-search-engine elasticsearch >>${current_log_file_path} 2>&1
    refreshSearchIndexes
    assertElasticSearchEnabled
}

function assertElasticSearchDisablingWorks()
{
    echo "${blue}## assertElasticSearchDisablingWorks${regular}"
    echo "## assertElasticSearchDisablingWorks" >>${current_log_file_path}

    cd "${devbox_dir}"
    bash m-search-engine mysql >>${current_log_file_path} 2>&1
    refreshSearchIndexes
    assertElasticSearchDisabled
}

function assertCeSampleDataInstalled()
{
    echo "${blue}## assertCeSampleDataInstalled${regular}"
    echo "## assertCeSampleDataInstalled" >>${current_log_file_path}

    cd "${devbox_dir}"
    productDetailsPage="$(curl -sb -x GET "${current_magento_base_url}/wayfarer-messenger-bag.html")"
    # Search for product SKU on the page
    pattern="24-MB05"
    assertTrue "Sample data is not installed." '[[ ${productDetailsPage} =~ ${pattern} ]]'
}

function assertEeSampleDataInstalled()
{
    echo "${blue}## assertEeSampleDataInstalled${regular}"
    echo "## assertEeSampleDataInstalled" >>${current_log_file_path}

    cd "${devbox_dir}"
    productDetailsPage="$(curl -sb -x GET "${current_magento_base_url}/joust-duffle-bag.html")"
    # Search for Related Products on the page, which are populated by EE sample data
    pattern="Affirm Water Bottle"
    assertTrue "EE sample data not installed." '[[ ${productDetailsPage} =~ ${pattern} ]]'
}

function assertEeSampleDataNotInstalled()
{
    echo "${blue}## assertEeSampleDataNotInstalled${regular}"
    echo "## assertEeSampleDataNotInstalled" >>${current_log_file_path}

    cd "${devbox_dir}"
    productDetailsPage="$(curl -sb -x GET "${current_magento_base_url}/joust-duffle-bag.html")"
    # Search for Related Products on the page, which are populated by EE sample data
    pattern="Affirm Water Bottle"
    assertTrue "EE sample data is installed, when should not be." '[[ ! ${productDetailsPage} =~ ${pattern} ]]'
}

function assertCeSampleDataNotInstalled()
{
    echo "${blue}## assertCeSampleDataNotInstalled${regular}"
    echo "## assertCeSampleDataNotInstalled" >>${current_log_file_path}

    cd "${devbox_dir}"
    productDetailsPage="$(curl -sb -x GET "${current_magento_base_url}/wayfarer-messenger-bag.html")"
    pattern="The page you requested was not found"
    assertTrue "Sample data is installed, when should not be." '[[ ${productDetailsPage} =~ ${pattern} ]]'
}

function assertTestsConfigured()
{
    echo "${blue}## assertTestsConfigured${regular}"
    echo "## assertTestsConfigured" >>${current_log_file_path}

    # Unit tests
    unit_tests_config_path="${devbox_dir}/default/dev/tests/unit/phpunit.xml"
    assertTrue "Unit tests are not configured ('${unit_tests_config_path}' is missing)" '[[ -f ${unit_tests_config_path} ]]'
    
    # Integration tests
    integration_tests_config_path="${devbox_dir}/default/dev/tests/integration/phpunit.xml"
    assertTrue "Integration tests are not configured ('${integration_tests_config_path}' is missing)" '[[ -f ${integration_tests_config_path} ]]'
    integration_tests_mysql_config_path="${devbox_dir}/default/dev/tests/integration/etc/install-config-mysql.php"
    assertTrue "Integration tests MySQL config ('${integration_tests_mysql_config_path}') is missing" '[[ -f ${integration_tests_mysql_config_path} ]]'
    integration_tests_mysql_config_content="$(cat "${integration_tests_mysql_config_path}")"
    pattern="amqp-password"
    assertTrue "Contents of '${integration_tests_mysql_config_path}' seems to be invalid${functional_tests_config_content} =~ ${pattern}" '[[ ${integration_tests_mysql_config_content} =~ ${pattern} ]]'
    
    # REST Web API tests
    rest_tests_config_path="${devbox_dir}/default/dev/tests/api-functional/phpunit_rest.xml"
    assertTrue "REST tests are not configured ('${rest_tests_config_path}' is missing)" '[[ -f ${rest_tests_config_path} ]]'
    rest_tests_config_content="$(cat "${rest_tests_config_path}")"
    pattern="${current_magento_base_url}"
    assertTrue "Contents of '${rest_tests_config_path}' seems to be invalid ${rest_tests_config_content} =~ ${pattern}" '[[ ${rest_tests_config_content} =~ ${pattern} ]]'
    
    # SOAP Web API tests
    soap_tests_config_path="${devbox_dir}/default/dev/tests/api-functional/phpunit_soap.xml"
    assertTrue "SOAP tests are not configured ('${soap_tests_config_path}' is missing)" '[[ -f ${soap_tests_config_path} ]]'
    soap_tests_config_content="$(cat "${soap_tests_config_path}")"
    pattern="${current_magento_base_url}"
    assertTrue "Contents of '${soap_tests_config_path}' seems to be invalid ${soap_tests_config_content} =~ ${pattern}" '[[ ${soap_tests_config_content} =~ ${pattern} ]]'
       
    # GraphQL Web API tests
    graphql_tests_config_path="${devbox_dir}/default/dev/tests/api-functional/phpunit_graphql.xml"
    assertTrue "GraphQL tests are not configured ('${graphql_tests_config_path}' is missing)" '[[ -f ${graphql_tests_config_path} ]]'
    graphql_tests_config_content="$(cat "${graphql_tests_config_path}")"
    pattern="${current_magento_base_url}"
    assertTrue "Contents of '${graphql_tests_config_path}' seems to be invalid ${graphql_tests_config_content} =~ ${pattern}" '[[ ${graphql_tests_config_content} =~ ${pattern} ]]'
    
    # Functional tests
    functional_tests_config_path="${devbox_dir}/default/dev/tests/functional/phpunit.xml"
    assertTrue "Functional tests are not configured ('${functional_tests_config_path}' is missing)" '[[ -f ${functional_tests_config_path} ]]'
    functional_tests_config_content="$(cat "${functional_tests_config_path}")"
    pattern="${current_magento_base_url}"
    assertTrue "Contents of '${functional_tests_config_path}' seems to be invalid ${functional_tests_config_content} =~ ${pattern}" '[[ ${functional_tests_config_content} =~ ${pattern} ]]'

    functional_tests_config_path="${devbox_dir}/default/dev/tests/functional/etc/config.xml"
    assertTrue "Functional tests are not configured ('${functional_tests_config_path}' is missing)" '[[ -f ${functional_tests_config_path} ]]'
    functional_tests_config_content="$(cat "${functional_tests_config_path}")"
    pattern="${current_magento_base_url}"
    assertTrue "Contents of '${functional_tests_config_path}' seems to be invalid ${functional_tests_config_content} =~ ${pattern}" '[[ ${functional_tests_config_content} =~ ${pattern} ]]'
}

function assertDebugConfigurationWork()
{
    echo "${blue}## assertDebugOptionsWork${regular}"
    echo "## assertDebugOptionsWork" >>${current_log_file_path}

    cd "${devbox_dir}"
    sed -i.back 's|magento_storefront: 0|magento_storefront: 1|g' "${devbox_dir}/etc/instance/default.yaml" >>${current_log_file_path} 2>&1
    sed -i.back 's|magento_admin: 0|magento_admin: 1|g' "${devbox_dir}/etc/instance/default.yaml" >>${current_log_file_path} 2>&1
    bash m-clear-cache >>${current_log_file_path} 2>&1

    magento_home_page_content="$(curl -sL ${current_magento_base_url})"
    pattern='Magento\\Theme\\Block\\Html\\Footer'
    assertTrue "Storefront debugging is not enabled. URL: '${current_magento_base_url}'" '[[ ${magento_home_page_content} =~ ${pattern} ]]'

    magento_backend_login_page_content="$(curl -sL "${current_magento_base_url}/admin")"
    pattern='Magento\\Backend\\Block\\Page\\Copyright'
    assertTrue "Admin panel debugging is not enabled. URL: '${current_magento_base_url}/admin'" '[[ ${magento_backend_login_page_content} =~ ${pattern} ]]'

    sed -i.back 's|magento_storefront: 1|magento_storefront: 0|g' "${devbox_dir}/etc/instance/default.yaml" >>${current_log_file_path} 2>&1
    sed -i.back 's|magento_admin: 1|magento_admin: 0|g' "${devbox_dir}/etc/instance/default.yaml" >>${current_log_file_path} 2>&1
    bash m-clear-cache >>${current_log_file_path} 2>&1

    magento_home_page_content="$(curl -sL ${current_magento_base_url})"
    pattern='Magento\\Theme\\Block\\Html\\Footer'
    assertFalse "Storefront debugging should not be enabled. URL: '${current_magento_base_url}'" '[[ ${magento_home_page_content} =~ ${pattern} ]]'

    magento_backend_login_page_content="$(curl -sL "${current_magento_base_url}/admin")"
    pattern='Magento\\Backend\\Block\\Page\\Copyright'
    assertFalse "Admin panel debugging should not be enabled. URL: '${current_magento_base_url}/admin'" '[[ ${magento_backend_login_page_content} =~ ${pattern} ]]'
}

function assertSourceCodeIsFromBranch()
{
    echo "${blue}## assertSourceCodeIsFromBranch (${2})${regular}"
    echo "## assertSourceCodeIsFromBranch(${1}, ${2})" >>${current_log_file_path}

    source_directory=${1}
    expected_branch=${2}

    cd "${source_directory}"
    actual_branch="$(git rev-parse --symbolic-full-name --abbrev-ref HEAD)"

    assertTrue "Git repository in '${source_directory}' was supposed to be switched to '${expected_branch}' branch. Actual: '${actual_branch}'" '[[ ${actual_branch} = ${expected_branch} ]]'
}

function assertRedisCacheIsEnabled()
{
    echo "${blue}## assertRedisCacheIsEnabled${regular}"
    echo "## assertRedisCacheIsEnabled" >>${current_log_file_path}

    cache_directory="${devbox_dir}/default/var/cache"
    assertFalse "Redis cache seems to be disabled since cache directory '${cache_directory}' was created." '[[ -d ${cache_directory} ]]'
}

function assertRedisCacheIsDisabled()
{
    echo "${blue}## assertRedisCacheIsDisabled${regular}"
    echo "## assertRedisCacheIsDisabled" >>${current_log_file_path}

    cache_directory="${devbox_dir}/default/var/cache"
    assertTrue "Redis cache seems to be enabled since cache directory '${cache_directory}' was not created." '[[ -d ${cache_directory} ]]'
}
