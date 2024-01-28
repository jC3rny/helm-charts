{{/*
Expand the name of the chart.
*/}}
{{- define "common.name" -}}
  {{- default .Release.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}


{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "common.fullname" -}}
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
Create chart name and version as used by the chart label.
*/}}
{{- define "common.chart" -}}
  {{- printf "%s-%s" (default .Chart.Name (splitList "/" .Chart.Home | last)) .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}


{{/*
Create a default app instance name.
*/}}
{{- define "common.instance" -}}
  {{- if .Values.rewriteLabels.environment }}
    {{- printf "%s-%s" (include "common.fullname" .) .Values.rewriteLabels.environment }}
  {{- else }}
    {{- (include "common.fullname" .) }}
  {{- end }}
{{- end }}


{{/*
Create the name of the service account to use
*/}}
{{- define "common.serviceAccountName" -}}
  {{- if .Values.serviceAccount.create }}
    {{- default (include "common.fullname" .) .Values.serviceAccount.name }}
  {{- else }}
    {{- default "default" .Values.serviceAccount.name }}
  {{- end }}
{{- end }}


{{/*
Create the name of the service
*/}}
{{- define "common.serviceName" -}}
  {{- default (include "common.fullname" .) .Values.service.name }}
{{- end }}


{{/*
Create the name of the job.
*/}}
{{- define "common.job.name" -}}
  {{- default .Release.Name .Values.job.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}