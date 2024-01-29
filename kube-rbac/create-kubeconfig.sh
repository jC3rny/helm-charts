#!/usr/bin/env bash
# . create-kubeconfig.sh ~/.config/kubeconfig/exampleOrg/config kube-rbac/values-example-org-users_dev.yaml

# ${1} - kubeconfig file path
# ${2} - values-*.yaml file path
# ${3} - chart name in values-*.yaml file (if omitted kube-rbac will be used)
#
# PREREQUISITES:
#   - Azure resource group role assignments ( Owner, Key Vault Administrator )


KUBECTL_CMD="kubectl --kubeconfig ${1}"

KUBECONFIG_CLUSTER_NAME="$(${KUBECTL_CMD} config view --flatten -o jsonpath='{ .clusters[0].name }')"
KUBECONFIG_CLUSTER_SERVER="$(${KUBECTL_CMD} config view --flatten -o jsonpath='{ .clusters[0].cluster.server }')"
KUBECONFIG_CLUSTER_CA_DATA="$(${KUBECTL_CMD} config view --flatten -o jsonpath='{ .clusters[0].cluster.certificate-authority-data }')"

KUBECONFIG_USER_NAMESPACE="$(yq e '."'${3:-kube-rbac}'".serviceAccount.namespaceOverride' ${2})"


for USERNAME in $(yq e '."'${3:-kube-rbac}'".groups.*.users' ${2} | awk -F ' ' '{ print $2 }' | sort -u); do
    USERNAME_DOMAIN="$(awk '{ split($0, a, "@"); print a[2] }' <<< ${USERNAME})"

    KUBECONFIG_USERNAME="$(awk '{ sub(/\./, "-"); split($0, a, "@"); print a[1] }' <<< ${USERNAME})"
    KUBECONFIG_USER_SECRET_NAME="$(${KUBECTL_CMD} -n ${KUBECONFIG_USER_NAMESPACE} get sa ${KUBECONFIG_USERNAME} -o jsonpath='{ .secrets[].name }')"
    KUBECONFIG_USER_TOKEN="$(${KUBECTL_CMD} -n ${KUBECONFIG_USER_NAMESPACE} get secrets ${KUBECONFIG_USER_SECRET_NAME} -o jsonpath='{ .data.token }' | base64 --decode)"

    if [ ! -z "${KUBECONFIG_USER_TOKEN}" ]; then
        KUBECONFIG_DATA="$(helm template kubeconfig . \
            --set "${3:-kube-rbac}.kubeConfig.enabled=yes" \
            --set "${3:-kube-rbac}.kubeConfig.cluster.name=${KUBECONFIG_CLUSTER_NAME}" \
            --set "${3:-kube-rbac}.kubeConfig.cluster.server=${KUBECONFIG_CLUSTER_SERVER}" \
            --set "${3:-kube-rbac}.kubeConfig.cluster.certificateAuthorityData=${KUBECONFIG_CLUSTER_CA_DATA}" \
            --set "${3:-kube-rbac}.kubeConfig.user.name=${KUBECONFIG_USERNAME}" \
            --set "${3:-kube-rbac}.kubeConfig.user.token=${KUBECONFIG_USER_TOKEN}" \
            --set "${3:-kube-rbac}.serviceAccount.namespaceOverride=${KUBECONFIG_USER_NAMESPACE}" 2> /dev/null)"
        
        # handle it manually
        mkdir -p ${PWD}/tmp

        printf '%s\n' "${KUBECONFIG_DATA}" > ${PWD}/tmp/$(printf "%s_%s.conf" ${KUBECONFIG_USERNAME} $(awk -F '/' '{ split($3, a, ":"); print a[1] }' <<< ${KUBECONFIG_CLUSTER_SERVER}))
        fi
    fi
done