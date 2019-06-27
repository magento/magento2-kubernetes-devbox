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
#    skip_codebase_stash=0
}

function tearDown()
{
    assertNoErrorsInLogs

    if [[ ${delete_test_project_on_tear_down} -eq 1 ]]; then
        stashLogs
#        stashMagentoCodebase
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

function testMultiInstanceWithCeFromComposerNoNfs()
{
    current_config_name="multi_instance_with_ce_from_composer_no_nfs"
#    skip_codebase_stash=1

    installEnvironment

    # Second instance is the last installed
    assertDevBoxContext "second"

    executeBasicCommonAssertions
    assertMagentoEditionIsCE
    assertCeSampleDataNotInstalled
    assertRedisCacheIsEnabled

    # Default instance assertions
    setDevBoxContext "default"
    assertDevBoxContext "default"
    current_magento_base_url="http://magento.default"

    assertMagentoFrontendAccessible
    assertMagentoCliWorks
    assertMagentoEditionIsCE

    assertRedisCacheIsEnabled

    executeExtendedCommonAssertions

    assertMainPageServedByBuiltInCache

    assertMagentoUnitTestsWork
    assertMagentoIntegrationTestsWork
}

## Call and Run all Tests
source lib/shunit2/shunit2
