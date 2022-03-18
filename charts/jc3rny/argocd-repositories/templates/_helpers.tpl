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