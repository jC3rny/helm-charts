#!/bin/env sh

echo -n "$1" | kubeseal --cert 'https://sealed-secrets.example.local/v1/cert.pem' \
                        --namespace ${2:-default} \
                        --scope namespace-wide \
                        --raw \
                        --from-file=/dev/stdin