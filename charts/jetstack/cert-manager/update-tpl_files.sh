#!/bin/env sh

for FILE_NAME in _helpers.tpl; do
    BASE_URL="https://raw.githubusercontent.com/cert-manager/cert-manager/master/deploy/charts/cert-manager/templates"

    if [ "$(which curl)" ]; then
        curl -o templates/${FILE_NAME} ${BASE_URL}/${FILE_NAME}
    else
        wget -O templates/${FILE_NAME} ${BASE_URL}/${FILE_NAME}
    fi
done