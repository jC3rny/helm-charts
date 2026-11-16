{{/*
The objects' name: the release name, or fullnameOverride.
*/}}
{{- define "xapplication.fullname" -}}
{{- default .Release.Name .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
A name derived from the fullname, <fullname>-<suffix>. Fails instead of truncating, so two
derived names never collide. Context: (list $ "<suffix>").
*/}}
{{- define "xapplication.child" -}}
{{- $name := printf "%s-%s" (include "xapplication.fullname" (index . 0)) (index . 1) -}}
{{- if gt (len $name) 63 -}}
{{- fail (printf "xapplication: the name %s is longer than 63 characters; shorten the release name or fullnameOverride" $name) -}}
{{- end -}}
{{- $name -}}
{{- end -}}

{{/*
app.kubernetes.io/name: the release name, or nameOverride.
*/}}
{{- define "xapplication.name" -}}
{{- default .Release.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "xapplication.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
The pods' track. Context: (dict "root" $ "canary" <bool>).
*/}}
{{- define "xapplication.instance" -}}
{{- if .canary -}}{{ printf "%s-canary" .root.Release.Name }}{{- else -}}{{ .root.Release.Name }}{{- end -}}
{{- end -}}

{{/*
Selector labels of the app's or the canary's pods. Context: (dict "root" $ "canary" <bool>).
*/}}
{{- define "xapplication.selectorLabels" -}}
app.kubernetes.io/name: {{ include "xapplication.name" .root }}
app.kubernetes.io/instance: {{ include "xapplication.instance" . }}
{{- end -}}

{{/*
app.kubernetes.io/version: the image tag when it is a valid label value, else nothing.
Context: (dict "root" $ "canary" <bool>).
*/}}
{{- define "xapplication.version" -}}
{{- $image := .canary | ternary .root.Values.canary.image .root.Values.image -}}
{{- $tag := toString ($image.tag | default "") -}}
{{- if regexMatch "^[A-Za-z0-9]([-A-Za-z0-9_.]{0,61}[A-Za-z0-9])?$" $tag -}}{{ $tag }}{{- end -}}
{{- end -}}

{{/*
Labels of every object except the pods (they would roll on every chart release).
*/}}
{{- define "xapplication.labels" -}}
{{- $labels := dict
  "helm.sh/chart" (include "xapplication.chart" .)
  "app.kubernetes.io/name" (include "xapplication.name" .)
  "app.kubernetes.io/instance" .Release.Name
  "app.kubernetes.io/managed-by" .Release.Service -}}
{{- with include "xapplication.version" (dict "root" . "canary" false) -}}
{{- $_ := set $labels "app.kubernetes.io/version" . -}}
{{- end -}}
{{- toYaml (merge $labels (.Values.commonLabels | default dict)) -}}
{{- end -}}

{{/*
Labels of the app's or the canary's pods. Context: (dict "root" $ "canary" <bool>).
*/}}
{{- define "xapplication.podLabels" -}}
{{- $root := .root -}}
{{- $labels := include "xapplication.selectorLabels" . | fromYaml -}}
{{- with include "xapplication.version" . -}}
{{- $_ := set $labels "app.kubernetes.io/version" . -}}
{{- end -}}
{{- $pod := include "xapplication.render" (dict "value" ($root.Values.podLabels | default dict) "context" $root) | fromYaml -}}
{{- toYaml (merge $labels $pod ($root.Values.commonLabels | default dict)) -}}
{{- end -}}

{{/*
A value rendered with tpl: a string as it is, anything else as YAML. Context:
(dict "value" <value> "context" $). The result is YAML text; read it back with fromYaml or
fromYamlArray.
*/}}
{{- define "xapplication.render" -}}
{{- if kindIs "string" .value -}}
{{- tpl .value .context -}}
{{- else -}}
{{- tpl (toYaml .value) .context -}}
{{- end -}}
{{- end -}}

{{/*
A scalar as a string, whole numbers without an exponent (values parse numbers as floats).
*/}}
{{- define "xapplication.string" -}}
{{- if and (kindIs "float64" .) (eq . (. | int64 | float64)) -}}
{{- . | int64 | toString -}}
{{- else -}}
{{- toString . -}}
{{- end -}}
{{- end -}}

