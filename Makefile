# Lint, render-test and release the Helm charts in this repository.
#
#   make lint                   helm lint --strict every chart (or CHART=<name>)
#   make test                   render every chart with default values and each <chart>/ci/*.yaml
#   make login                  log in to GHCR with a classic PAT (write:packages scope),
#                               read from GITHUB_PAT in .env or the environment, else prompted
#   make release CHART=<name>   package the committed chart and push it to $(REGISTRY)

REGISTRY  ?= oci://ghcr.io/jc3rny/helm
GHCR_USER ?= jc3rny
CHARTS    := $(patsubst %/Chart.yaml,%,$(shell git ls-files ':(glob)*/Chart.yaml'))
CHART     ?= $(CHARTS)

.PHONY: lint test login release

lint:
	helm lint --strict $(CHART)

test:
	@set -e; for c in $(CHART); do \
		if helm show chart $$c | grep -q '^type: library'; then echo "==> $$c: library chart, skipped"; continue; fi; \
		for v in '' $$(ls $$c/ci/*.yaml 2> /dev/null); do \
			echo "==> $$c $${v:-(default values)}"; \
			helm template test $$c $${v:+-f $$v} > /dev/null; \
		done; \
	done

login:
	@if [ -f .env ]; then . ./.env; fi; \
	if [ -n "$${GITHUB_PAT:-}" ]; then \
		printf '%s' "$$GITHUB_PAT" | helm registry login ghcr.io -u $(GHCR_USER) --password-stdin; \
	else \
		helm registry login ghcr.io -u $(GHCR_USER); \
	fi

release:
	$(if $(filter-out 1,$(words $(CHART))),$(error set CHART to one of: $(CHARTS)))
	$(if $(filter $(CHART),$(CHARTS)),,$(error unknown chart '$(CHART)', expected one of: $(CHARTS)))
	@test -z "$$(git status --porcelain -- $(CHART))" || { echo "$(CHART) has uncommitted changes"; exit 1; }
	@set -e; v=$$(helm show chart $(CHART) | awk '/^version:/ {print $$2}'); \
	if helm show chart $(REGISTRY)/$(CHART) --version "$$v" > /dev/null 2>&1; then \
		echo "$(CHART) $$v is already in $(REGISTRY)"; exit 1; \
	fi; \
	mkdir -p tmp; d=$$(mktemp -d tmp/release.XXXXXX); trap 'rm -rf "$$d"' EXIT; \
	git archive HEAD $(CHART) | tar -x -C $$d; \
	helm package $$d/$(CHART) -d tmp; \
	helm push tmp/$(CHART)-$$v.tgz $(REGISTRY)
