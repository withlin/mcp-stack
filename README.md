# Observability MCP Stack

Umbrella Helm chart that deploys official [Grafana MCP](https://github.com/grafana/mcp-grafana) and [VictoriaMetrics MCP](https://github.com/VictoriaMetrics-Community/mcp-victoriametrics) servers as Kubernetes workloads.

## Architecture

This chart follows the **dependency (umbrella) pattern** — the same approach used by `kube-prometheus-stack` and `loki-stack`. Official upstream charts are included as subcharts:

| Subchart | Source | Version | Port |
|---|---|---|---|
| `grafana-mcp` | [grafana-community/helm-charts](https://github.com/grafana-community/helm-charts/tree/main/charts/grafana-mcp) | 0.7.2 (appVersion 0.11.1) | 8000 |
| `mcp-victoriametrics` | [VictoriaMetrics-Community/mcp-victoriametrics](https://github.com/VictoriaMetrics-Community/mcp-victoriametrics/tree/main/k8s/helm) | 0.1.0 (appVersion 1.15.0) | 8080 |

```
observability-mcp/
├── Chart.yaml                          # Dependencies declared here
├── Chart.lock                          # Lock file (auto-generated)
├── values.yaml                         # Unified config for both subcharts
├── templates/
│   ├── _helpers.tpl
│   └── NOTES.txt
└── charts/
    ├── grafana-mcp/                    # Official Grafana MCP chart (from Helm repo)
    │   ├── Chart.yaml
    │   ├── values.yaml
    │   └── templates/
    └── mcp-victoriametrics/            # Official VM MCP chart (vendored from GitHub)
        ├── Chart.yaml
        ├── values.yaml
        └── templates/
```

## Prerequisites

- Kubernetes >= 1.25
- Helm >= 3.x
- A running Grafana instance (for grafana-mcp)
- A running VictoriaMetrics instance or VictoriaMetrics Cloud account (for mcp-victoriametrics)

## Quick Start

### 1. Update dependencies

```bash
cd observability-mcp
helm dependency update .
```

### 2. Install

```bash
# Both MCP servers (self-hosted VictoriaMetrics)
helm install mcp ./observability-mcp \
  --set "grafana-mcp.grafana.apiKey=<GRAFANA_SA_TOKEN>" \
  --set "mcp-victoriametrics.vm.entrypoint=http://vmselect:8481" \
  --namespace mcp --create-namespace

# Both MCP servers (VictoriaMetrics Cloud)
helm install mcp ./observability-mcp \
  --set "grafana-mcp.grafana.apiKey=<GRAFANA_SA_TOKEN>" \
  --set "mcp-victoriametrics.vm.cloudAPIKey=<VMC_API_KEY>" \
  --namespace mcp --create-namespace
```

### 3. Verify

```bash
kubectl get pods -n mcp
kubectl get svc -n mcp
```

### 4. Access (port-forward)

```bash
# Grafana MCP
kubectl port-forward svc/mcp-grafana-mcp 8000:8000 -n mcp

# VictoriaMetrics MCP
kubectl port-forward svc/mcp-mcp-victoriametrics 8080:8080 -n mcp
```

## Enable/Disable Components

Each subchart can be independently toggled:

```yaml
# Only deploy Grafana MCP
grafana-mcp:
  enabled: true
mcp-victoriametrics:
  enabled: false
```

```bash
# Or via CLI
helm install mcp ./observability-mcp \
  --set "mcp-victoriametrics.enabled=false" \
  --set "grafana-mcp.grafana.apiKey=<TOKEN>"
```

## Configuration

All values are passed to subcharts via the subchart name as key prefix. See [values.yaml](observability-mcp/values.yaml) for the full annotated configuration.

### Grafana MCP — Required Settings

| Parameter | Description |
|---|---|
| `grafana-mcp.grafana.url` | Grafana instance URL (default: `http://grafana:3000`) |
| `grafana-mcp.grafana.apiKey` | Service account token (chart creates a Secret) |
| `grafana-mcp.grafana.apiKeySecret.name` | Or reference an existing Secret |
| `grafana-mcp.grafana.apiKeySecret.key` | Key within the existing Secret |

### VictoriaMetrics MCP — Required Settings

Choose one mode:

**Self-hosted VictoriaMetrics:**

| Parameter | Description |
|---|---|
| `mcp-victoriametrics.vm.entrypoint` | VM entrypoint URL (required) |
| `mcp-victoriametrics.vm.type` | `single` or `cluster` (default: `single`) |
| `mcp-victoriametrics.vm.bearerToken` | Auth token (string or `valueFrom` map) |

**VictoriaMetrics Cloud:**

| Parameter | Description |
|---|---|
| `mcp-victoriametrics.vm.cloudAPIKey` | Cloud API key (enables cloud mode) |

## Tool Access Control

### Grafana MCP

Two complementary mechanisms for controlling which MCP tool categories are active:

**Blacklist mode** — disable specific categories via `--disable-<category>`:

```yaml
grafana-mcp:
  disabledCategories:
    - write        # read-only mode, no create/update/delete
    - admin        # hide team/role/permission tools
    - incident     # hide incident management tools
```

Available categories: `search`, `datasource`, `incident`, `prometheus`, `loki`, `elasticsearch`, `alerting`, `dashboard`, `folder`, `oncall`, `asserts`, `sift`, `admin`, `pyroscope`, `navigation`, `proxied`, `annotations`, `rendering`, `cloudwatch`, `examples`, `clickhouse`, `searchlogs`, `runpanelquery`, `write` (cross-cutting).

**Whitelist mode** — only enable specific categories via `extraArgs`:

```yaml
grafana-mcp:
  extraArgs:
    - --enabled-tools=search,datasource,prometheus,loki,dashboard
```

Default enabled categories: `search`, `datasource`, `incident`, `prometheus`, `loki`, `alerting`, `dashboard`, `folder`, `oncall`, `asserts`, `sift`, `pyroscope`, `navigation`, `proxied`, `annotations`, `rendering`.

Not enabled by default: `elasticsearch`, `admin`, `cloudwatch`, `clickhouse`, `examples`, `searchlogs`, `runpanelquery`.

### VictoriaMetrics MCP

Fine-grained tool-level disable via environment variables:

```yaml
mcp-victoriametrics:
  mcp:
    mode: sse
    disable:
      tools:              # disable individual tools by name
        - some_tool_name
      resources: false    # set true to disable all MCP resources
    heartbeatInterval: 30s
```

## Security (Gatekeeper / PSS Restricted)

Both subcharts ship with hardened security defaults that satisfy the Kubernetes Pod Security Standards **Restricted** profile:

| Control | Value |
|---|---|
| `runAsNonRoot` | `true` |
| `runAsUser` / `runAsGroup` | `1000` |
| `fsGroup` | `1000` |
| `readOnlyRootFilesystem` | `true` |
| `allowPrivilegeEscalation` | `false` |
| `capabilities.drop` | `[ALL]` |
| `seccompProfile.type` | `RuntimeDefault` |
| `seLinuxOptions.level` | `s0:c123,c456` (placeholder — adjust to your cluster) |

All security contexts are set at both **pod level** and **container level**.

> **Note**: `seLinuxOptions.level` is a placeholder. Replace `s0:c123,c456` with the actual MCS label for your cluster's SELinux policy.

## Health Probes

| Component | Liveness | Readiness |
|---|---|---|
| grafana-mcp | TCP socket on port `mcp-http` | TCP socket on port `mcp-http` |
| mcp-victoriametrics | HTTP GET `/health/liveness` | HTTP GET `/health/readiness` |

## Resources

Both subcharts have default resource requests and limits:

```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

## Ingress

Both subcharts support Ingress (disabled by default):

```yaml
grafana-mcp:
  ingress:
    enabled: true
    className: nginx
    hosts:
      - host: mcp-grafana.example.com
        paths:
          - path: /
            pathType: Prefix
    tls:
      - secretName: mcp-grafana-tls
        hosts:
          - mcp-grafana.example.com

mcp-victoriametrics:
  ingress:
    enabled: true
    className: nginx
    hosts:
      - host: mcp-vm.example.com
        paths:
          - path: /
            pathType: ImplementationSpecific
```

VictoriaMetrics MCP also supports Gateway API HTTPRoute:

```yaml
mcp-victoriametrics:
  route:
    enabled: true
    parentRefs:
      - name: my-gateway
        sectionName: http
```

## Upgrading Upstream Charts

```bash
# 1. Edit Chart.yaml — bump the version
# 2. For grafana-mcp (from Helm repo):
helm dependency update ./observability-mcp

# 3. For mcp-victoriametrics (vendored):
#    Replace charts/mcp-victoriametrics/ with the new version from upstream
#    Then run:
helm dependency update ./observability-mcp
```

## References

- [grafana/mcp-grafana](https://github.com/grafana/mcp-grafana) — Grafana MCP server source
- [grafana-community/helm-charts](https://github.com/grafana-community/helm-charts/tree/main/charts/grafana-mcp) — Official Grafana MCP Helm chart
- [VictoriaMetrics-Community/mcp-victoriametrics](https://github.com/VictoriaMetrics-Community/mcp-victoriametrics) — VictoriaMetrics MCP server source
- [VictoriaMetrics MCP Helm chart](https://github.com/VictoriaMetrics-Community/mcp-victoriametrics/tree/main/k8s/helm) — Official VM MCP Helm chart
