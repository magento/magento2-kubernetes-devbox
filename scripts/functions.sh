#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")/.." && devbox_dir=$PWD

source "${devbox_dir}/scripts/colors.sh"

default_log="${devbox_dir}/log/debug.log"
log_file_path="${devbox_dir}/scripts/.current_log_path"
nesting_level_file="${devbox_dir}/scripts/.current_nesting_level"

function info() {
    echo "[$(formattedDate)]$(getIndentationByNesting "$@")$(getStyleByNesting "$@")${1}$(regular)$(sourceFile)$(regular)"
    log "[$(formattedDate)] INFO:$(getIndentationByNesting "$@")${1}$(sourceFile)]"
}

function status() {
    echo "[$(formattedDate)]$(getIndentationByNesting "$@")$(getStyleByNesting "$@")$(blue)${1}$(regular)$(sourceFile)$(regular)"
    log "[$(formattedDate)] STATUS:$(getIndentationByNesting "$@")${1}$(sourceFile)]"
}

function warning() {
    echo "[$(formattedDate)]$(getIndentationByNesting "$@")$(getStyleByNesting "$@")$(yellow)${1}$(regular)$(sourceFile)$(regular)"
    log "[$(formattedDate)] WARNING:$(getIndentationByNesting "$@")${1}$(sourceFile)]"
}

function error() {
    echo "[$(formattedDate)]$(getIndentationByNesting "$@")$(getStyleByNesting "$@")$(red)${1}$(regular)$(sourceFile)$(regular)"
    log "[$(formattedDate)] ERROR:$(getIndentationByNesting "$@")${1}$(sourceFile)]"
}

function success() {
    echo "[$(formattedDate)]$(getIndentationByNesting "$@")$(getStyleByNesting "$@")$(green)${1}$(regular)$(sourceFile)$(regular)"
    log "[$(formattedDate)] SUCCESS:$(getIndentationByNesting "$@")${1}$(sourceFile)]"
}

function filterDevboxOutput()
{
    if [[ -n "${1}" ]]; then
        input="${1}"
    else
        input="$(cat)"
    fi
    log "${input}"
    output="$(echo "${input}" | grep -i "\[.*\].*\[.*\]" | sed "s/.*\(\[.*\].*\[.*\]\)/\1/g")"
    if [[ -n "${output}" ]]; then
        echo "${output}"
    fi
}

function log() {
    if [[ -n "${1}" ]]; then
        input="${1}"
    else
        input="$(cat)"
    fi
    if [[ -n "${input}" ]]; then
        if [[ -f "${log_file_path}" ]]; then
            log_file="${devbox_dir}/$(cat "${log_file_path}")"
        else
            log_file="${default_log}"
        fi
        echo "${input}" | sed "s/\[[[:digit:]]\{1,\}m//g" >> "${log_file}" 2> /dev/null
    fi
}

function logError() {
    if [[ -n "${1}" ]]; then
        input="${1}"
    else
        input="$(cat)"
    fi
    if [[ -n "${input}" ]]; then
        outputErrorsOnly "${input}"
        outputInfoOnly "${input}"
    fi
}

function sourceFile() {
    if [[ ! ${BASH_SOURCE[2]} =~ functions\.sh ]]; then
        echo " $(grey)[${BASH_SOURCE[2]}]"
    else
        echo " $(grey)[Unknown source file]"
    fi
}

function formattedDate() {
    date "+%Y-%m-%d %H:%M:%S"
}

function outputErrorsOnly()
{
    errors="$(echo "${1}" | grep -iv "Connection to 127.0.0.1 closed." \
        | grep -iv "Cloning into .*\.\.\."\
        | grep -iv "Checking out .* done\."\
    )"
    if [[ -n "${errors}" ]]; then
        error "${errors}"
        log "error: ${errors}"
    fi
}

function outputInfoOnly()
{
    info="$(echo "${1}" | grep -iv "Connection to 127.0.0.1 closed." \
        | grep -i "Cloning into .*\.\.\."\
        | grep -i "Checking out .* done\."\
    )"
    if [[ -n "${info}" ]]; then
        log "${info}"
    fi
}

function incrementNestingLevel()
{
    if [[ ! -f "${nesting_level_file}" ]]; then
        echo 1 > "${nesting_level_file}"
        chmod a+w "${nesting_level_file}"
    else
        nesting_level="$(cat "${nesting_level_file}")"
        nesting_level="$((${nesting_level}+1))"
        echo ${nesting_level} > "${nesting_level_file}"
    fi
}

