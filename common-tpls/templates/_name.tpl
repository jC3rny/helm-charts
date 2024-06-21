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
  {{- else -}}
    {{- $name := default .Release.Name .Values.nameOverride }}
    {{- if contains $name .Release.Name }}
      {{- .Release.Name | trunc 63 | trimSuffix "-" }}
    {{- else -}}
      {{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
    {{- end }}
  {{- end }}
{{- end }}

{{/*
Create the name of the deployment.
*/}}
{{- define "common.deployment.name" -}}
  {{- hasKey .Values.deploymentStrategy.canary "nameSuffix" | ternary (printf "%s-%s" (include "common.fullname" .) "canary") (include "common.fullname" .) }}
{{- end }}

{{/*
Create the name of the job.
*/}}
{{- define "common.job.name" -}}
  {{- default (printf "%s-%s" (include "common.fullname" .) .Values.job.nameOverride) .Values.job.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create the name of the cronJob.
*/}}
{{- define "common.cronJob.name" -}}
  {{- default (printf "%s-%s" (include "common.fullname" .) .Values.cronJob.nameOverride) .Values.cronJob.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create the name of the standalone pod.
*/}}
{{- define "common.pod.name" -}}
  {{- default (printf "%s-%s" (include "common.fullname" .) .Values.pod.nameOverride) .Values.pod.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}


{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "common.chart" -}}
  {{- printf "%s-%s" (default .Chart.Name (splitList "/" .Chart.Home | last)) .Chart.Version }}
{{- end }}


{{/*
Create a default app instance name.
*/}}
{{- define "common.instance" -}}
  {{- if hasKey .Values "rewriteLabels" }}
    {{- empty .Values.rewriteLabels.environment | ternary (include "common.deployment.name" .) (printf "%s-%s" (include "common.deployment.name" .) .Values.rewriteLabels.environment) }}
  {{- else -}}
    {{- include "common.deployment.name" . }}
  {{- end }}
{{- end }}


{{/*
Create the name of the main container
*/}}
{{- define "common.containerName" -}}
  {{- empty .Values.containerName | ternary (default .Chart.Name .Values.rewriteLabels.component) .Values.containerName }}
{{- end }}


{{/*
Create the name of the service
*/}}
{{- define "common.serviceName" -}}
  {{- default (include "common.deployment.name" .) .Values.service.name }}
{{- end }}


{{/*
Create the name of the service account to use
*/}}
{{- define "common.serviceAccountName" -}}
  {{- if .Values.serviceAccount.create }}
    {{- default (include "common.fullname" .) .Values.serviceAccount.name }}
  {{- else -}}
    {{- default "default" .Values.serviceAccount.name }}
  {{- end }}
{{- end }}

{{- define "common.job.serviceAccountName" -}}
  {{- if .Values.job.serviceAccount.create }}
    {{- default (include "common.job.name" .) .Values.job.serviceAccount.name }}
  {{- else -}}
    {{- default "default" .Values.job.serviceAccount.name }}
  {{- end }}
{{- end }}

{{- define "common.cronJob.serviceAccountName" -}}
  {{- if .Values.cronJob.serviceAccount.create }}
    {{- default (include "common.cronJob.name" .) .Values.cronJob.serviceAccount.name }}
  {{- else -}}
    {{- default "default" .Values.cronJob.serviceAccount.name }}
  {{- end }}
{{- end }}

{{- define "common.pod.serviceAccountName" -}}
  {{- if .Values.pod.serviceAccount.create }}
    {{- default (include "common.pod.name" .) .Values.pod.serviceAccount.name }}
  {{- else -}}
    {{- default "default" .Values.pod.serviceAccount.name }}
  {{- end }}
{{- end }}
