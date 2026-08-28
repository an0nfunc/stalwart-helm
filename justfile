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

# Assert the rendered config.json is valid JSON carrying a DataStore.
# A tagged-union typo renders fine and produces a pod that cannot start.
check-config:
    #!/usr/bin/env bash
    set -euo pipefail
    helm template stalwart chart/stalwart | python3 -c '
    import sys, json, yaml
    for d in yaml.safe_load_all(sys.stdin):
        if d and d.get("kind") == "ConfigMap" and "config.json" in d.get("data", {}):
            cfg = json.loads(d["data"]["config.json"])
            assert "@type" in cfg, "config.json has no @type discriminator"
            print("config.json OK:", cfg["@type"])
            break
    else:
        raise SystemExit("no config.json ConfigMap rendered")
    '

# Assert the metrics Service keeps its name. Alerting and dashboards key on the
# derived job label, so a rename detaches monitoring silently.
check-metrics-name:
    helm template stalwart chart/stalwart --set metrics.enabled=true | grep -q "name: stalwart-metrics"
    @echo "metrics Service name OK"

# Validate rendered templates with kubeconform
test: check-config check-metrics-name
    helm template stalwart chart/stalwart | kubeconform -strict -ignore-missing-schemas
    @for f in examples/*.yaml; do \
        echo "--- Validating with $f ---"; \
        helm template stalwart chart/stalwart -f "$f" | kubeconform -strict -ignore-missing-schemas; \
    done

# Package the chart
package:
    helm package chart/stalwart
