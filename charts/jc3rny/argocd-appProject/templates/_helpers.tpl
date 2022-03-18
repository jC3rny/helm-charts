{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "app-projects.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}


{{/*
Common labels
*/}}
{{- define "app-projects.labels" -}}
helm.sh/chart: {{ include "app-projects.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}