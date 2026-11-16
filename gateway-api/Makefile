.PHONY: fetch-crds publish lint template

# Fetch Gateway API CRDs (version from values.yaml crds.version) and
# Envoy Gateway CRDs (version from values.yaml envoyGateway.crds.version).
fetch-crds:
	sh scripts/fetch-crds.sh

# Package and push the chart to the OCI registry.
publish:
	sh scripts/publish.sh

lint:
	helm lint .

template:
	helm template test .