function decrementNestingLevel()
{
    if [[ -f "${nesting_level_file}" ]]; then
        nesting_level="$(cat "${nesting_level_file}")"
        nesting_level="$((${nesting_level}-1))"
        if [[ ${nesting_level} -eq 0 ]]; then
            rm -f "${nesting_level_file}"
        else
            echo ${nesting_level} > "${nesting_level_file}"
        fi
    fi
}

function resetNestingLevel()
{
    rm -f "${nesting_level_file}"
}

function initLogFile()
{
    if [[ -n "${1}" ]]; then
        log_file="${1}"
    else
        log_file="debug"
    fi
    echo "log/${log_file}.log" > "${log_file_path}"
    rm -f "${devbox_dir}/log/${log_file}.log"
    touch "${devbox_dir}/log/${log_file}.log"
    chmod a+w "${devbox_dir}/log/${log_file}.log"
}

function getIndentationByNesting()
{
    if [[ ! -f "${nesting_level_file}" ]]; then
        nesting_level=0
        echo ' '
    else
        nesting_level="$(cat "${nesting_level_file}")"
        if [[ ${nesting_level} -eq 1 ]]; then
            echo ' >  '
        else
            indentation="$(( (${nesting_level} - 1) * 4 ))"
            echo "$(printf '=%.0s' $(seq 1 ${indentation})) >  " | sed 's|=| |g'
        fi
    fi
}

function getStyleByNesting()
{
    if [[ ! -f "${nesting_level_file}" ]]; then
        nesting_level=0
    else
        nesting_level="$(cat "${nesting_level_file}")"
    fi

    if [[ ${nesting_level} -eq 0 ]]; then
        echo "$(bold)"
    fi
}

function bash()
{
    $(which bash) "$@" 2> >(logError)
}

# TODO: Move kubectl related functions to the host-only scripts
function getMagento2PodId()
{
    # TODO: Calculate based on current helm release
    echo "$(kubectl get pods | grep -ohE 'magento2-monolith-[a-z0-9\-]+')"
}

function getMagento2CheckoutPodId()
{
    # TODO: Calculate based on current helm release
    echo "$(kubectl get pods | grep -ohE 'magento2-checkout-[a-z0-9\-]+')"
}

function getRedisMasterPodId()
{
    echo "$(kubectl get pods | grep -ohE 'magento2-redis-master-[a-z0-9\-]+')"
}

function getMysqlPodId()
{
    echo "$(kubectl get pods | grep -ohE 'magento2-mysql-[a-z0-9\-]+')"
}

function executeInMagento2Container()
{
    magento2_pod_id="$(getMagento2PodId)"
    kubectl exec "${magento2_pod_id}" --container monolith "$@" 2> >(logError)
}

function executeInMagento2CheckoutContainer()
{
    magento2_pod_id="$(getMagento2CheckoutPodId)"
    kubectl exec "${magento2_pod_id}" --container checkout "$@" 2> >(logError)
}

function isMinikubeRunning() {
    minikube_status="$(minikube status | grep minikube: 2> >(log))"
    if [[ ${minikube_status} == "minikube: Running" ]]; then
        echo 1
    fi
}

function isMinikubeStopped() {
    minikube_status="$(minikube status | grep minikube: 2> >(log))"
    if [[ ${minikube_status} == "minikube: Stopped" ]]; then
        echo 1
    fi
    if [[ ${minikube_status} == "minikube: Saved" ]]; then
        echo 1
    fi
}

function isMinikubeSaved() {
    minikube_status="$(minikube status | grep minikube: 2> >(log))"
    if [[ ${minikube_status} == "minikube: Saved" ]]; then
        echo 1
    fi
}

# TODO: Add suspended

function isMinikubeInitialized() {
    if [[ $(isMinikubeRunning) -eq 1 || $(isMinikubeStopped) -eq 1 || $(isMinikubeSaved) -eq 1 ]]; then
        echo 1
    fi
}

function waitForKubernetesPodToRun()
{
    set +e

    if [[ -n "${1}" ]]; then
        pod_id="${1}"
    else
        error "Argument missing for 'waitForKubernetesPodToRun'"
        set -e
        exit 1
    fi

    COUNTER=0
    pod_status=$(kubectl get pods --all-namespaces | grep -hE "${pod_id}-[a-z0-9\-]+" | grep -o 'Running')

    while [[ $pod_status != 'Running' && $COUNTER -lt 240 ]] ; do
        sleep 3
        let COUNTER+=3
        status "Waiting for pod (${pod_id}) to run"
        pod_status=$(kubectl get pods --all-namespaces | grep -hE "${pod_id}-[a-z0-9\-]+" | grep -o 'Running')
    done
    set -e
}
