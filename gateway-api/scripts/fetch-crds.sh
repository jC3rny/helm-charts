#!/bin/sh
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CHART_DIR="$(dirname "$SCRIPT_DIR")"

# Read appVersion from Chart.yaml
APP_VERSION=$(grep '^appVersion:' "$CHART_DIR/Chart.yaml" | awk '{print $2}' | tr -d '"')

if [ -z "$APP_VERSION" ]; then
  echo "ERROR: Could not read appVersion from Chart.yaml" >&2
  exit 1
fi

RAW_URL="https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v${APP_VERSION}/config/crd"
STANDARD_DIR="$CHART_DIR/crds/standard"
EXPERIMENTAL_DIR="$CHART_DIR/crds/experimental"

# Parse resource list from a kustomization.yaml (strips "- " prefix and optional path prefixes)
parse_resources() {
  grep '^- ' | sed 's/^- //' | sed 's|.*/||'
}

echo "Fetching Gateway API CRDs v${APP_VERSION}..."

# Fetch resource lists from kustomization files
STANDARD_CRDS=$(curl -sSfL "${RAW_URL}/kustomization.yaml" | parse_resources)
EXPERIMENTAL_CRDS=$(curl -sSfL "${RAW_URL}/experimental/kustomization.yaml" | parse_resources)

# Clean and recreate directories
rm -rf "$STANDARD_DIR" "$EXPERIMENTAL_DIR"
mkdir -p "$STANDARD_DIR" "$EXPERIMENTAL_DIR"

# Download standard CRDs
STANDARD_COUNT=$(echo "$STANDARD_CRDS" | wc -l | tr -d ' ')
echo "Downloading standard CRDs (${STANDARD_COUNT} files)..."
echo "$STANDARD_CRDS" | while IFS= read -r crd; do
  echo "  ${crd}"
  curl -sSfL "${RAW_URL}/standard/${crd}" -o "${STANDARD_DIR}/${crd}"
done

# Download ALL experimental CRDs (includes enhanced versions of standard CRDs)
EXP_COUNT=$(echo "$EXPERIMENTAL_CRDS" | wc -l | tr -d ' ')
echo "Downloading experimental CRDs (${EXP_COUNT} files)..."
echo "$EXPERIMENTAL_CRDS" | while IFS= read -r crd; do
  echo "  ${crd}"
  curl -sSfL "${RAW_URL}/experimental/${crd}" -o "${EXPERIMENTAL_DIR}/${crd}"
done

echo "Done. CRDs saved to crds/standard/ (${STANDARD_COUNT}) and crds/experimental/ (${EXP_COUNT})"

# --- Envoy Gateway CRDs ---
# Read version from values.yaml (envoyGateway.crds.version)
ENVOY_VERSION=$(grep -A2 '^envoyGateway:' "$CHART_DIR/values.yaml" | grep 'version:' | awk '{print $2}' | tr -d '"')

if [ -z "$ENVOY_VERSION" ]; then
  echo "WARNING: Could not read envoyGateway.crds.version from values.yaml, skipping Envoy Gateway CRDs" >&2
  exit 0
fi

ENVOY_RAW_URL="https://raw.githubusercontent.com/envoyproxy/gateway/${ENVOY_VERSION}/charts/gateway-crds-helm/templates/generated"
ENVOY_API_URL="https://api.github.com/repos/envoyproxy/gateway/contents/charts/gateway-crds-helm/templates/generated?ref=${ENVOY_VERSION}"
ENVOY_DIR="$CHART_DIR/crds/envoyproxy"

echo ""
echo "Fetching Envoy Gateway CRDs ${ENVOY_VERSION}..."

# Discover CRD filenames from GitHub API
ENVOY_CRDS=$(curl -sSfL "$ENVOY_API_URL" | python3 -c "import sys,json; [print(f['name']) for f in json.load(sys.stdin) if f['name'].endswith('.yaml')]")

# Clean and recreate directory
rm -rf "$ENVOY_DIR"
mkdir -p "$ENVOY_DIR"

# Download Envoy Gateway CRDs (strip Helm template wrappers)
ENVOY_COUNT=$(echo "$ENVOY_CRDS" | wc -l | tr -d ' ')
echo "Downloading Envoy Gateway CRDs (${ENVOY_COUNT} files)..."
echo "$ENVOY_CRDS" | while IFS= read -r crd; do
  echo "  ${crd}"
  curl -sSfL "${ENVOY_RAW_URL}/${crd}" \
    | sed '1{/^{{-.*}}$/d;}' \
    | sed '1{/^---$/d;}' \
    | tac | sed '1{/^$/d;}' | sed '1{/^{{-.*}}$/d;}' | tac \
    > "${ENVOY_DIR}/${crd}"
done

echo "Done. Envoy Gateway CRDs saved to crds/envoyproxy/ (${ENVOY_COUNT})"
