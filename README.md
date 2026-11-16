# helm-charts

Helm charts for running platform components and applications on Kubernetes: Gateway API and Envoy Gateway, the Grafana LGTM observability stack (Alloy, dashboards), RBAC management and a general-purpose application chart. Each chart is published as an OCI artifact to the GitHub Container Registry under `oci://ghcr.io/jc3rny/helm`.

> **Retired:** `web-app` and `common-tpls` are no longer maintained and were removed from `main` on 2026-11-16. Final versions: [web-app-3.1.1](https://github.com/jC3rny/helm-charts/tree/web-app-3.1.1) and [common-tpls-1.0.1](https://github.com/jC3rny/helm-charts/tree/common-tpls-1.0.1). See [Retired charts](#retired-charts).

## Charts

| Chart | Version | Description |
|---|---|---|
| [envoy-gateway](envoy-gateway/) | 0.1.0+1.9.1 | Envoy Gateway control plane, GatewayClass and Prometheus monitors |
| [gateway-api](gateway-api/) | 0.4.0+1.6.1 | Gateway API CRDs (standard and experimental), Envoy Gateway CRDs, and templated Gateway, route and policy resources |
| [grafana-alloy](grafana-alloy/) | 0.1.0+1.8.1 | Grafana Alloy DaemonSet with a preconfigured pipeline for logs, metrics, traces and profiles (LGTM) |
| [grafana-dashboards](grafana-dashboards/) | 0.3.1 | Grafana dashboards, delivered as ConfigMaps for the Grafana sidecar or as `GrafanaDashboard` / `GrafanaFolder` resources for grafana-operator |
| [kube-rbac](kube-rbac/) | 1.1.0 | Group-based RBAC: ClusterRoles, per-namespace RoleBindings and optional ServiceAccount kubeconfigs |
| [xapplication](xapplication/) | 0.1.0 | One application: a Deployment or StatefulSet with its Services, optionally an HTTPRoute, a canary, an autoscaler, a PodDisruptionBudget, persistent volumes, secrets through External Secrets or Sealed Secrets, and monitoring |

Versions with a `+` suffix wrap or track an upstream release: `0.1.0+1.9.1` is version `0.1.0` of this chart for upstream `1.9.1`.

## Usage

```sh
helm show values oci://ghcr.io/jc3rny/helm/<chart> --version <version>
helm install <release> oci://ghcr.io/jc3rny/helm/<chart> --version <version> -f values.yaml
```

As a dependency in another chart:

```yaml
dependencies:
  - name: grafana-alloy
    version: 0.1.0+1.8.1
    repository: oci://ghcr.io/jc3rny/helm
```

## Development

The root `Makefile` drives all checks and releases:

```sh
make lint                       # helm lint --strict on every chart (or CHART=<name>)
make test                       # render every chart with each <chart>/ci/*.yaml (default values if it has none)
make login                      # log in to ghcr.io (classic PAT with write:packages, GITHUB_PAT in .env)
make package CHART=<name>       # package the committed chart into the repository root
make release CHART=<name>       # package and push to oci://ghcr.io/jc3rny/helm
```

- `release` packages the committed chart only and refuses to overwrite a version that is already published.
- Every chart lists this repository first under `sources:` in its `Chart.yaml`, which links the published package to this repository on GitHub.
- Each release is tagged `<chart>-<version>`, for example `grafana-alloy-0.1.0+1.8.1`.

[seal-it.sh](seal-it.sh) is a helper around `kubeseal` and `yq` that seals values in a values file in place.

## Retired charts

| Chart | Last version | Status |
|---|---|---|
| `web-app` | [3.1.1](https://github.com/jC3rny/helm-charts/tree/web-app-3.1.1) | Deprecated, removed from `main` on 2026-11-16 |
| `common-tpls` | [1.0.1](https://github.com/jC3rny/helm-charts/tree/common-tpls-1.0.1) | Deprecated, removed from `main` on 2026-11-16 (library chart used by `web-app`) |

- All published versions stay available on GHCR, so pinned installs keep working. Helm prints a deprecation warning for the last versions.
- No further releases or fixes are planned.
- The source of the final versions stays available at their tags, linked in the table.

```sh
helm pull oci://ghcr.io/jc3rny/helm/web-app --version 3.1.1
```

Older releases of `envoy-gateway`, `gateway-api` and `grafana-dashboards` remain on Docker Hub (`oci://registry-1.docker.io/jc3rny`), but new releases are published only to GHCR.

## License

[GPL-3.0](LICENSE)
