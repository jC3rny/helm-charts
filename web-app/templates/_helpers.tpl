{{/*
Expand the name of the chart.
*/}}
{{- define "web-app.name" -}}
{{- default .Release.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}


{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "web-app.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Release.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}


{{/*
Create a default app instance name.
*/}}
{{- define "web-app.instance" -}}
{{- if .Values.rewriteLabels.environment }}
{{- printf "%s-%s" (include "web-app.fullname" .) .Values.rewriteLabels.environment }}
{{- else }}
{{- (include "web-app.fullname" .) }}
{{- end }}
{{- end }}


{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "web-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}


{{/*
Common labels
*/}}
{{- define "web-app.labels" -}}
helm.sh/chart: {{ include "web-app.chart" . }}
{{- if .Values.customLabels }}
{{ include "web-app.customLabels" . }}
{{- else }}
{{ include "web-app.selectorLabels" . }}
app.kubernetes.io/component: {{ default .Chart.Name (include "web-app.name" .) .Values.rewriteLabels.component }}
{{- if or (.Chart.AppVersion) (.Values.image.tag) }}
app.kubernetes.io/version: {{ default .Chart.AppVersion .Values.image.tag | quote }}
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
{{- define "web-app.selectorLabels" -}}
{{- if .Values.customLabels -}}
{{ include "web-app.customLabels" . }}
{{- else -}}
app.kubernetes.io/name: {{ .Release.Name }}
app.kubernetes.io/instance: {{ default (include "web-app.instance" .) .Values.rewriteLabels.instance }}
{{- end }}
{{- end }}


{{/*
Custom labels
*/}}
{{- define "web-app.customLabels" -}}
{{- if .Values.customLabels }}
{{- toYaml .Values.customLabels }}
{{- end }}
{{- end }}


{{/*
Create the name of the configMap
*/}}
{{- define "web-app.envFrom.configMapName" -}}
{{- if .Values.envFrom.configMap }}
{{- printf "%s-%s" (include "web-app.fullname" .) "env" | trimSuffix "-" }}-config
{{- end }}
{{- end }}


{{/*
Create the name of the common secrets
*/}}
{{- define "web-app.containerRegistryName" -}}
{{- if .Values.imagePullSecrets }}
{{- printf "%s-%s" (regexReplaceAll "\\W+" .Values.imagePullSecrets.url "-" | trimSuffix "-") "registry-secret" }}
{{- end }}
{{- end }}

{{- define "web-app.envFrom.secretName" -}}
{{- if .Values.envFrom.secret }}
{{- printf "%s-%s" (include "web-app.fullname" .) "env" | trimSuffix "-" }}-secret
{{- end }}
{{- end }}

{{- define "web-app.envFrom.sealedSecretName" -}}
{{- if .Values.envFrom.sealedSecret }}
{{- printf "%s-%s" (include "web-app.fullname" .) "env" | trimSuffix "-" }}-sealed
{{- end }}
{{- end }}


{{/*
Create the name of the service account to use
*/}}
{{- define "web-app.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "web-app.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
