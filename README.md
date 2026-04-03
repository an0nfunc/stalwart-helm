# stalwart-helm

[![CI](https://github.com/an0nfunc/stalwart-helm/actions/workflows/ci.yaml/badge.svg)](https://github.com/an0nfunc/stalwart-helm/actions/workflows/ci.yaml)
[![License](https://img.shields.io/github/license/an0nfunc/stalwart-helm)](LICENSE)
[![Release](https://img.shields.io/github/v/release/an0nfunc/stalwart-helm)](https://github.com/an0nfunc/stalwart-helm/releases)

Helm chart for [Stalwart Mail Server](https://stalw.art/) with YAML-to-TOML config conversion.

## Features

- **YAML-to-TOML config** - Write your Stalwart configuration as native YAML in `values.yaml`; the chart automatically renders it to TOML. No more escaping TOML in ConfigMaps.
- **StatefulSet** with RocksDB persistence and health probes (startup, liveness, readiness)
- **Optional Prometheus metrics** with ServiceMonitor support (including BasicAuth)
- **Optional Ingress and HTTPRoute** templates for the management UI
- **Production-tested** on real mail infrastructure

## Prerequisites

- Kubernetes >= 1.26
- Helm >= 3.12

## Quick Start

```bash
helm install stalwart oci://ghcr.io/an0nfunc/stalwart-helm/chart \
  --namespace mail --create-namespace \
  --set config.server.hostname=mail.example.com
```

Or from source:

```bash
git clone https://github.com/an0nfunc/stalwart-helm.git
helm install stalwart ./stalwart-helm/chart/stalwart \
  --namespace mail --create-namespace
```

Access the admin UI:

```bash
kubectl -n mail port-forward svc/stalwart 8080:8080
# Open http://localhost:8080 (default: admin / changeme)
```

## YAML-to-TOML Configuration

This chart's key feature is native YAML configuration. Instead of embedding raw TOML in a ConfigMap, you write Stalwart's configuration as YAML under the `config:` key in your values file. The chart's template engine converts it to TOML automatically.

**Example** - your `values.yaml`:

```yaml
config:
  server:
    hostname: "mail.example.com"
  storage:
    data: "rocksdb"
    blob: "s3"
  store:
    s3:
      type: "s3"
      bucket: "my-mail-bucket"
      endpoint: "https://s3.example.com"
```

**Rendered** `config.toml`:

```toml
server.hostname = "mail.example.com"
storage.data = "rocksdb"
storage.blob = "s3"
store.s3.type = "s3"
store.s3.bucket = "my-mail-bucket"
store.s3.endpoint = "https://s3.example.com"
```

Stalwart supports environment variable substitution in config values using `%{env:VAR_NAME}%` syntax. Combine this with `envFrom` to inject secrets:

```yaml
config:
  authentication:
    fallback-admin:
      secret: "%{env:ADMIN_PASSWORD}%"

envFrom:
  - secretRef:
      name: stalwart-secrets
```

## Configuration

| Key | Default | Description |
|-----|---------|-------------|
| `image.repository` | `stalwartlabs/stalwart` | Container image |
| `image.tag` | `""` (defaults to `v<appVersion>-alpine`) | Image tag |
| `replicas` | `1` | Number of replicas |
| `service.type` | `ClusterIP` | Service type (`ClusterIP`, `LoadBalancer`, `NodePort`) |
| `service.annotations` | `{}` | Service annotations (e.g., cloud LB config) |
| `service.ports` | smtp/submission/imap/imaps/https | Exposed ports |
| `ingress.enabled` | `false` | Enable Ingress for management UI |
| `httpRoute.enabled` | `false` | Enable Gateway API HTTPRoute for management UI |
| `persistence.enabled` | `true` | Enable persistent storage |
| `persistence.storageClass` | `""` | Storage class |
| `persistence.size` | `50Gi` | Volume size |
| `metrics.enabled` | `false` | Enable Prometheus metrics service |
| `metrics.serviceMonitor.enabled` | `false` | Create ServiceMonitor |
| `config` | *(minimal RocksDB config)* | Stalwart config as YAML (rendered to TOML) |
| `envFrom` | `[]` | Environment variable sources |
| `extraVolumeMounts` | `[]` | Additional volume mounts |
| `extraVolumes` | `[]` | Additional volumes |
| `initContainers` | `[]` | Init containers |

See [values.yaml](chart/stalwart/values.yaml) for all available options.

## Examples

See the [examples/](examples/) directory for ready-to-use value files:

- [`minimal.yaml`](examples/minimal.yaml) - Bare minimum override
- [`s3-blob-storage.yaml`](examples/s3-blob-storage.yaml) - S3 for blob storage with env var secrets

```bash
helm install stalwart oci://ghcr.io/an0nfunc/stalwart-helm/chart \
  -f examples/s3-blob-storage.yaml \
  --namespace mail --create-namespace
```

## Upgrading

When updating the `config:` section, the StatefulSet will automatically roll due to a config checksum annotation on the pod template.

## License

Apache 2.0 - see [LICENSE](LICENSE).
