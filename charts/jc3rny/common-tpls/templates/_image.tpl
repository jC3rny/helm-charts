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

{{- define "common.cronJob.containerRegistryName" -}}
  {{- $url := .Values.cronJob.imagePullSecret.useGlobal | ternary $.Values.global.imagePullSecret.url .Values.cronJob.imagePullSecret.url }}
  {{- printf "%s-%s" (regexReplaceAll "\\W+" $url "-" | trimSuffix "-") "registry-secret" }}
{{- end }}

{{- define "common.pod.containerRegistryName" -}}
  {{- $url := .Values.pod.imagePullSecret.useGlobal | ternary $.Values.global.imagePullSecret.url .Values.pod.imagePullSecret.url }}
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

{{- define "common.cronJob.containerImage" -}}
  {{- $url := .Values.cronJob.image.useGlobal | ternary $.Values.global.imagePullSecret.url .Values.cronJob.imagePullSecret.url }}
  {{- $repository := .Values.cronJob.image.useGlobal | ternary $.Values.global.image.repository .Values.cronJob.image.repository }}
  {{- $tag := .Values.cronJob.image.useGlobal | ternary $.Values.global.image.tag .Values.cronJob.image.tag }}
  {{- printf "%s/%s" (default "" $url) $repository | trimPrefix "/" | trimSuffix "/" }}:{{ default .Chart.AppVersion $tag }}
{{- end }}

{{- define "common.pod.containerImage" -}}
  {{- $url := .Values.pod.image.useGlobal | ternary $.Values.global.imagePullSecret.url .Values.pod.imagePullSecret.url }}
  {{- $repository := .Values.pod.image.useGlobal | ternary $.Values.global.image.repository .Values.pod.image.repository }}
  {{- $tag := .Values.pod.image.useGlobal | ternary $.Values.global.image.tag .Values.pod.image.tag }}
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

{{- define "common.cronJob.containerImagePullPolicy" -}}
  {{- .Values.cronJob.image.useGlobal | ternary $.Values.global.image.pullPolicy .Values.cronJob.image.pullPolicy }}
{{- end }}

{{- define "common.pod.containerImagePullPolicy" -}}
  {{- .Values.pod.image.useGlobal | ternary $.Values.global.image.pullPolicy .Values.pod.image.pullPolicy }}
{{- end }}