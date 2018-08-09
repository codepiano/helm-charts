{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "common.project_name" -}}
{{- required ".Values.projectName is required!" .Values.projectName | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "common.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := required ".Values.projectName is required!" .Values.projectName -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "common.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Helm treat full number args as float64, convert to plain string without scientific notation.
Rely on sprig toString function.
*/}}
{{- define "image.tag" -}}
{{- $type := typeOf .Values.image.tag -}}
{{- if eq $type "float64" -}}
{{- printf "%s" (toString .Values.image.tag) -}}
{{- else -}}
{{- printf .Values.image.tag -}}
{{- end -}}
{{- end -}}

{{/*
Create env
*/}}
{{- define "env" }}
{{- if .Values.container.env }}
{{ print "env:" }}
{{- range $key,$value := .Values.container.env }}
{{ printf "- name: %s" (quote $key) | indent 2}}
{{ printf "value: %s" (quote $value) | indent 4 }}
{{- end }}
{{- end -}}
{{- end -}}

{{/*
Create file content as configmap
*/}}
{{- define "configmap.file" -}}
{{- $type := typeOf .Values.configmap -}}
{{- if eq $type "[]interface {}" -}}
{{ template "configmap.entry" .Values.configmap }}
{{- else if eq $type "map[string]interface {}" -}}
{{- range $service := .Values.configmap }}
{{ template "configmap.entry" $service }}
{{- end }}
{{- end -}}
{{- end -}}

{{/*
Configmap helper function, generate entry
*/}}
{{- define "configmap.entry" -}}
{{- range $entry := . }}
{{- range $file := $entry.files }}
{{ printf "%s: |+" $file.file_name }}
{{ $file.file_content | indent 2 }}
{{- end }}
{{- end }}
{{- end -}}

{{/*
Configmap helper function, mount configmap as files
*/}}
{{- define "configmap.mount" -}}
{{- $type := typeOf .Values.configmap -}}
{{- $context := dict "project_name" .Values.projectName -}}
{{- if eq $type "[]interface {}" -}}
{{- $_ := set $context "configmap" .Values.configmap -}}
{{ template "configmap.entry.volume" $context }}
{{- else if eq $type "map[string]interface {}" -}}
{{- range $key, $configs := .Values.configmap }}
{{- $_ := set $context "service" $key -}}
{{- $_ := set $context "configmap" $configs -}}
{{ template "configmap.entry.volume" $context }}
{{- end }}
{{- end -}}
{{- end -}}

{{/*
Configmap helper function, generate volumes info
*/}}
{{- define "configmap.entry.volume" }}
{{- range $volume := .configmap }}
{{ printf "- name: %s-%s" (default "config-files" $.service) (required "entries in .Values.configmap must have volume_name property" .volume_name) }}
{{ printf "%s" "configMap:" | indent 2 }}
{{ printf "name: %s" $.project_name | indent 4 }}
{{ printf "%s" "items:" | indent 4 -}}
{{ include "configmap.entry.file" $volume.files | indent 4 }}
{{- end }}
{{- end -}}

{{/*
Configmap helper function, generate entry info
*/}}
{{- define "configmap.entry.file" }}
{{- range $file := . }}
{{ printf "- key: %s" $file.file_name }}
{{ printf "path: %s" (default $file.file_name $file.file_path) | indent 2 }}
{{- end }}
{{- end -}}

{{/*
Configmap helper function, mount configmap entry to pod
*/}}
{{- define "configmap.volume.mount" }}
{{- $context := dict "containerName"  (default "config-files" .containerName) -}}
{{- $type := typeOf .Values.configmap -}}
{{- if eq $type "[]interface {}" -}}
{{- $_ := set $context "volumes" .Values.configmap -}}
{{ template "configmap.volume.mount.entry" $context }}
{{- else if eq $type "map[string]interface {}" -}}
{{ $volumes := (pluck .containerName .Values.configmap) | first }}
{{- $_ := set $context "volumes" $volumes -}}
{{ template "configmap.volume.mount.entry" $context }}
{{- end }}
{{- end -}}

{{/*
Configmap helper function, generate volume mount entry
*/}}
{{- define "configmap.volume.mount.entry" }}
{{- range $volumeMount := .volumes }}
{{ printf "- name: %s-%s" $.containerName $volumeMount.volume_name }}
{{ printf "mountPath: %s" $volumeMount.mount_path | indent 2 }}
{{- end }}
{{- end -}}
