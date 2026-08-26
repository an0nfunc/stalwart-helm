# Changelog

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
