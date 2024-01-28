{{/*
Create the name of the configMap
*/}}
{{- define "common.envFrom.configMapName" -}}
  {{- if .Values.envFrom.useGlobal }}
      {{- printf "%s-%s-%s-%s" .Release.Name "global" "env" "cm" }}
  {{- else }}
    {{- printf "%s-%s-%s" (include "common.fullname" .) "env" "cm" }}
  {{- end }}
{{- end }}


{{/*
Create the name of the job configMap
*/}}
{{- define "common.job.envFrom.configMapName" -}}
  {{- if .Values.job.envFrom.useGlobal }}
      {{- printf "%s-%s-%s-%s" .Release.Name "global" "env" "cm" }}
  {{- else }}
    {{- printf "%s-%s-%s-%s" (include "common.job.name" .) "job" "env" "cm" }}
  {{- end }}
{{- end }}


{{/*
Create the name of the cronJob configMap
*/}}
{{- define "common.cronJob.envFrom.configMapName" -}}
  {{- if .Values.cronJob.envFrom.useGlobal }}
      {{- printf "%s-%s-%s-%s" .Release.Name "global" "env" "cm" }}
  {{- else }}
    {{- printf "%s-%s-%s-%s" (include "common.cronJob.name" .) "cron" "env" "cm" }}
  {{- end }}
{{- end }}


{{/*
Create the name of the pod configMap
*/}}
{{- define "common.pod.envFrom.configMapName" -}}
  {{- if .Values.pod.envFrom.useGlobal }}
      {{- printf "%s-%s-%s-%s" .Release.Name "global" "env" "cm" }}
  {{- else }}
    {{- printf "%s-%s-%s-%s" (include "common.pod.name" .) "job" "env" "cm" }}
  {{- end }}
{{- end }}