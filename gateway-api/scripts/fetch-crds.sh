#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHART_DIR="$(dirname "$SCRIPT_DIR")"

# Read appVersion from Chart.yaml
APP_VERSION=$(grep '^appVersion:' "$CHART_DIR/Chart.yaml" | awk '{print $2}' | tr -d '"')

if [[ -z "$APP_VERSION" ]]; then
  echo "ERROR: Could not read appVersion from Chart.yaml" >&2
  exit 1
fi

BASE_URL="https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v${APP_VERSION}/config/crd"
STANDARD_DIR="$CHART_DIR/crds/standard"
EXPERIMENTAL_DIR="$CHART_DIR/crds/experimental"

# Standard CRD files
STANDARD_CRDS=(
  "gateway.networking.k8s.io_backendtlspolicies.yaml"
  "gateway.networking.k8s.io_gatewayclasses.yaml"
  "gateway.networking.k8s.io_gateways.yaml"
  "gateway.networking.k8s.io_grpcroutes.yaml"
  "gateway.networking.k8s.io_httproutes.yaml"
  "gateway.networking.k8s.io_referencegrants.yaml"
)

# Experimental-only CRD files (gateway.networking.k8s.io only, not in standard)
EXPERIMENTAL_CRDS=(
  "gateway.networking.k8s.io_tcproutes.yaml"
  "gateway.networking.k8s.io_tlsroutes.yaml"
  "gateway.networking.k8s.io_udproutes.yaml"
)

echo "Fetching Gateway API CRDs v${APP_VERSION}..."

# Clean and recreate directories
rm -rf "$STANDARD_DIR" "$EXPERIMENTAL_DIR"
mkdir -p "$STANDARD_DIR" "$EXPERIMENTAL_DIR"

# Download standard CRDs
echo "Downloading standard CRDs..."
for crd in "${STANDARD_CRDS[@]}"; do
  echo "  ${crd}"
  curl -sSfL "${BASE_URL}/standard/${crd}" -o "${STANDARD_DIR}/${crd}"
done

# Download experimental-only CRDs
echo "Downloading experimental CRDs..."
for crd in "${EXPERIMENTAL_CRDS[@]}"; do
  echo "  ${crd}"
  curl -sSfL "${BASE_URL}/experimental/${crd}" -o "${EXPERIMENTAL_DIR}/${crd}"
done

echo "Done. CRDs saved to crds/standard/ and crds/experimental/"
