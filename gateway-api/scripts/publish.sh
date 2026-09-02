#!/bin/sh
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CHART_DIR="$(dirname "$SCRIPT_DIR")"
CHART_NAME="$(basename "$CHART_DIR")"
REGISTRY="oci://registry-1.docker.io/jc3rny"
PASSWORD_FILE="$CHART_DIR/tmp/dockerhub"

if [ ! -f "$PASSWORD_FILE" ]; then
  echo "ERROR: Password file not found: $PASSWORD_FILE" >&2
  exit 1
fi

# Login
helm registry login registry-1.docker.io -u jc3rny --password-stdin < "$PASSWORD_FILE"

# Package (version comes straight from Chart.yaml's `version` field)
CHART_PKG="$(helm package "$CHART_DIR" --destination "$CHART_DIR/tmp" | awk '{print $NF}')"

echo "Packaged: $CHART_PKG"

# Push
helm push "$CHART_PKG" "$REGISTRY"

# Cleanup
rm -f "$CHART_PKG"
