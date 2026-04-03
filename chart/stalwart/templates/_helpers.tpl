{{/*
Expand the name of the chart.
*/}}
{{- define "stalwart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "stalwart.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "stalwart.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "stalwart.labels" -}}
helm.sh/chart: {{ include "stalwart.chart" . }}
{{ include "stalwart.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "stalwart.selectorLabels" -}}
app.kubernetes.io/name: {{ include "stalwart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Container image with tag defaulting to appVersion.
*/}}
{{- define "stalwart.image" -}}
{{ .Values.image.repository }}:{{ .Values.image.tag | default (printf "v%s-alpine" .Chart.AppVersion) }}
{{- end }}

{{/*
Convert YAML to TOML format.
Recursively walks a YAML map and emits flat dotted-key TOML.
*/}}
{{- define "stalwart.toToml" -}}
{{- $prefix := "" -}}
{{- if gt (len (index . 1)) 0 -}}
{{- $prefix = index . 1 -}}
{{- end -}}
{{- $config := index . 0 -}}
{{- range $key, $value := $config -}}
{{- $fullKey := $key -}}
{{- if gt (len $prefix) 0 -}}
{{- $fullKey = printf "%s.%s" $prefix $key -}}
{{- end -}}
{{- if kindIs "map" $value }}
{{ include "stalwart.toToml" (list $value $fullKey) }}
{{- else if kindIs "slice" $value }}
{{ $fullKey }} = {{ $value | toJson }}
{{- else if kindIs "string" $value }}
{{ $fullKey }} = {{ $value | quote }}
{{- else if kindIs "bool" $value }}
{{ $fullKey }} = {{ $value }}
{{- else }}
{{ $fullKey }} = {{ $value }}
{{- end -}}
{{- end -}}
{{- end -}}
