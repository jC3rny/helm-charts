{{/*
Create release namespace.
*/}}
{{- define "common.namespace" -}}
  {{- if .Values.namespaceOverride -}}
    {{- .Values.namespaceOverride }}
  {{- else }}
    {{- .Release.Namespace }}
  {{- end -}}
{{- end }}