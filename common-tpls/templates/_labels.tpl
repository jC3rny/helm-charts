{{/*
Common labels
*/}}
{{- define "common.labels" -}}
{{ include "common.markerLabels" . }}
{{ include "common.appLabels" . }}
{{- end }}


{{/*
Marker labels
*/}}
{{- define "common.markerLabels" -}}
helm.sh/chart: {{ include "common.chart" . }}
{{ include "common.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}


{{/*
Selector labels
*/}}
{{- define "common.selectorLabels" -}}
{{- if hasKey .Values.customLabels "selector" -}}
{{- toYaml .Values.customLabels.selector }}
{{- else -}}
app.kubernetes.io/name: {{ .Release.Name }}
{{- if hasKey .Values "rewriteLabels" }}
app.kubernetes.io/instance: {{ empty .Values.rewriteLabels.instance | ternary (include "common.instance" .) .Values.rewriteLabels.instance }}
{{- else }}
app.kubernetes.io/instance: {{ include "common.instance" . }}
{{- end }}
{{- end }}
{{- end }}


{{/*
App labels
*/}}
{{- define "common.appLabels" -}}
{{- if hasKey .Values.customLabels "others" }}
{{- toYaml .Values.customLabels.others }}
{{- else -}}
{{- $component := default .Chart.Name (splitList "/" .Chart.Home | last) -}}
{{- if hasKey .Values "rewriteLabels" -}}
app.kubernetes.io/component: {{ empty .Values.rewriteLabels.component | ternary .Chart.Name .Values.rewriteLabels.component }}
{{- if not (empty .Values.rewriteLabels.environment) }}
app.kubernetes.io/environment: {{ .Values.rewriteLabels.environment }}
{{- end }}
{{- if not (empty .Values.rewriteLabels.partOf) }}
app.kubernetes.io/part-of: {{ .Values.rewriteLabels.partOf }}
{{- end }}
{{- else -}}
app.kubernetes.io/component: {{ not (contains $component .Chart.Name) | ternary .Chart.Name $component }}
{{- end }}
{{- if or .Chart.AppVersion (hasKey .Values "image") }}
{{- if hasKey .Values "image" }}
app.kubernetes.io/version: {{ .Values.image.useGlobal | ternary .Values.global.image.tag .Values.image.tag | quote }}
{{- else }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
{{- end }}
{{- range $key, $value := .Values.additionalLabels }}
{{ $key }}: {{ ($value | regexMatch "@") | ternary ($value | replace "@" "_at-sign_") $value }}
{{- end }}
{{- end }}
{{- end }}