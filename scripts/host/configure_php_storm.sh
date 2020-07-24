#!/usr/bin/env bash

# Copyright © Magento, Inc. All rights reserved.
# See COPYING.txt for license details.

cd "$(dirname "${BASH_SOURCE[0]}")/../.." && devbox_dir=$PWD

source "${devbox_dir}/scripts/functions.sh"

status "Configuring PhpStorm"
incrementNestingLevel

cd "${devbox_dir}"
ssh_port="$(bash "${devbox_dir}/scripts/get_env_config_value.sh" "guest_forwarded_ssh_port")"
magento_host_name="$(bash "${devbox_dir}/scripts/get_config_value.sh" "magento_host_name")"

cp -R "${devbox_dir}/scripts/host/php-storm-configs/." "${devbox_dir}/.idea/"

enabled_virtual_host_config="/etc/apache2/sites-available/magento2.conf"

host_os="$(bash "${devbox_dir}/scripts/host/get_host_os.sh")"
#if [[ ${host_os} == "Windows" ]] || [[ $(bash "${devbox_dir}/scripts/get_env_config_value.sh" "guest_use_nfs") == 0 ]]; then
#    sed -i.back "s|<magento_guest_path>|/var/www/magento|g" "${devbox_dir}/.idea/deployment.xml"
#    sed -i.back 's|<auto_upload_attributes>| autoUpload="Always" autoUploadExternalChanges="true"|g' "${devbox_dir}/.idea/deployment.xml"
#    sed -i.back 's|<auto_upload_option>|<option name="myAutoUpload" value="ALWAYS" />|g' "${devbox_dir}/.idea/deployment.xml"
#else
    # TODO: Add support multi-instance installation
#    sed -i.back "s|<magento_guest_path>|\$PROJECT_DIR\$/$(getContext)|g" "${devbox_dir}/.idea/deployment.xml"
    sed -i.back 's|<auto_upload_attributes>||g' "${devbox_dir}/.idea/deployment.xml"
    sed -i.back 's|<auto_upload_option>||g' "${devbox_dir}/.idea/deployment.xml"
#fi

sed -i.back "s|<host_name>|${magento_host_name}|g" "${devbox_dir}/.idea/webServers.xml"
sed -i.back "s|<ssh_port>|${ssh_port}|g" "${devbox_dir}/.idea/webServers.xml"
sed -i.back "s|<host_name>|${magento_host_name}|g" "${devbox_dir}/.idea/php.xml"
sed -i.back "s|<ssh_port>|${ssh_port}|g" "${devbox_dir}/.idea/php.xml"
sed -i.back "s|<host_name>|${magento_host_name}|g" "${devbox_dir}/.idea/deployment.xml"
sed -i.back "s|<host_name>|${magento_host_name}|g" "${devbox_dir}/.idea/deployment.xml"
sed -i.back "s|<host_name>|${magento_host_name}|g" "${devbox_dir}/.idea/.name"
sed -i.back "s|<host_name>|${magento_host_name}|g" "${devbox_dir}/.idea/modules.xml"
sed -i.back "s|<host_name>|${magento_host_name}|g" "${devbox_dir}/.idea/remote-mappings.xml"
rm -rf "${devbox_dir}/.idea/*.back"
rm -f "${devbox_dir}/.idea/.name.back"

mv "${devbox_dir}/.idea/host_name.iml" "${devbox_dir}/.idea/${magento_host_name}.iml"

repository_url_ee="$(bash "${devbox_dir}/scripts/get_config_value.sh" "repository_url_ee")"
if [[ -z ${repository_url_ee} ]]; then
    mv "${devbox_dir}/.idea/vcs.ce.xml" "${devbox_dir}/.idea/vcs.xml"
    rm "${devbox_dir}/.idea/vcs.ee.xml"
else
    mv "${devbox_dir}/.idea/vcs.ee.xml" "${devbox_dir}/.idea/vcs.xml"
    rm "${devbox_dir}/.idea/vcs.ce.xml"
fi

decrementNestingLevel
