#!/bin/env sh

CHART_PATH=${1:-.}
CHART_PATH=${CHART_PATH%/}

TMP_DIR="${CHART_PATH}/pkg"

mkdir -p ${TMP_DIR}

#rm -fv ${TMP_DIR}/Chart.lock

helm package ${CHART_PATH} --destination ${TMP_DIR}/ &> /dev/null
helm repo index ${TMP_DIR}/ &> /dev/null

CHART_NAME=$(yq -r '.name' ${CHART_PATH}/Chart.yaml)
CHART_VERSION=$(yq -r '.version' ${CHART_PATH}/Chart.yaml)
CHART_HOME=$(yq -r '.home' ${CHART_PATH}/Chart.yaml)

PKG_DIGEST=$(yq -r '.entries."'$CHART_NAME'"[] | select(.version == "'$CHART_VERSION'").digest' ${TMP_DIR}/index.yaml)
PKG_GENERATED=$(yq -r '.generated' ${TMP_DIR}/index.yaml)

cat /dev/null > ${TMP_DIR}/Chart.lock

echo ""
echo "dependencies:" | tee -a ${TMP_DIR}/Chart.lock
echo "  - name: $CHART_NAME" | tee -a ${TMP_DIR}/Chart.lock
echo "    repository: $CHART_HOME" | tee -a ${TMP_DIR}/Chart.lock
echo "    version: $CHART_VERSION" | tee -a ${TMP_DIR}/Chart.lock
echo "digest: sha256:$PKG_DIGEST" | tee -a ${TMP_DIR}/Chart.lock
echo "generated: $PKG_GENERATED" | tee -a ${TMP_DIR}/Chart.lock
echo ""

#rm -fv ${TMP_DIR}/index.yaml