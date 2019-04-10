#! /usr/bin/env bash

#tests_dir=$(cd "$(dirname "$0")"; pwd)
test_config_dir="${tests_dir}/_files"
vagrant_dir="${tests_dir}/tmp/test/magento2-vagrant"
current_log_file_path="${tests_dir}/tmp/test/current-test.log"
magento_codebase_stash_dir="${tests_dir}/tmp/testsuite/codebases"
skip_codebase_stash=0
logs_dir="${tests_dir}/logs"
current_config_name=""
current_codebase=""
current_magento_base_url=""

# Colors for CLI output
bold=$(tput bold)
green=$(tput setaf 2)
blue=$(tput setaf 4)
red=$(tput setaf 1)
grey=$(tput setaf 7)
regular=$(tput sgr0)
