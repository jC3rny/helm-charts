#!/bin/env bash
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


if [ "$(yq e '."'${3:-kube-rbac}'".keyVault.provider' ${2})" != "null" ]; then
    KEYVAULT_PROVIDER="$(yq e '."'${3:-kube-rbac}'".keyVault.provider' ${2})"
    KEYVAULT_SUBSCRIPTION="$(yq e '."'${3:-kube-rbac}'".keyVault.subscription' ${2})"
    KEYVAULT_RESOURCE_GROUP="$(yq e '."'${3:-kube-rbac}'".keyVault.resourceGroup' ${2})"
    KEYVAULT_RESOURCE_GROUP_SCOPE="$(az group show --subscription "${KEYVAULT_SUBSCRIPTION}" --name "${KEYVAULT_RESOURCE_GROUP}" | jq -r '.id')"
    KEYVAULT_RESOURCE_GROUP_ROLES_ASSIGNMENT="$(az role assignment list --role "Key Vault Reader" --scope "${KEYVAULT_RESOURCE_GROUP_SCOPE}")"
    KEYVAULT_LOCATION="$(yq e '."'${3:-kube-rbac}'".keyVault.location' ${2})"
fi


if [ "${KEYVAULT_LOCATION}" == "null" ]; then
    KEYVAULT_LOCATION="$(yq e '.keyVault.location' ./values.yaml)"
fi


for USERNAME in $(yq e '."'${3:-kube-rbac}'".groups.*.users' ${2} | awk -F ' ' '{ print $2 }' | sort | uniq); do
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
        
        if [ "${KEYVAULT_PROVIDER}" == "azure" ]; then
            KEYVAULT_VAULT_NAME="$(yq e '."'${3:-kube-rbac}'".keyVault.vaultName' ${2})"
    
            if [ "${KEYVAULT_VAULT_NAME}" == "null" ]; then
                KEYVAULT_VAULT_NAME="$(cut -c -24 <<< "x-${KUBECONFIG_USERNAME}")"
            fi

            az keyvault show --subscription "${KEYVAULT_SUBSCRIPTION}" --name "${KEYVAULT_VAULT_NAME}" &> /dev/null
            
            if [ $? -eq 1 ]; then
                az keyvault create --name "${KEYVAULT_VAULT_NAME}" \
                    --subscription "${KEYVAULT_SUBSCRIPTION}" \
                    --resource-group "${KEYVAULT_RESOURCE_GROUP}" \
                    --location "${KEYVAULT_LOCATION}" \
                    --retention-days 7 \
                    --enable-rbac-authorization "true" &> /dev/null
            fi
    
            if [ $? -eq 0 ]; then
                KEYVAULT_SCOPE="$(az keyvault show --subscription ${KEYVAULT_SUBSCRIPTION} --name ${KEYVAULT_VAULT_NAME} | jq -r '.id')"

                az keyvault secret set \
                    --subscription "${KEYVAULT_SUBSCRIPTION}" \
                    --vault-name "${KEYVAULT_VAULT_NAME}" \
                    --name "${KUBECONFIG_CLUSTER_NAME}" \
                    --value "${KUBECONFIG_DATA}" \
                    | jq -r '.id'
                
                if [ ! -z "${USERNAME_DOMAIN}" ]; then
                    USERNAME_OBJECT_ID="$(az ad user list --filter "mail eq '"${USERNAME}"'" 2> /dev/null | jq -r '.[].objectId')"

                    if [ ! -z "${USERNAME_OBJECT_ID}" ]; then
                        if [ -z "$(jq -r '.[] | select(.principalId == "'${USERNAME_OBJECT_ID}'").id' <<< "${KEYVAULT_RESOURCE_GROUP_ROLES_ASSIGNMENT}")" ]; then
                            az role assignment create \
                                --assignee-object-id "${USERNAME_OBJECT_ID}" \
                                --assignee-principal-type "User" \
                                --role "Key Vault Reader" \
                                --scope "${KEYVAULT_RESOURCE_GROUP_SCOPE}" &> /dev/null
                        fi

                        az role assignment create \
                            --assignee-object-id "${USERNAME_OBJECT_ID}" \
                            --assignee-principal-type "User" \
                            --role "Key Vault Secrets User" \
                            --scope "${KEYVAULT_SCOPE}" &> /dev/null
                    fi
                else
                    for KEYVAULT_SECRETS_OFFICER in $(yq e '."'${3:-kube-rbac}'".keyVault.secretsOfficer' ${2} | awk '{ gsub(/[][]/,""); gsub(/,/,""); print}'); do
                        if [ ! -z "${KEYVAULT_SECRETS_OFFICER}" ]; then
                            KEYVAULT_SECRETS_OFFICER_ID="$(az ad user list --filter "mail eq '"${KEYVAULT_SECRETS_OFFICER}"'" | jq -r '.[].objectId')"
                            
                            if [ ! -z "${KEYVAULT_SECRETS_OFFICER_ID}" ]; then
                                if [ -z "$(jq -r '.[] | select(.principalId == "'${KEYVAULT_SECRETS_OFFICER_ID}'").id' <<< "${KEYVAULT_RESOURCE_GROUP_ROLES_ASSIGNMENT}")" ]; then
                                    az role assignment create \
                                        --assignee-object-id "${KEYVAULT_SECRETS_OFFICER_ID}" \
                                        --assignee-principal-type "User" \
                                        --role "Key Vault Reader" \
                                        --scope "${KEYVAULT_RESOURCE_GROUP_SCOPE}" &> /dev/null
                                fi

                                az role assignment create \
                                    --assignee-object-id "${KEYVAULT_SECRETS_OFFICER_ID}" \
                                    --assignee-principal-type "User" \
                                    --role "Key Vault Secrets User" \
                                    --scope "${KEYVAULT_SCOPE}" &> /dev/null
                            fi
                        fi
                    done
                fi
            fi
        else
        # handle it manually
        mkdir -p ${PWD}/tmp

        yq e -n <<< ${KUBECONFIG_DATA} > ${PWD}/tmp/$(printf "%s_%s.conf" ${KUBECONFIG_USERNAME} $(awk -F '/' '{ split($3, a, ":"); print a[1] }' <<< ${KUBECONFIG_CLUSTER_SERVER}))
        fi
    fi
done