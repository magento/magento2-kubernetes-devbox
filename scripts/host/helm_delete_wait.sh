#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")/../.." && devbox_dir=$PWD

source "${devbox_dir}/scripts/functions.sh"

cd "${devbox_dir}/etc/helm"
set +e

kinds=( Service Deployment Pod Secret ConfigMap PersistentVolumeClaim PersistentVolume )
counter=0 attempts=3

deleteResourceManually () {
    local kind=$1
    local release=$2
    info "Deleting any dangling ${kind}"

    kubectl delete "${kind}" \
        -l "release=${release}" \
        --force \
        --grace-period 0 2>/dev/null
}

status "Cleaning up existing Kubernetes resources."
incrementNestingLevel
for release in "$@"; do
    incrementNestingLevel
    status "Deleting release ${release}"

    if helm ls -q --all | grep -qF "${release}"; then
        info "Found helm release; deleting with --purge"
        helm delete "${release}" --purge
    else
        info "No release found; deleting manually"
        for kind in "${kinds[@]}"; do
            deleteResourceManually "${kind}" "${release}"
        done
    fi

    info "Awaiting resource deleting confirmation"
    for kind in "${kinds[@]}"; do
        counter=0

        while [ $counter -lt $attempts ]; do
            pending_resources="$(kubectl get "${kind}" \
                -o wide \
                -l "release=${release}" 2>/dev/null
            )"

            if [ -n "${pending_resources}" ]; then
                info "${release} ${kind} still running. ${counter}/${attempts} tests completed; retrying."
                info "${pending_resources}" 1>&2

                ((++counter))
                sleep 10
            else
                break
            fi
        done

        if [ $counter -eq $attempts ]; then
            error "${release} ${kind} failed to delete in time. Deleting manually.";
            deleteResourceManually "$kind" "$release"

            counter=0

            while [ $counter -lt $attempts ]; do
                pending_resources="$(kubectl get "${kind}" \
                    -o wide \
                    -l "release=${release}" 2>/dev/null
                )"

                if [ -n "${pending_resources}" ]; then
                    info "${release} ${kind} still running. ${counter}/${attempts} tests completed; retrying."
                    info "${pending_resources}" 1>&2

                    ((++counter))
                    sleep 10
                else
                    break
                fi
            done

            if [ $counter -eq $attempts ]; then
                error "${release} ${kind} failed to delete in time. Can't proceed.";
                exit 1
            fi
        fi
    done

    info "Awaiting helm confirmation"
    counter=0

    while [ $counter -lt $attempts ]; do
        if helm ls -q --all | grep -qF "${release}"; then
            info "${release} still in tiller. ${counter}/${attempts} checks completed; retrying."

            ((++counter))
            sleep 10
        else
            break
        fi
    done

    if [ $counter -eq $attempts ]; then
        error "${release} failed to purge from tiller delete in time.";
        exit 1
    fi

    success "Deleted all helm-created resources for release ${release}"
    decrementNestingLevel
done
decrementNestingLevel
success "Deleted all helm-created resources"
