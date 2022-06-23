#!/bin/bash
#. get-repoSecrets.sh >> values-dev.yaml

KUBE_CONFIG=${1:-$HOME/.kube/config}
SEAL_SCRIPT_PATH=$2

NAMESPACE=argocd

KUBECTL="kubectl --kubeconfig $KUBE_CONFIG -n $NAMESPACE"

echo "repositories:"

for REPO in `$KUBECTL get secrets -o json |jq -r '.items[] |select(.metadata.name |test("repo-")).metadata.name'`; do
  
  REPO_NAME=`$KUBECTL get cm argocd-cm -o json |jq -r '.data.repositories' |yq -r '.[] |select(.passwordSecret.name=="'$REPO'").name'`
  REPO_TYPE=`$KUBECTL get cm argocd-cm -o json |jq -r '.data.repositories' |yq -r '.[] |select(.passwordSecret.name=="'$REPO'").type'`
  REPO_AUTH_USERNAME=`$KUBECTL get secrets $REPO -o jsonpath='{ .data.username }' |base64 --decode`
  REPO_AUTH_PASSWORD=`$KUBECTL get secrets $REPO -o jsonpath='{ .data.password }' |base64 --decode`
  REPO_SSH_PRIVATE_KEY=`$KUBECTL get secrets $REPO -o jsonpath='{ .data.sshPrivateKey }' |base64 --decode`
  REPO_INSECURE=`$KUBECTL get cm argocd-cm -o json |jq -r '.data.repositories' |yq -r '.[] |select(.passwordSecret.name=="'$REPO'").insecure'`
  REPO_INSECURE_IGNORE_HOST_KEY=`$KUBECTL get cm argocd-cm -o json |jq -r '.data.repositories' |yq -r '.[] |select(.passwordSecret.name=="'$REPO'").insecureIgnoreHostKey'`

  echo "  - url: `$KUBECTL get cm argocd-cm -o json |jq -r '.data.repositories' |yq -r '.[] |select(.passwordSecret.name=="'$REPO'").url'`"
  if [ "$REPO_NAME" != "null" ]; then echo "    name: $REPO_NAME"; fi
  echo "    type: $REPO_TYPE"
  echo "    auth:"
  echo "      secretName: $REPO"
  echo "      username: $REPO_AUTH_USERNAME"
  if [ "$SEAL_SCRIPT_PATH" == "" ]; then
    echo "      password: $REPO_AUTH_PASSWORD"
  else
    #echo "      sealedPassword: `. $(dirname $BASH_SOURCE)/seal-dev.sh $REPO_AUTH_PASSWORD`"
    echo "      sealedPassword: `. $SEAL_SCRIPT_PATH $REPO_AUTH_PASSWORD`"
  fi
  if [ -n "$REPO_SSH_PRIVATE_KEY" ]; then echo "      sshPrivateKey: $REPO_SSH_PRIVATE_KEY"; fi
  if [ "$REPO_INSECURE" != "null" ]; then echo "    insecure: $REPO_INSECURE"; fi
  if [ "$REPO_INSECURE_IGNORE_HOST_KEY" != "null" ]; then echo "    insecureIgnoreHostKey: $REPO_INSECURE_IGNORE_HOST_KEY"; fi
done