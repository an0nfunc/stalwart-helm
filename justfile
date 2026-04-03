default:
    @just --list

# Lint the Helm chart
lint:
    helm lint chart/stalwart

# Template the chart with default values
template:
    helm template stalwart chart/stalwart

# Template with an example values file
template-example file="examples/minimal.yaml":
    helm template stalwart chart/stalwart -f {{ file }}

# Validate rendered templates with kubeconform
test:
    helm template stalwart chart/stalwart | kubeconform -strict -ignore-missing-schemas
    @for f in examples/*.yaml; do \
        echo "--- Validating with $$f ---"; \
        helm template stalwart chart/stalwart -f "$$f" | kubeconform -strict -ignore-missing-schemas; \
    done

# Package the chart
package:
    helm package chart/stalwart
