{{/*
Checks across values that values.schema.json cannot express. Every failure names the value.
*/}}
{{- define "xapplication.validate" -}}
{{- $v := .Values -}}
{{- $sts := eq $v.kind "StatefulSet" -}}

{{- /* image */ -}}
{{- if not $v.image.repository -}}
{{- fail "xapplication: image.repository is required" -}}
{{- end -}}
{{- if not (or $v.image.tag $v.image.digest) -}}
{{- fail "xapplication: image.tag or image.digest is required" -}}
{{- end -}}

{{- /* strategy */ -}}
{{- $strategy := ($v.strategy | default dict).type | default "RollingUpdate" -}}
{{- $strategies := $sts | ternary (list "RollingUpdate" "OnDelete") (list "RollingUpdate" "Recreate") -}}
{{- if not (has $strategy $strategies) -}}
{{- fail (printf "xapplication: strategy.type %s is not one of %s for kind %s" $strategy (join ", " $strategies) $v.kind) -}}
{{- end -}}

{{- /* ports: names and numbers unique across the pod */ -}}
{{- $portNames := list "http" -}}
{{- $portNumbers := list (int $v.port) -}}
{{- $metricsPort := include "xapplication.metricsPort" . -}}
{{- $metricsDeclared := ne $metricsPort "" -}}
{{- $declared := list -}}
{{- range $v.ports -}}
{{- $declared = append $declared (dict "name" .name "port" .port "where" "ports") -}}
{{- end -}}
{{- if $metricsDeclared -}}
{{- $declared = append $declared (dict "name" "metrics" "port" $metricsPort "where" "metrics.endpoints") -}}
{{- end -}}
{{- range $sidecar := include "xapplication.render" (dict "value" ($v.sidecars | default list) "context" .) | fromYamlArray -}}
{{- range $sidecar.ports -}}
{{- $declared = append $declared (dict "name" (.name | default "") "port" .containerPort "where" (printf "sidecar %s" $sidecar.name)) -}}
{{- end -}}
{{- end -}}
{{- range $declared -}}
{{- if .name -}}
{{- if has .name $portNames -}}
{{- fail (printf "xapplication: the port name %s (%s) is used twice in the pod (http is the app's port%s)" .name .where ($metricsDeclared | ternary ", metrics the declared metrics port" "")) -}}
{{- end -}}
{{- $portNames = append $portNames .name -}}
{{- end -}}
{{- if has (int .port) $portNumbers -}}
{{- fail (printf "xapplication: the port number %d (%s) is used twice in the pod" (int .port) .where) -}}
{{- end -}}
{{- $portNumbers = append $portNumbers (int .port) -}}
{{- end -}}

{{- /* env: unique names, exactly one source */ -}}
{{- $envNames := list -}}
{{- range $e := $v.env -}}
{{- if has $e.name $envNames -}}
{{- fail (printf "xapplication: env %s is set twice" $e.name) -}}
{{- end -}}
{{- $envNames = append $envNames $e.name -}}
{{- $sources := 0 -}}
{{- range list "value" "valueFrom" "remoteRef" "encryptedData" -}}
{{- if hasKey $e . -}}{{- $sources = add1 $sources -}}{{- end -}}
{{- end -}}
{{- if ne (int $sources) 1 -}}
{{- fail (printf "xapplication: env %s needs exactly one of value, valueFrom, remoteRef, encryptedData" $e.name) -}}
{{- end -}}
{{- if and (hasKey $e "remoteRef") (not $v.externalSecrets.secretStoreRef.name) -}}
{{- fail (printf "xapplication: env %s has remoteRef, so externalSecrets.secretStoreRef.name is required" $e.name) -}}
{{- end -}}
{{- end -}}

