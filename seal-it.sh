#!/usr/bin/env bash

# Installation:
# :~$ curl -o .local/bin/seal-it https://raw.githubusercontent.com/jC3rny/helm-charts/main/seal-it.sh

# Usage:
# :~$ seal-it -c ".stringData" -f ./values-test.yaml -n example -h "sealed-secrets.example.local" --verbose
# :~$ seal-it -c ".repositories" -f ./values-test.yaml -n example -m name -E "date +'repo-%y%m%d-%H%M%S-%3N'" -h "sealed-secrets.example.local" --verbose
# :~$ seal-it -v "TEST" -n example -h "sealed-secrets.example.local" --verbose
# :~$ seal-it -R 25 -n example -h "sealed-secrets.example.local" --verbose
# :~$ seal-it -D -c ".imagePullSecret" -k "sealedDockerConfig" -f ./values-test.yaml -n example -h "sealed-secrets.example.local" --verbose


CONTEXT=""
ENCRYPTED_KEY=""
PRETTY_PRINT=""
MASKED_KEYS_REGEX=""
MARKER_KEY=""
MARKER_VALUE_EVAL=""
FILE_PATH=""
SEALED_SECRET_URL=""
SEALED_SECRET_URL_HOST=""
SEALED_SECRET_URL_PATH="/v1/cert.pem"
SEAL_VALUE=""
SEAL_RANDOM=0
SEAL_DOCKERCONFIG="false"
NAMESPACE=""
SKIP_BACKUP="false"
YQ_COMPATIBLE_VERSION="4"
PRINT_HELP="false"
VERBOSE="false"


# Check YQ version
if [ "$(printf '%s\n%s' ${YQ_COMPATIBLE_VERSION} $(yq --version | awk '{ print $4 }') | sort -V | head -n1)" != "${YQ_COMPATIBLE_VERSION}" ]; then
    echo -e ":: [ERROR] yq version mismatch! Compatible versions is v${YQ_COMPATIBLE_VERSION}.x ..."
    return 1
fi


for ARG in "${@}"; do
    case $ARG in
        -c|--context)
        CONTEXT=${2}
        shift; shift
        ;;
        -k|--encrypted-key)
        ENCRYPTED_KEY=${2}
        shift; shift
        ;;
        -P|--pretty-print)
        PRETTY_PRINT="--prettyPrint"
        shift
        ;;
        -m|--marker-key)
        MARKER_KEY=${2}
        shift; shift
        ;;
        -E|--marker-value-eval)
        MARKER_VALUE_EVAL=${2}
        shift; shift
        ;;
        -f|--file-path)
        FILE_PATH=${2}
        shift; shift
        ;;
        -u|--url)
        SEALED_SECRET_URL=${2}
        shift; shift
        ;;
        -h|--host)
        SEALED_SECRET_URL_HOST=${2}
        shift; shift
        ;;
        --url-path)
        SEALED_SECRET_URL_PATH=${2}
        shift; shift
        ;;
        -v|--seal-value)
        SEAL_VALUE=${2}
        shift; shift
        ;;
        -R|--seal-random)
        SEAL_RANDOM=${2}
        shift; shift
        ;;
        -D|--seal-dockerconfig)
        SEAL_DOCKERCONFIG="true"
        shift
        ;;
        -n|--namespace)
        NAMESPACE=${2}
        shift; shift
        ;;
        -B|--skip-backup)
        SKIP_BACKUP="true"
        ;;
        --help)
        PRINT_HELP="true"
        ;;
        --verbose)
        VERBOSE="true"
        shift
        ;;
    esac
done

ENCRYPTED_KEY="${ENCRYPTED_KEY:-encryptedData}"
MASKED_KEYS_REGEX="labels|annotations|${ENCRYPTED_KEY}"
SEALED_SECRET_URL_PATH="$(sed s':^/::' <<< ${SEALED_SECRET_URL_PATH})"
SEALED_SECRET_URL="${SEALED_SECRET_URL:-https://$SEALED_SECRET_URL_HOST/$SEALED_SECRET_URL_PATH}"
NAMESPACE="${NAMESPACE:-default}"


