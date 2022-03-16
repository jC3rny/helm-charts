{{/*
Common labels
*/}}
{{- define "common.labels" -}}
helm.sh/chart: {{ include "common.chart" . }}
{{ include "common.selectorLabels" . }}
{{- if .Values.customLabels }}
{{- with .Values.customLabels.others }}
{{ toYaml . }}
{{- end }}
{{- else }}
{{- $component := default .Chart.Name (splitList "/" .Chart.Home | last) }}
{{- if or (not (contains $component .Chart.Name)) .Values.rewriteLabels.component }}
app.kubernetes.io/component: {{ default .Chart.Name .Values.rewriteLabels.component }}
{{- end }}
{{- if or .Chart.AppVersion .Values.image }}
app.kubernetes.io/version: {{ default .Chart.AppVersion (.Values.image.useGlobal | ternary .Values.global.image.tag .Values.image.tag) | quote }}
{{- end }}
{{- if .Values.rewriteLabels.environment }}
app.kubernetes.io/environment: {{ .Values.rewriteLabels.environment }}
{{- end }}
{{- if .Values.rewriteLabels.partOf }}
app.kubernetes.io/part-of: {{ .Values.rewriteLabels.partOf }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}
{{- end }}


{{/*
Selector labels
*/}}
{{- define "common.selectorLabels" -}}
{{- if .Values.customLabels -}}
{{- toYaml .Values.customLabels.selector }}
{{- else -}}
app.kubernetes.io/name: {{ .Release.Name }}
app.kubernetes.io/instance: {{ default (include "common.instance" .) .Values.rewriteLabels.instance }}
{{- end }}
{{- end }}