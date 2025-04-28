{{/*
Expand the name of the chart.
*/}}
{{- define "gfdsh.name" -}}
{{- printf "%s-%s" (default .Chart.Name .Values.nameOverride) (replace "_" "-" .Env.name) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create release namespace.
*/}}
{{- define "gfdsh.namespace" -}}
  {{ default .Release.Namespace .Values.namespaceOverride }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "gfdsh.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "gfdsh.labels" -}}
helm.sh/chart: {{ include "gfdsh.chart" . }}
{{ include "gfdsh.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "gfdsh.selectorLabels" -}}
app.kubernetes.io/name: {{ include "gfdsh.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