{{- define "xapplication.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "xapplication.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{/*
The app's or the canary's image. Context: (dict "root" $ "canary" <bool>).
*/}}
{{- define "xapplication.image" -}}
{{- $repository := .root.Values.image.repository -}}
{{- $image := .canary | ternary .root.Values.canary.image .root.Values.image -}}
{{- if $image.digest -}}
{{- printf "%s@%s" $repository $image.digest -}}
{{- else -}}
{{- printf "%s:%s" $repository $image.tag -}}
{{- end -}}
{{- end -}}

{{/*
The number of the app's container port metrics, which an endpoint of metrics declares by giving
its port as a number (the first such endpoint; the validation refuses a second); else nothing.
*/}}
{{- define "xapplication.metricsPort" -}}
{{- if .Values.metrics.enabled -}}
{{- $numbers := list -}}
{{- range .Values.metrics.endpoints -}}
{{- if not (kindIs "string" .port) -}}
{{- $numbers = append $numbers (int .port) -}}
{{- end -}}
{{- end -}}
{{- with $numbers -}}{{ first . }}{{- end -}}
{{- end -}}
{{- end -}}

{{/*
The port name an endpoint of metrics scrapes: metrics for a number, else the name.
*/}}
{{- define "xapplication.endpointPort" -}}
{{- if kindIs "string" .port -}}{{ .port }}{{- else -}}metrics{{- end -}}
{{- end -}}

{{/*
Every named port of the pod, name to number (JSON): http, ports, a declared metrics port and
the sidecars' ports.
*/}}
{{- define "xapplication.portMap" -}}
{{- $ports := dict "http" (int .Values.port) -}}
{{- range .Values.ports -}}
{{- $_ := set $ports .name (int .port) -}}
{{- end -}}
{{- with include "xapplication.metricsPort" . -}}
{{- $_ := set $ports "metrics" (int .) -}}
{{- end -}}
{{- range include "xapplication.render" (dict "value" (.Values.sidecars | default list) "context" .) | fromYamlArray -}}
{{- range .ports -}}
{{- if .name -}}
{{- $_ := set $ports .name (int .containerPort) -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- toJson $ports -}}
{{- end -}}

{{/*
Init containers or sidecars, rendered, each with the app's securityContext unless it sets its
own. Context: (dict "root" $ "value" <list>).
*/}}
{{- define "xapplication.containers" -}}
{{- $root := .root -}}
{{- $containers := include "xapplication.render" (dict "value" (.value | default list) "context" $root) | fromYamlArray -}}
{{- range $containers -}}
{{- if not (hasKey . "securityContext") -}}
{{- $_ := set . "securityContext" $root.Values.securityContext -}}
{{- end -}}
{{- end -}}
{{- toYaml $containers -}}
{{- end -}}

{{/*
Whether a volume is a claim of the chart's own (persistentVolumeClaim with size).
*/}}
{{- define "xapplication.ownClaim" -}}
{{- if and .persistentVolumeClaim (hasKey .persistentVolumeClaim "size") -}}true{{- end -}}
{{- end -}}

{{/*
Deployment strategy or StatefulSet updateStrategy. Recreate and OnDelete render
rollingUpdate: null, which removes the rollingUpdate Kubernetes filled in for the previous
RollingUpdate (else the API server refuses the switch).
*/}}
{{- define "xapplication.strategy" -}}
{{- $strategy := .Values.strategy | default dict -}}
{{- $type := $strategy.type | default "RollingUpdate" -}}
{{- $rollingUpdate := $strategy.rollingUpdate | default dict -}}
{{- $fields := eq .Values.kind "StatefulSet" | ternary (list "maxUnavailable" "partition") (list "maxSurge" "maxUnavailable") -}}
{{- $picked := dict -}}
{{- range $fields -}}
{{- if hasKey $rollingUpdate . -}}
{{- $_ := set $picked . (index $rollingUpdate .) -}}
{{- end -}}
{{- end -}}
{{ eq .Values.kind "StatefulSet" | ternary "updateStrategy" "strategy" }}:
  type: {{ $type }}
  {{- if ne $type "RollingUpdate" }}
  rollingUpdate: null
  {{- else if $picked }}
  rollingUpdate:
    {{- toYaml $picked | nindent 4 }}
  {{- end }}
{{- end -}}
