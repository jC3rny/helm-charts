{{/*
The pod template of the app or the canary. Context: (dict "root" $ "canary" <bool>).
*/}}
{{- define "xapplication.podTemplate" -}}
{{- $ctx := . -}}
{{- $root := .root -}}
{{- $v := $root.Values -}}
{{- $sts := eq $v.kind "StatefulSet" -}}
{{- $volumes := include "xapplication.render" (dict "value" ($v.volumes | default list) "context" $root) | fromYamlArray -}}
metadata:
  labels:
    {{- include "xapplication.podLabels" . | nindent 4 }}
  {{- with $v.podAnnotations }}
  annotations:
    {{- include "xapplication.render" (dict "value" . "context" $root) | nindent 4 }}
  {{- end }}
spec:
  serviceAccountName: {{ include "xapplication.serviceAccountName" $root }}
  automountServiceAccountToken: {{ $v.automountServiceAccountToken }}
  enableServiceLinks: false
  {{- with $v.podSecurityContext }}
  securityContext:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $v.imagePullSecrets }}
  imagePullSecrets:
    {{- include "xapplication.render" (dict "value" . "context" $root) | nindent 4 }}
  {{- end }}
  {{- with $v.initContainers }}
  initContainers:
    {{- include "xapplication.containers" (dict "root" $root "value" .) | nindent 4 }}
  {{- end }}
  containers:
    - name: app
      image: {{ include "xapplication.image" $ctx | quote }}
      imagePullPolicy: {{ $v.image.pullPolicy }}
      {{- with $v.command }}
      command:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with $v.args }}
      args:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      ports:
        - name: http
          containerPort: {{ $v.port }}
          protocol: TCP
        {{- range $v.ports }}
        - name: {{ .name }}
          containerPort: {{ .port }}
          protocol: TCP
        {{- end }}
        {{- with include "xapplication.metricsPort" $root }}
        - name: metrics
          containerPort: {{ . }}
          protocol: TCP
        {{- end }}
      {{- with $v.env }}
      env:
        {{- range include "xapplication.render" (dict "value" . "context" $root) | fromYamlArray }}
        - name: {{ .name }}
          {{- if hasKey . "value" }}
          value: {{ include "xapplication.string" .value | quote }}
          {{- else if hasKey . "valueFrom" }}
          valueFrom:
            {{- toYaml .valueFrom | nindent 12 }}
          {{- else if hasKey . "remoteRef" }}
          valueFrom:
            secretKeyRef:
              name: {{ include "xapplication.child" (list $root "env") }}
              key: {{ .name }}
          {{- else if hasKey . "encryptedData" }}
          valueFrom:
            secretKeyRef:
              name: {{ include "xapplication.child" (list $root "sealed") }}
              key: {{ .name }}
          {{- end }}
        {{- end }}
      {{- end }}
      {{- with $v.envFrom }}
      envFrom:
        {{- include "xapplication.render" (dict "value" . "context" $root) | nindent 8 }}
      {{- end }}
      {{- with $v.resources }}
      resources:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with $v.probes }}
      {{- with .readiness }}
      readinessProbe:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .liveness }}
      livenessProbe:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .startup }}
      startupProbe:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- end }}
      {{- with $v.lifecycle }}
      lifecycle:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with $v.securityContext }}
      securityContext:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      volumeMounts:
        - name: tmp
          mountPath: /tmp
        {{- range $volumes }}
        - name: {{ .name }}
          mountPath: {{ .mountPath }}
          {{- with .subPath }}
          subPath: {{ . }}
          {{- end }}
          {{- if .readOnly }}
          readOnly: true
          {{- end }}
        {{- end }}
    {{- with $v.sidecars }}
    {{- include "xapplication.containers" (dict "root" $root "value" .) | nindent 4 }}
    {{- end }}
  volumes:
    - name: tmp
      emptyDir:
        sizeLimit: {{ $v.tmp.sizeLimit }}
    {{- range $volumes }}
    {{- if include "xapplication.ownClaim" . }}
    {{- if not $sts }}
    - name: {{ .name }}
      persistentVolumeClaim:
        claimName: {{ include "xapplication.child" (list $root .name) }}
    {{- end }}
    {{- else }}
    - name: {{ .name }}
      {{- toYaml (omit . "name" "mountPath" "subPath" "readOnly") | nindent 6 }}
    {{- end }}
    {{- end }}
  {{- with $v.terminationGracePeriodSeconds }}
  terminationGracePeriodSeconds: {{ . }}
  {{- end }}
  {{- with $v.nodeSelector }}
  nodeSelector:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $v.affinity }}
  affinity:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $v.tolerations }}
  tolerations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $v.topologySpread }}
  topologySpreadConstraints:
    {{- range . }}
    {{- $constraint := merge
      (dict "labelSelector" (dict "matchLabels" (include "xapplication.selectorLabels" $ctx | fromYaml)))
      (omit . "labelSelector")
      (dict "maxSkew" 1 "whenUnsatisfiable" "ScheduleAnyway") }}
    - {{- toYaml $constraint | nindent 6 }}
    {{- end }}
  {{- end }}
{{- end -}}
