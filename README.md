# stalwart-helm

[![CI](https://github.com/itsh-cloud/stalwart-helm/actions/workflows/ci.yaml/badge.svg)](https://github.com/itsh-cloud/stalwart-helm/actions/workflows/ci.yaml)
[![License](https://img.shields.io/github/license/itsh-cloud/stalwart-helm)](LICENSE)
[![Release](https://img.shields.io/github/v/release/itsh-cloud/stalwart-helm)](https://github.com/itsh-cloud/stalwart-helm/releases)

Helm chart for [Stalwart Mail Server](https://stalw.art/).

> **Chart 0.4.0 targets Stalwart 0.16+.** 0.16 replaced the TOML configuration
> file with a datastore-backed model, so the YAML-to-TOML conversion that earlier
> chart versions provided no longer has anything to convert. Deployments still on
> Stalwart 0.15.x should stay on chart 0.3.x. `helm upgrade` alone does **not**
> migrate a 0.15 deployment: see [UPGRADING/v0_16.md](https://github.com/stalwartlabs/stalwart/blob/main/UPGRADING/v0_16.md).

## Features

- **Datastore bootstrap** - `config` renders to the small `config.json` that 0.16 reads at startup, with schema validation on the tagged union so a misspelled `@type` fails at render rather than at pod start.
- **Recovery mode** - first-class support for booting with only the management listener to apply configuration to a server that cannot start normally.
- **StatefulSet** with RocksDB persistence and health probes (startup, liveness, readiness)
- **Optional Prometheus metrics** with ServiceMonitor support (including BasicAuth)
- **Optional Ingress and HTTPRoute** templates for the management UI
- **Production-tested** on real mail infrastructure

## Prerequisites

- Kubernetes >= 1.26
- Helm >= 3.12

## Quick Start

```bash
helm install stalwart oci://ghcr.io/itsh-cloud/charts/stalwart \
  --namespace mail --create-namespace \
  --set config.server.hostname=mail.example.com
```

Or from source:

```bash
git clone https://github.com/itsh-cloud/stalwart-helm.git
helm install stalwart ./stalwart-helm/chart/stalwart \
  --namespace mail --create-namespace
```

Access the admin UI:

```bash
kubectl -n mail port-forward svc/stalwart 8080:8080
# Open http://localhost:8080
```

## Configuration

Since Stalwart 0.16 the configuration file holds a **DataStore object and
nothing else**. Listeners, TLS, queues, spam filtering, DKIM, webhooks and
directories all live inside the datastore itself and are managed with
[`stalwart-cli`](https://github.com/stalwartlabs/cli) or the WebUI, not by this
chart.

So `config` here is the bootstrap datastore, rendered to `config.json`:

```yaml
config:
  "@type": RocksDb
  path: /var/lib/stalwart
```

The `@type` discriminator is required and validated against
`values.schema.json`; a typo fails the render instead of producing a pod that
cannot start.

### Applying the rest of the configuration

Boot once in recovery mode, apply a plan, then redeploy without it:

```yaml
recoveryMode:
  enabled: true
recoveryAdmin:
  enabled: true
  value: "admin:choose-a-real-password"
```

```bash
kubectl -n mail port-forward svc/stalwart 8080:8080
stalwart-cli --url http://127.0.0.1:8080 --user admin --password ... apply --file plan.ndjson
```

Then set both back to `false` and upgrade again. `STALWART_RECOVERY_ADMIN`
authenticates even outside recovery mode, so it is a back door and must not be
left enabled.

### Paths

`configPath` and `dataPath` default to `/etc/stalwart/config.json` and
`/var/lib/stalwart`, matching the upstream image. If you are upgrading a
deployment whose volume is mounted elsewhere, set `dataPath` to the existing
mount and point `config.path` at the same place. Rewriting the path is not
required, and a mismatch between the two is the documented way to end up with a
server that starts cleanly against an empty store.

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
| `config` | *(RocksDb at /var/lib/stalwart)* | Bootstrap DataStore object, rendered to `config.json` |
| `configPath` | `/etc/stalwart/config.json` | Where `config.json` is mounted |
| `dataPath` | `/var/lib/stalwart` | Where the data volume is mounted |
| `probePort` | `http` | Port the health probes target |
| `recoveryMode.enabled` | `false` | Boot with only the management listener |
| `recoveryAdmin.enabled` | `false` | Supply `STALWART_RECOVERY_ADMIN` (a back door) |
| `env` | `[]` | Additional environment variables |
| `envFrom` | `[]` | Environment variable sources |
| `extraVolumeMounts` | `[]` | Additional volume mounts |
| `extraVolumes` | `[]` | Additional volumes |
| `initContainers` | `[]` | Init containers |
| `command` | `[]` | Override the container entrypoint |
| `args` | `[]` | Override the container arguments |

See [values.yaml](chart/stalwart/values.yaml) for all available options.

## Examples

See the [examples/](examples/) directory for ready-to-use value files:

- [`minimal.yaml`](examples/minimal.yaml) - Bare minimum override
- [`s3-blob-storage.yaml`](examples/s3-blob-storage.yaml) - S3 for blob storage with env var secrets

```bash
helm install stalwart oci://ghcr.io/itsh-cloud/charts/stalwart \
  -f examples/s3-blob-storage.yaml \
  --namespace mail --create-namespace
```

### Raising the open-file limit

Container runtimes commonly set the `nofile` soft limit to 1024 while leaving a
much higher hard limit. That is low for a mail server, which holds a file
descriptor per SMTP, IMAP and outbound connection, and Stalwart does not raise
the soft limit itself. Once exhausted it fails connections and DNS lookups with
`No file descriptors available (os error 24)`.

Check what your runtime gives the container:

```bash
kubectl exec -n mail stalwart-0 -- grep 'open files' /proc/1/limits
```

Raising the soft limit up to the hard limit needs no extra privileges. Because
Kubernetes has no field for it, wrap the entrypoint:

```yaml
command: ["/bin/sh", "-c"]
args:
  - exec /usr/local/bin/stalwart --config /opt/stalwart/etc/config.toml
```

with the limit applied first:

```yaml
command: ["/bin/sh", "-c"]
args:
  - ulimit -n 65535 && exec /usr/local/bin/stalwart --config /opt/stalwart/etc/config.toml
```

The binary and config paths must match the image, so re-check them when changing
`image.tag`. Prefer raising the runtime's default if you can, since that fixes
every workload on the node rather than this one.

## Upgrading

When updating the `config:` section, the StatefulSet will automatically roll due to a config checksum annotation on the pod template.

## License

Apache 2.0 - see [LICENSE](LICENSE).
