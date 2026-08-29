# Changelog

## v0.4.1

- `args` now defaults to `--config <configPath>`. 0.16 dropped the entrypoint
  wrapper that used to supply it and the image's entrypoint is the bare binary,
  so with 0.4.0 a deployment that did not override `args` started the container
  with no arguments: it printed usage and exited into CrashLoopBackOff. Setting
  `args` explicitly still overrides the default.

## v0.4.0

### Breaking

Stalwart 0.16 replaced the TOML configuration file with a datastore-backed
configuration model. The config file now holds a `DataStore` object and nothing
else; listeners, TLS, queues, spam filtering, DKIM, webhooks and directories all
live inside the datastore and are applied with `stalwart-cli`. This chart's
YAML-to-TOML conversion has no counterpart in that model and is removed.

- `config` is now a single Stalwart `DataStore` object rendered to
  `config.json`, not a tree rendered to `config.toml`. Render fails if the
  required `@type` discriminator is missing.
- The `stalwart.toToml` template helper is removed.
- The config file mounts at `/etc/stalwart/config.json` (was
  `/opt/stalwart/etc/config.toml`), and the data directory defaults to
  `/var/lib/stalwart` (was a hardcoded `/data`). Both are now values,
  `configPath` and `dataPath`.
- The `authentication.fallback-admin` render guard added in v0.2.0 is removed
  along with the setting it guarded. 0.16 supplies the bootstrap administrator
  through the `STALWART_RECOVERY_ADMIN` environment variable instead, which this
  chart now models with `recoveryAdmin`.

**Migration:** `helm upgrade` alone does **not** migrate a 0.15 deployment. The
0.15 settings have to be dumped, converted and applied to the new datastore
before the server will serve anything, and the first 0.16 boot performs a
one-way data migration. Follow upstream's `UPGRADING/v0_16.md` and stay on
v0.3.x until you have done so.

### Added

- `recoveryMode` (`enabled`, `port`, `logLevel`) sets `STALWART_RECOVERY_MODE*`,
  which disables every background service and exposes only the management
  listener, for applying configuration to a server that cannot start normally.
- `recoveryAdmin` supplies `STALWART_RECOVERY_ADMIN` from a chart-created or
  pre-existing Secret. The value is `user:password`; render fails if the
  password begins with `$`, `_` or `{`, which Stalwart parses as a pre-hashed
  secret rather than a password.
- `env` for additional environment variables.
- `probePort`, so the health probes can target a listener other than the
  management port.
- `values.schema.json`, which validates the `config` tagged union. A
  misspelled `@type` previously rendered fine and produced a pod that could not
  start.

### Unchanged on purpose

- `spec.serviceName`, the `volumeClaimTemplates` and the `http` container port
  keep their names. All three are either immutable on a StatefulSet or
  referenced by the metrics Service and the probes, so changing them would turn
  an upgrade into a recreate or silently detach monitoring.

## v0.3.0

- The container entrypoint and arguments can now be overridden with `command`
  and `args`. Both default to empty, so the image's own entrypoint is used
  unless you set them.

  The motivating case is the `nofile` soft limit. Runtimes commonly default it
  to 1024 against a far higher hard limit, which a mail server exhausts under
  load, failing connections and DNS lookups with `No file descriptors available
  (os error 24)`. Stalwart does not raise the limit itself and Kubernetes has no
  field for it, so the entrypoint has to be wrapped. The README carries the
  recipe.

## v0.2.2

- The project moved from `an0nfunc` to the `itsh-cloud` organisation. A GitHub
  transfer redirects the repository and the git remote, but it does **not** move
  GHCR packages, so `oci://ghcr.io/an0nfunc/stalwart-helm/chart/stalwart` is
  frozen at v0.2.1 and will never receive another version.

  **Migration:** pull from `oci://ghcr.io/itsh-cloud/charts/stalwart` instead.
  Chart contents are unchanged, so this is a source swap, not an upgrade.
- The README's install command was missing the chart name and could never
  resolve. Releases also now fail fast if `Chart.yaml` and the tag disagree.

## v0.2.1

- The service now supports `externalTrafficPolicy`, so deployments that need
  the client IP preserved can set it to `Local`.

## v0.2.0

### Breaking

- The chart no longer ships a default `authentication.fallback-admin.secret`.
  The configmap template now `fail`s render if the secret is unset OR equals
  the placeholder `"changeme"`. Stops new deployments from accidentally
  exposing the mail server with publicly-known credentials. Existing
  deployments that pass an explicit secret (or env-var reference like
  `"%{env:VAR}%"`) are unaffected — `helm upgrade` succeeds normally.

  **Migration:** if you currently rely on the chart default, add to your
  values:
  ```yaml
  config:
    authentication:
      fallback-admin:
        user: "admin"
        secret: "<your-strong-password>"
  ```
  Or use an env-var reference plus `envFrom` to source from a Secret.

### Added

- New optional `templates/networkpolicy.yaml` gated on `networkPolicy.enabled`
  (default `false` for backwards compatibility). When enabled, restricts
  ingress to the public mail protocol ports plus user-supplied management
  API rules. See `values.yaml` for the schema.

## v0.1.1 and earlier

See git history.
