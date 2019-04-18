#! /usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")/.." && project_root_dir=$PWD

tests_dir="${project_root_dir}/tests"
cd ${tests_dir}

## Includes
source include/global_variables.sh
source include/configuration.sh
source include/helpers.sh
source include/assertions.sh

## Setup and tear down

function oneTimeSetUp
{
    clearLogs
}

function setUp()
{
    debug_vagrant_project=0
    skip_codebase_stash=0
}

function tearDown()
{
    assertNoErrorsInLogs

    if [[ ${delete_test_project_on_tear_down} -eq 1 ]]; then
        stashLogs
        stashMagentoCodebase
        clearTestTmp
    fi

    # TODO: change globally when https://github.com/paliarush/magento2-vagrant-for-developers/issues/58 is unblocked
    vagrant_dir="${tests_dir}/tmp/test/magento2-vagrant"
}

function oneTimeTearDown()
{
    echo "
See logs in ${logs_dir}"
}

## Tests

function testNoCustomConfigBasicTest()
{
    current_config_name="no_custom_config"
    current_codebase="ce"
    installEnvironment
#    assertVarnishDisabled
    executeBasicCommonAssertions
    assertMagentoEditionIsCE
    assertCeSampleDataNotInstalled
    assertTestsConfigured
    assertDebugConfigurationWork
    assertRedisCacheIsEnabled
}

## Call and Run all Tests
source lib/shunit2-2.1.6/src/shunit2
