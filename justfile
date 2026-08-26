default:
    @just --list

# Obviously-fake secret so the chart renders locally. The chart refuses to
# render without one (see chart/stalwart/values.yaml). Mirrors CI.
render_secret := "ci-test-pw-not-for-prod"

# Lint the Helm chart
lint:
    helm lint chart/stalwart

# Template the chart with default values
template:
    helm template stalwart chart/stalwart --set config.authentication.fallback-admin.secret={{ render_secret }}

# Template with an example values file
template-example file="examples/minimal.yaml":
    helm template stalwart chart/stalwart -f {{ file }}

# Validate rendered templates with kubeconform
test:
    helm template stalwart chart/stalwart --set config.authentication.fallback-admin.secret={{ render_secret }} | kubeconform -strict -ignore-missing-schemas
    @for f in examples/*.yaml; do \
        echo "--- Validating with $f ---"; \
        helm template stalwart chart/stalwart -f "$f" | kubeconform -strict -ignore-missing-schemas; \
    done

# Package the chart
package:
    helm package chart/stalwart
