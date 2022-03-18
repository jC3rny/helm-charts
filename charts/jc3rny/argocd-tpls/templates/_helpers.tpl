{{/*
Expand the name of the chart.
*/}}
{{- define "argocd.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "argocd.fullname" -}}
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
Common labels
*/}}
{{- define "app-of-apps.labels" -}}
helm.sh/chart: {{ include "argocd.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}





{{/*
Create the name of the repository secret
*/}}
{{- define "argocd.repo.secretName" -}}
  {{- if .url }}
      {{- printf "%s-%s" (regexReplaceAll "\\W+" (split "//" .url)._1 "-" | trimSuffix "-") "repo" }}
  {{- end }}
{{- end }}


{{/*
Repository labels
*/}}
{{- define "argocd.repo.labels" -}}
argocd.argoproj.io/secret-type: repository
{{- end }}


{{/*
Create the name of the credential secret
*/}}
{{- define "argocd.creds.secretName" -}}
  {{- if .url }}
      {{- printf "%s-%s" (regexReplaceAll "\\W+" (split "//" .url)._1 "-" | trimSuffix "-") "creds" }}
  {{- end }}
{{- end }}


{{/*
Credential labels
*/}}
{{- define "argocd.creds.labels" -}}
argocd.argoproj.io/secret-type: repo-creds
{{- end }}










{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "argocd.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}


{{/*
Common labels
*/}}
{{- define "argocd.labels" -}}
helm.sh/chart: {{ include "argocd.chart" . }}
{{ include "argocd.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}


{{/*
Selector labels
*/}}
{{- define "argocd.selectorLabels" -}}
app.kubernetes.io/name: {{ include "argocd.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
