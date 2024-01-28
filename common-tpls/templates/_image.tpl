{{/*
Create the name of the container registry secret
*/}}
{{- define "common.containerRegistryName" -}}
  {{- $url := .Values.imagePullSecret.useGlobal | ternary $.Values.global.imagePullSecret.url .Values.imagePullSecret.url }}
  {{- printf "%s-%s" (regexReplaceAll "\\W+" $url "-" | trimSuffix "-") "registry-secret" }}
{{- end }}

{{- define "common.job.containerRegistryName" -}}
  {{- $url := .Values.job.imagePullSecret.useGlobal | ternary $.Values.global.imagePullSecret.url .Values.job.imagePullSecret.url }}
  {{- printf "%s-%s" (regexReplaceAll "\\W+" $url "-" | trimSuffix "-") "registry-secret" }}
{{- end }}


{{/*
Create the name of the container image
*/}}
{{- define "common.containerImage" -}}
  {{- $url := .Values.image.useGlobal | ternary $.Values.global.imagePullSecret.url .Values.imagePullSecret.url }}
  {{- $repository := .Values.image.useGlobal | ternary $.Values.global.image.repository .Values.image.repository }}
  {{- $tag := .Values.image.useGlobal | ternary $.Values.global.image.tag .Values.image.tag }}
  {{- printf "%s/%s" (default "" $url) $repository | trimPrefix "/" | trimSuffix "/" }}:{{ default .Chart.AppVersion $tag }}
{{- end }}

{{- define "common.job.containerImage" -}}
  {{- $url := .Values.job.image.useGlobal | ternary $.Values.global.imagePullSecret.url .Values.job.imagePullSecret.url }}
  {{- $repository := .Values.job.image.useGlobal | ternary $.Values.global.image.repository .Values.job.image.repository }}
  {{- $tag := .Values.job.image.useGlobal | ternary $.Values.global.image.tag .Values.job.image.tag }}
  {{- printf "%s/%s" (default "" $url) $repository | trimPrefix "/" | trimSuffix "/" }}:{{ default .Chart.AppVersion $tag }}
{{- end }}


{{/*
Set up default pull policy of the container image
*/}}
{{- define "common.containerImagePullPolicy" -}}
  {{- .Values.image.useGlobal | ternary $.Values.global.image.pullPolicy .Values.image.pullPolicy }}
{{- end }}

{{- define "common.job.containerImagePullPolicy" -}}
  {{- .Values.job.image.useGlobal | ternary $.Values.global.image.pullPolicy .Values.job.image.pullPolicy }}
{{- end }}