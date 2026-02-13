# MCP Helm Stack

This repo provides a Helm Chart that deploys Grafana MCP and VictoriaMetrics MCP together.
It includes Gatekeeper-friendly security defaults (non-root, no privilege escalation, read-only FS, seccomp), plus probes and resource requests/limits.

## Structure

```
./mcp-stack
  Chart.yaml
  values.yaml
  templates/
    _helpers.tpl
    grafana-mcp-*.yaml
    victoriametrics-mcp-*.yaml
```

## Quick Start

Render templates:

```
helm template mcp ./mcp-stack
```

Install/upgrade:

```
helm upgrade --install mcp ./mcp-stack -f ./mcp-stack/values.yaml
```

## Image & Tag

Set repository and tag in `values.yaml`:

```
 grafanaMcp:
   image:
     repository: grafana/mcp-grafana
     tag: "<your-tag>"

 victoriaMetricsMcp:
   image:
     repository: ghcr.io/victoriametrics-community/mcp-victoriametrics
     tag: "<your-tag>"
```

## Security (Gatekeeper)

Defaults include:

- `podSecurityContext`: `runAsNonRoot`, `runAsUser`, `runAsGroup`, `fsGroup`, `seccompProfile: RuntimeDefault`
- `securityContext`: `allowPrivilegeEscalation: false`, `readOnlyRootFilesystem: true`, `capabilities.drop: ["ALL"]`

Override any of these in `values.yaml`.

## Probes & Resources

Default `livenessProbe` / `readinessProbe` use tcpSocket on the `http` port.
CPU/Memory requests and limits are set and can be overridden in `values.yaml`.

## Env & Secret

This chart can write env values into a Secret and inject them via `envFrom`.

Rules:

- `secret.create: true` → create Secret; `env` + `secret.data` are written; Deployment uses `envFrom`
- `secret.name: "xxx"` → do not create; reference existing Secret; `env` is not rendered
- neither set → `env` is rendered directly into Deployment (plain text)

If keys overlap, `secret.data` wins.

### Example: Create Secret and Inject

```
grafanaMcp:
  secret:
    create: true
  env:
    GRAFANA_URL: "https://grafana.example.com"
    GRAFANA_SERVICE_ACCOUNT_TOKEN: "xxxxx"
```

### Example: Use Existing Secret

```
grafanaMcp:
  secret:
    create: false
    name: "grafana-mcp-secret"
```

## Common Options (partial)

- `grafanaMcp.env.*` / `victoriaMetricsMcp.env.*`
- `grafanaMcp.secret.*` / `victoriaMetricsMcp.secret.*`
- `grafanaMcp.resources` / `victoriaMetricsMcp.resources`
- `grafanaMcp.securityContext` / `victoriaMetricsMcp.securityContext`
- `grafanaMcp.podSecurityContext` / `victoriaMetricsMcp.podSecurityContext`

## References

```
https://github.com/grafana/mcp-grafana
https://github.com/VictoriaMetrics-Community/mcp-victoriametrics
```
