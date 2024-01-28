{{- define "common.tls.secretName" -}}
  {{- printf "%s-%s" (include "common.fullname" .) "tls" }}
{{- end }}


{{- define "common.envFrom.secretName" -}}
  {{- if .Values.envFrom.useGlobal }}
    {{- printf "%s-%s-%s-%s" .Release.Name "global" "env" "secret" }}
  {{- else }}
    {{- printf "%s-%s-%s" (include "common.fullname" .) "env" "secret" }}
  {{- end }}
{{- end }}


{{- define "common.job.envFrom.secretName" -}}
  {{- if .Values.job.envFrom.useGlobal }}
    {{- printf "%s-%s-%s-%s" .Release.Name "global" "env" "secret" }}
  {{- else }}
    {{- printf "%s-%s-%s-%s" (include "common.job.name" .) "job" "env" "secret" }}
  {{- end }}
{{- end }}


{{- define "common.cronJob.envFrom.secretName" -}}
  {{- if .Values.cronJob.envFrom.useGlobal }}
    {{- printf "%s-%s-%s-%s" .Release.Name "global" "env" "secret" }}
  {{- else }}
    {{- printf "%s-%s-%s-%s" (include "common.cronJob.name" .) "cron" "env" "secret" }}
  {{- end }}
{{- end }}


{{- define "common.pod.envFrom.secretName" -}}
  {{- if .Values.pod.envFrom.useGlobal }}
    {{- printf "%s-%s-%s-%s" .Release.Name "global" "env" "secret" }}
  {{- else }}
    {{- printf "%s-%s-%s-%s" (include "common.pod.name" .) "job" "env" "secret" }}
  {{- end }}
{{- end }}


{{- define "common.envFrom.sealedSecretName" -}}
  {{- if .Values.envFrom.useGlobal }}
    {{- printf "%s-%s-%s-%s" .Release.Name "global" "env" "sealed" }}
  {{- else }}
    {{- printf "%s-%s-%s" (include "common.fullname" .) "env" "sealed" }}
  {{- end }}
{{- end }}


{{- define "common.job.envFrom.sealedSecretName" -}}
  {{- if .Values.job.envFrom.useGlobal }}
    {{- printf "%s-%s-%s-%s" .Release.Name "global" "env" "sealed" }}
  {{- else }}
    {{- printf "%s-%s-%s-%s" (include "common.job.name" .) "job" "env" "sealed" }}
  {{- end }}
{{- end }}


{{- define "common.cronJob.envFrom.sealedSecretName" -}}
  {{- if .Values.cronJob.envFrom.useGlobal }}
    {{- printf "%s-%s-%s-%s" .Release.Name "global" "env" "sealed" }}
  {{- else }}
    {{- printf "%s-%s-%s-%s" (include "common.cronJob.name" .) "cron" "env" "sealed" }}
  {{- end }}
{{- end }}


{{- define "common.pod.envFrom.sealedSecretName" -}}
  {{- if .Values.pod.envFrom.useGlobal }}
    {{- printf "%s-%s-%s-%s" .Release.Name "global" "env" "sealed" }}
  {{- else }}
    {{- printf "%s-%s-%s-%s" (include "common.pod.name" .) "job" "env" "sealed" }}
  {{- end }}
{{- end }}