#! /usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")/.." && project_root_dir=$PWD

tests_dir="${project_root_dir}/tests"
cd ${tests_dir}

## Includes
source include/global_variables.sh
source include/configuration.sh
source include/helpers.sh
source include/assertions.sh

original_devbox_dir="${devbox_dir}"
source ./../scripts/functions.sh
devbox_dir=${original_devbox_dir}
cd ${tests_dir}

## Setup and tear down

function oneTimeSetUp
{
    clearLogs
}

function setUp()
{
    debug_devbox_project=0
}

function tearDown()
{
    assertNoErrorsInLogs

    if [[ ${delete_test_project_on_tear_down} -eq 1 ]]; then
        stashLogs
        clearTestTmp
    fi

    # TODO: change globally when https://github.com/paliarush/magento2-vagrant-for-developers/issues/58 is unblocked
    devbox_dir="${tests_dir}/tmp/test/magento2-devbox"
}

function oneTimeTearDown()
{
    echo "
See logs in ${logs_dir}"
}

## Tests

function testCe24WithSampleDataMysqlSearchNoNfs()
{
    current_config_name="ce24_with_sample_data_mysql_search_no_nfs"

    installEnvironment

    assertSourceCodeIsFromBranch "${devbox_dir}/default" "2.4-develop"
    assertSourceCodeIsFromBranch "${devbox_dir}/default/magento2-sample-data" "2.4-develop"

    executeBasicCommonAssertions
    # TODO: Fix Sample Data assertion
#    assertCeSampleDataInstalled
    assertMagentoEditionIsCE

    assertElasticSearchDisabled
    assertSearchWorks
    assertElasticSearchEnablingWorks

    assertRedisCacheIsEnabled

    executeExtendedCommonAssertions
}

## Call and Run all Tests
source lib/shunit2/shunit2