if [ "$VERBOSE" == "true" ]; then
    echo
    echo ":: $(basename ${BASH_SOURCE}) ::"
    echo
    echo "env:"
    echo "  CONTEXT:                ${CONTEXT}"
    echo "  ENCRYPTED_KEY:          ${ENCRYPTED_KEY}"
    echo "  MASKED_KEYS_REGEX:      ${MASKED_KEYS_REGEX}"
    echo "  MARKER_KEY:             ${MARKER_KEY}"
    echo "  MARKER_VALUE_EVAL:      ${MARKER_VALUE_EVAL}"
    echo "  FILE_PATH:              ${FILE_PATH}"
    echo "  SEALED_SECRET_URL:      ${SEALED_SECRET_URL}"
    echo "  SEALED_SECRET_URL_HOST: ${SEALED_SECRET_URL_HOST}"
    echo "  SEALED_SECRET_URL_PATH: ${SEALED_SECRET_URL_PATH}"
    echo "  SEAL_VALUE:             ${SEAL_VALUE}"
    echo "  SEAL_RANDOM:            ${SEAL_RANDOM}"
    echo "  SEAL_DOCKERCONFIG:      ${SEAL_DOCKERCONFIG}"
    echo "  NAMESPACE:              ${NAMESPACE}"
    echo "  SKIP_BACKUP:            ${SKIP_BACKUP}"
    echo "  PRINT_HELP:             ${PRINT_HELP}"
    echo "  VERBOSE:                ${VERBOSE}"
fi


# Functions
function backup(){

    if [ "${SKIP_BACKUP}" != "true" ]; then
        echo
        echo "backup original file:"
        
        cp -v ${FILE_PATH} ${FILE_PATH}.$(date +'backup-%y%m%d-%H%M%S-%3N')
    fi
}


function seal_value(){

    if [ -n "${1}" ]; then
        STDIN="${1}"
    else
        read STDIN
    fi

    if [ "${VERBOSE}" == "true" ]; then
        echo
        echo "seal_value:"
        echo "  value:      \"${STDIN}\""
        echo "  namespace:  \"${NAMESPACE}\""
        echo
    fi

    if [ ! -z "${SEALED_SECRET_URL}" ]; then
        echo -n "${STDIN}" | kubeseal --cert "${SEALED_SECRET_URL}" \
                                 --namespace ${NAMESPACE} \
                                 --scope namespace-wide \
                                 --raw \
                                 --from-file=/dev/stdin    
    else
        return 1
    fi
}


function seal_dockerconfig(){

    if [ "$(yq eval ${1}' | ... comments = "" | has("'${ENCRYPTED_KEY}'")' ${FILE_PATH})" == "false" ]; then
        
        URL="$(yq eval ${1}'.url | ... comments = ""' ${FILE_PATH})"
        USERNAME="$(yq eval ${1}'.username | ... comments = ""' ${FILE_PATH})"
        PASSWORD="$(yq eval ${1}'.password | ... comments = ""' ${FILE_PATH})"
        
        if [ "${VERBOSE}" == "true" ]; then unset VERBOSE; fi
        
        VALUE="$(printf "{\"auths\": {\"%s\": {\"auth\": \"%s\"}}}" ${URL} $(printf "%s:%s" ${USERNAME} ${PASSWORD} | base64) | seal_value)"

        if [ $? -eq 0 ]; then
            # Backup original file
            backup

            for KEY in url username password; do yq eval -i "del(${1}.${KEY})" ${FILE_PATH}; done
            
            yq eval -i ${PRETTY_PRINT} ${1}' |= (.'${ENCRYPTED_KEY}' = "'${VALUE}'")' ${FILE_PATH}
        fi

        if [ -z "${VERBOSE}" ]; then VERBOSE="true"; fi
    fi
}