{{- /* volumes: unique names and mount paths, one source, claims */ -}}
{{- $volumeNames := list "tmp" -}}
{{- $mountPaths := list "/tmp" -}}
{{- range $vol := $v.volumes -}}
{{- if has $vol.name $volumeNames -}}
{{- fail (printf "xapplication: the volume name %s is used twice (tmp is reserved)" $vol.name) -}}
{{- end -}}
{{- $volumeNames = append $volumeNames $vol.name -}}
{{- if has $vol.mountPath $mountPaths -}}
{{- fail (printf "xapplication: volume %s mounts %s, which another volume (or /tmp) already uses" $vol.name $vol.mountPath) -}}
{{- end -}}
{{- $mountPaths = append $mountPaths $vol.mountPath -}}
{{- $sources := keys (omit $vol "name" "mountPath" "subPath" "readOnly") -}}
{{- if ne (len $sources) 1 -}}
{{- fail (printf "xapplication: volume %s needs exactly one source, has %d (%s)" $vol.name (len $sources) (join ", " (sortAlpha $sources))) -}}
{{- end -}}
{{- with $vol.persistentVolumeClaim -}}
{{- if eq (hasKey . "size") (hasKey . "claimName") -}}
{{- fail (printf "xapplication: volume %s: persistentVolumeClaim needs exactly one of size, claimName" $vol.name) -}}
{{- end -}}
{{- if and (hasKey . "size") (not $sts) (eq (.accessMode | default "ReadWriteOnce") "ReadWriteOnce") -}}
{{- if or (gt (int $v.replicaCount) 1) $v.autoscaling.enabled (ne $strategy "Recreate") $v.canary.enabled -}}
{{- fail (printf "xapplication: volume %s is a ReadWriteOnce claim, which attaches to one node: the Deployment needs replicaCount 1, no autoscaling, strategy Recreate and no canary (or kind StatefulSet, or accessMode ReadWriteMany)" $vol.name) -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- /* httpRoute */ -}}
{{- if and $v.httpRoute.enabled (not $v.httpRoute.parentRefs) -}}
{{- fail "xapplication: httpRoute.parentRefs is required when httpRoute is enabled" -}}
{{- end -}}

{{- /* canary */ -}}
{{- if $v.canary.enabled -}}
{{- if $sts -}}
{{- fail "xapplication: canary needs kind Deployment" -}}
{{- end -}}
{{- if not $v.httpRoute.enabled -}}
{{- fail "xapplication: canary needs httpRoute, which splits the traffic" -}}
{{- end -}}
{{- if not (or $v.canary.image.tag $v.canary.image.digest) -}}
{{- fail "xapplication: canary.image.tag or canary.image.digest is required" -}}
{{- end -}}
{{- with $v.canary.header -}}
{{- if and .name (not (hasKey . "value")) -}}
{{- fail "xapplication: canary.header needs a value with its name" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- /* extraServices: unique names, reserved names, ports that exist */ -}}
{{- $reserved := list -}}
{{- if $v.canary.enabled -}}{{- $reserved = append $reserved "canary" -}}{{- end -}}
{{- if and $v.metrics.enabled (eq $v.metrics.type "ServiceMonitor") -}}{{- $reserved = append $reserved "metrics" -}}{{- end -}}
{{- if $sts -}}{{- $reserved = append $reserved "headless" -}}{{- end -}}
{{- $serviceNames := list -}}
{{- range $v.extraServices -}}
{{- if has .name $reserved -}}
{{- fail (printf "xapplication: extraServices %s: the chart renders that Service itself here" .name) -}}
{{- end -}}
{{- if has .name $serviceNames -}}
{{- fail (printf "xapplication: extraServices %s is set twice" .name) -}}
{{- end -}}
{{- $serviceNames = append $serviceNames .name -}}
{{- if and (eq (toString .clusterIP) "None") (ne (.type | default "ClusterIP") "ClusterIP") -}}
{{- fail (printf "xapplication: extraServices %s: clusterIP None needs type ClusterIP" .name) -}}
{{- end -}}
{{- $service := .name -}}
{{- range .ports -}}
{{- if not (has . $portNames) -}}
{{- fail (printf "xapplication: extraServices %s: no container declares the port %s (declared: %s)" $service . (join ", " $portNames)) -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- /* metrics: one declared port at most, named ports exist, no endpoint twice */ -}}
{{- if $v.metrics.enabled -}}
{{- $numbers := 0 -}}
{{- range $v.metrics.endpoints -}}
{{- if not (kindIs "string" .port) -}}{{- $numbers = add1 $numbers -}}{{- end -}}
{{- end -}}
{{- if gt (int $numbers) 1 -}}
{{- fail "xapplication: metrics.endpoints: at most one endpoint gives its port as a number (it declares the port metrics); declare others in ports and name them" -}}
{{- end -}}
{{- $endpoints := list -}}
{{- range $v.metrics.endpoints -}}
{{- if and (kindIs "string" .port) (not (has .port $portNames)) -}}
{{- fail (printf "xapplication: metrics.endpoints: no container declares the port %s (declared: %s)" .port (join ", " $portNames)) -}}
{{- end -}}
{{- $endpoint := printf "%s%s" (include "xapplication.endpointPort" .) (.path | default "/metrics") -}}
{{- if has $endpoint $endpoints -}}
{{- fail (printf "xapplication: metrics.endpoints: port %s with path %s is listed twice" (include "xapplication.endpointPort" .) (.path | default "/metrics")) -}}
{{- end -}}
{{- $endpoints = append $endpoints $endpoint -}}
{{- end -}}
{{- end -}}
{{- end -}}
