{{/*
Expand the name of the chart.
*/}}
{{- define "kube-rbac.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "kube-rbac.fullname" -}}
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
{{- define "kube-rbac.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "kube-rbac.labels" -}}
helm.sh/chart: {{ include "kube-rbac.chart" . }}
{{ include "kube-rbac.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "kube-rbac.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kube-rbac.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}


{{/*
Create release namespace.
*/}}
{{- define "kube-rbac.serviceAccount.namespace" -}}
  {{ default .Release.Namespace .Values.serviceAccount.namespaceOverride }}
{{- end }}


{{/*
Create list of all users
*/}}
{{- define "kube-rbac.allUsers" -}}
  {{- $allUsers := list }}
  {{- range $key,$group := .Values.groups }}
    {{- range $user := get $group "users" }}
      {{ $allUsers = append $allUsers $user }}
    {{- end }}
  {{- end }}
  {{- toJson ($allUsers | uniq | sortAlpha) }}
{{- end }}


{{/*
User name
*/}}
{{- define "kube-rbac.username" -}}
{{ (. | regexMatch "@") | ternary ((. | splitn "@" 2)._0 | replace "." "-") . }}
{{- end }}


{{/*
User labels
*/}}
{{- define "kube-rbac.userLabels" -}}
metadata.user/username: {{ include "kube-rbac.username" . }}
metadata.user/email: {{ (. | regexMatch "@") | ternary (. | replace "@" "_at-sign_") ("null" | quote) }}
metadata.user/organization: {{ (. | regexMatch "@") | ternary ((. | splitn "@" 2)._1 | splitn "." 2)._0 ("null" | quote) }}
{{- end }}


{{/*
Role name
*/}}
{{- define "kube-rbac.roleName" -}}
{{ (. | regexMatch ":") | ternary (. | splitn ":" 2)._1 . }}
{{- end }}