# Seal value
if [ ! -z "${SEAL_VALUE}" ] || [ ${SEAL_RANDOM} -gt 0 ]; then
    if [ ${SEAL_RANDOM} -gt 0 ]; then
        seal_value "$(head /dev/urandom | tr -cd '[:alnum:]' | head -c ${SEAL_RANDOM})"
    else
        seal_value "${SEAL_VALUE}"
    fi

    echo; echo
fi


# Seal dockerconfig
if [ "${SEAL_DOCKERCONFIG}" == "true" ]; then 
    seal_dockerconfig "${CONTEXT}"

    echo
fi


# Seal values file
if [ ! -z "${CONTEXT}" ] && [ ! -z "${FILE_PATH}" ] && [ -z "${SEAL_VALUE}" ] && [ "${SEAL_DOCKERCONFIG}" == "false" ]; then

    if [ "$(yq eval ${CONTEXT}' | ... comments = "" | tag == "!!map"' ${FILE_PATH})" == "true" ]; then
        
        # Map (map)
        if [ "$(yq eval ${CONTEXT}' | ... comments = "" | has("'${ENCRYPTED_KEY}'")' ${FILE_PATH})" == "false" ]; then

            # Backup original file
            backup
            
            yq eval -i ${PRETTY_PRINT} "${CONTEXT} |= (.${ENCRYPTED_KEY} = {})" ${FILE_PATH}

            for KEY in $(yq eval ${CONTEXT}' | ... comments = "" | keys' ${FILE_PATH} | awk '{ print $2 }' | grep -Ev "${MASKED_KEYS_REGEX}"); do
                
                VALUE="$(yq eval ${CONTEXT}'.'${KEY}' | ... comments = ""' ${FILE_PATH} | seal_value)"

                yq eval -i ${PRETTY_PRINT} "del(${CONTEXT}.${KEY})" ${FILE_PATH}
                yq eval -i ${PRETTY_PRINT} ${CONTEXT}'.'${ENCRYPTED_KEY}' |= (.'${KEY}' = "'${VALUE}'")' ${FILE_PATH}
            done
        fi; echo

    else
        # Array (seq)
        I=0

        # Backup original file
        backup

        while [ ${I} -lt $(yq eval ${CONTEXT}' | ... comments = "" | length' ${FILE_PATH}) ]; do

            if [ "$(yq eval ${CONTEXT}'['${I}'] | ... comments = "" | has("'${ENCRYPTED_KEY}'")' ${FILE_PATH})" == "false" ]; then

                MAP=""

                for KEY in $(yq eval ${CONTEXT}'['${I}'] | ... comments = "" | keys' ${FILE_PATH} | awk '{ print $2 }'); do

                    VALUE="$(yq eval ${CONTEXT}'['${I}'].'${KEY}' | ... comments = ""' ${FILE_PATH} | seal_value)"

                    if [ -z "${MAP}" ]; then
                        MAP="$(printf ".%s = \"%s\"" ${KEY} ${VALUE})"
                    else
                        MAP="$(printf "%s, .%s = \"%s\"" ${MAP} ${KEY} ${VALUE})"
                    fi
                done

                yq eval -i "del(${CONTEXT}[${I}].*)" ${FILE_PATH}

                # Set marker
                if [ ! -z "${MARKER_KEY}" ] && [ ! -z "${MARKER_VALUE_EVAL}" ]; then
                    yq eval -i ${PRETTY_PRINT} ${CONTEXT}'['${I}'] |= (.'${MARKER_KEY}' = "'$(eval ${MARKER_VALUE_EVAL})'")' ${FILE_PATH}
                fi

                yq eval -i ${PRETTY_PRINT} "${CONTEXT}[${I}] |= (.${ENCRYPTED_KEY} = {})" ${FILE_PATH}
                yq eval -i ${PRETTY_PRINT} "${CONTEXT}[${I}].${ENCRYPTED_KEY} |= (${MAP})" ${FILE_PATH}
            fi

            I=$((I+1))
        done; echo
    fi
fi


if [ "$VERBOSE" == "true" ]; then
    echo ":: $(basename ${BASH_SOURCE}) ::"
    echo
fi