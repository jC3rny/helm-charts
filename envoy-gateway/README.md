# envoy-gateway

Wrapper around the upstream [Envoy Gateway](https://gateway.envoyproxy.io/) Helm charts
(`gateway-helm` + `gateway-crds-helm`), adding the pieces upstream does not ship:

| resource | what it covers |
| --- | --- |
| `GatewayClass` | the class Gateways reference (`gateway.gatewayClassName`) |
| `ServiceMonitor` | control plane — Service `envoy-gateway`, port `metrics` (19001), `/metrics` |
| `PodMonitor` | data plane — Envoy proxy pods, port 19001, `/stats/prometheus` |

Gateways, HTTPRoutes and EnvoyProxy resources are **not** part of this chart — those come
from the `gateway-api` chart.

## Metrics

Upstream `gateway-helm` ships no ServiceMonitor or PodMonitor template. It only sets
`prometheus.io/scrape` pod annotations, which neither kube-prometheus-stack nor Grafana
Alloy consumes by default — so without this chart, nothing scrapes Envoy Gateway.

Both monitors are plain Prometheus Operator CRDs, read equally by the Prometheus Operator
and by Alloy (`prometheus.operator.servicemonitors` / `.podmonitors`). The
`monitoring.coreos.com` CRDs must exist in the cluster.

### Why the data plane needs a PodMonitor, not a ServiceMonitor

The controller-generated envoy Service is a LoadBalancer carrying only the Gateway's
listener ports. Port 19001 is never exposed through a Service, so there is nothing for a
ServiceMonitor to select.

### Required on every EnvoyProxy

Envoy Gateway declares the `metrics` container port **only** when proxy telemetry is on.
Every EnvoyProxy resource must therefore set:

```yaml
spec:
  telemetry:
    metrics:
      prometheus: {}
```

Without it the port does not exist and the PodMonitor finds no targets.

### Telling these metrics apart from cilium-envoy

If Cilium's `envoy.prometheus.serviceMonitor` is also enabled, both scrapers produce
metrics named `envoy_*` — they are both Envoy. The PodMonitor promotes two labels that
cilium-envoy series never carry, so:

```promql
envoy_cluster_upstream_rq_total{gateway!=""}   # Envoy Gateway
envoy_cluster_upstream_rq_total{gateway=""}    # cilium-envoy
```

## Notes

- `gatewayClass` is cluster-scoped. Disable it (`gatewayClass.enabled: false`) if a cluster
  runs more than one release of this chart, or the releases will contend for the same object.
- `metrics.podMonitor.namespaceSelector` defaults to `any: true` because proxies are created
  in their Gateway's namespace (`deploy.type: GatewayNamespace`). An explicit value replaces
  the default rather than merging with it.
- `envoy-gateway.config.envoyGateway.logging.level.default` ships as `debug`. Set it to
  `info` for production.
