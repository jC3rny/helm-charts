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