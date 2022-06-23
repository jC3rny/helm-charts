{{/*
Create the name of the repository secret
*/}}
{{- define "argocd.repo.secretName" -}}
  {{- if and (not (hasKey . "name")) (hasKey . "url") }}
    {{- printf  "argocd-repository-%s" (regexReplaceAll "\\W+" (split "//" .url)._1 "-" | trimSuffix "-" | trimSuffix "-git" | lower ) }}
  {{- else }}
    {{- required "key .name is missing" .name }}
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
{{- define "argocd.repo-creds.secretName" -}}
  {{- if and (not (hasKey . "name")) (hasKey . "url") }}
    {{- printf "argocd-repo-creds-%s" (regexReplaceAll "\\W+" (split "//" .url)._1 "-" | trimSuffix "-" | trimSuffix "-git" | lower ) }}
  {{- else }}
    {{- required "key .name is missing" .name }}
  {{- end }}
{{- end }}

{{/*
Credential labels
*/}}
{{- define "argocd.repo-creds.labels" -}}
argocd.argoproj.io/secret-type: repo-creds
{{- end }}