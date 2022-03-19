{{/*
Common labels
*/}}
{{- define "common.labels" -}}
{{ include "common.basicLabels" . }}
{{- if .Values.customLabels }}
{{- with .Values.customLabels.others }}
{{ toYaml . }}
{{- end }}
{{- else }}
{{- $component := default .Chart.Name (splitList "/" .Chart.Home | last) }}
{{- if or (not (contains $component .Chart.Name)) (hasKey .Values "rewriteLabels") }}
{{- if hasKey .Values.rewriteLabels "component" }}
app.kubernetes.io/component: {{ .Values.rewriteLabels.component }}
{{- else }}
app.kubernetes.io/component: {{ .Chart.Name }}
{{- end }}
{{- end }}
{{- if or .Chart.AppVersion (hasKey .Values "image") }}
{{- if (hasKey .Values "image") }}
app.kubernetes.io/version: {{ hasKey .Values.image "useGlobal" | ternary .Values.global.image.tag .Values.image.tag | quote }}
{{- else }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
{{- end }}
{{- if hasKey .Values "rewriteLabels" }}
{{- if .Values.rewriteLabels.environment }}
app.kubernetes.io/environment: {{ .Values.rewriteLabels.environment }}
{{- end }}
{{- end }}
{{- if hasKey .Values "rewriteLabels" }}
{{- if .Values.rewriteLabels.partOf }}
app.kubernetes.io/part-of: {{ .Values.rewriteLabels.partOf }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}


{{/*
Basic labels
*/}}
{{- define "common.basicLabels" -}}
helm.sh/chart: {{ include "common.chart" . }}
{{ include "common.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}


{{/*
Selector labels
*/}}
{{- define "common.selectorLabels" -}}
{{- if .Values.customLabels -}}
{{- toYaml .Values.customLabels.selector }}
{{- else -}}
app.kubernetes.io/name: {{ .Release.Name }}
{{- if hasKey .Values "rewriteLabels" }}
{{- if .Values.rewriteLabels.instance }}
app.kubernetes.io/instance: {{ .Values.rewriteLabels.instance }}
{{- end }}
{{- else }}
app.kubernetes.io/instance: {{ (include "common.instance" .) }}
{{- end }}
{{- end }}
{{- end }}