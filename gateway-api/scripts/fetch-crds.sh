#!/bin/sh
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CHART_DIR="$(dirname "$SCRIPT_DIR")"

# Read Gateway API version from values.yaml (crds.version)
APP_VERSION=$(yq '.crds.version // ""' "$CHART_DIR/values.yaml")

if [ -z "$APP_VERSION" ]; then
  echo "ERROR: Could not read crds.version from values.yaml" >&2
  exit 1
fi

RAW_URL="https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v${APP_VERSION}/config/crd"
STANDARD_DIR="$CHART_DIR/crds/standard"
EXPERIMENTAL_DIR="$CHART_DIR/crds/experimental"

# Parse resource list from a kustomization.yaml (strips leading whitespace/"- " and optional path prefixes)
parse_resources() {
  grep -E '^[[:space:]]*- ' | sed -E 's/^[[:space:]]*- //' | sed 's|.*/||'
}

# Download a URL to a file, then drop it unless it's a CustomResourceDefinition.
# Helm's crds/ directory convention requires every file there to be a CRD (helm lint
# and `helm install` both reject anything else), so non-CRD resources bundled upstream
# (e.g. Gateway API's vap_safeupgrades.yaml ValidatingAdmissionPolicy) must not be stored here.
fetch_crd_only() {
  url="$1"
  dest="$2"
  curl -sSfL "$url" -o "$dest"
  if ! grep -q '^kind: CustomResourceDefinition$' "$dest"; then
    echo "    skipped (not a CustomResourceDefinition, incompatible with Helm's crds/ convention)"
    rm -f "$dest"
  fi
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
  fetch_crd_only "${RAW_URL}/standard/${crd}" "${STANDARD_DIR}/${crd}"
done

# Download ALL experimental CRDs (includes enhanced versions of standard CRDs)
EXP_COUNT=$(echo "$EXPERIMENTAL_CRDS" | wc -l | tr -d ' ')
echo "Downloading experimental CRDs (${EXP_COUNT} files)..."
echo "$EXPERIMENTAL_CRDS" | while IFS= read -r crd; do
  echo "  ${crd}"
  fetch_crd_only "${RAW_URL}/experimental/${crd}" "${EXPERIMENTAL_DIR}/${crd}"
done

STANDARD_SAVED=$(find "$STANDARD_DIR" -name '*.yaml' | wc -l | tr -d ' ')
EXP_SAVED=$(find "$EXPERIMENTAL_DIR" -name '*.yaml' | wc -l | tr -d ' ')
echo "Done. CRDs saved to crds/standard/ (${STANDARD_SAVED}) and crds/experimental/ (${EXP_SAVED})"

# --- Envoy Gateway CRDs ---
# Read version from values.yaml (envoyGateway.crds.version)
ENVOY_VERSION=$(yq '.envoyGateway.crds.version // ""' "$CHART_DIR/values.yaml")

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
  if ! grep -q '^kind: CustomResourceDefinition$' "${ENVOY_DIR}/${crd}"; then
    echo "    skipped (not a CustomResourceDefinition, incompatible with Helm's crds/ convention)"
    rm -f "${ENVOY_DIR}/${crd}"
  fi
done

ENVOY_SAVED=$(find "$ENVOY_DIR" -name '*.yaml' | wc -l | tr -d ' ')
echo "Done. Envoy Gateway CRDs saved to crds/envoyproxy/ (${ENVOY_SAVED})"
