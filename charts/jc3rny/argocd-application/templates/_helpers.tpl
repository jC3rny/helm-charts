{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "app-of-apps.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}


{{/*
Common labels
*/}}
{{- define "app-of-apps.labels" -}}
helm.sh/chart: {{ include "app-of-apps.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}