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
Create configmap
*/}}
{{- define "configmap" -}}
{{- $type := typeOf .Values.configmap -}}
{{- if eq $type "[]interface {}" -}}
{{ template "config.file" .Values.configmap }}
{{- else if eq $type "map[string]interface {}" -}}
{{- range $service := .Values.configmap }}
{{ template "config.file" $service }}
{{- end }}
{{- end -}}
{{- end -}}

{{/*
Configmap helper function
*/}}
{{- define "config.file" -}}
{{- range $file := . }}
{{ printf "%s: |+" $file.file_name | indent 2 }}
{{ $file.file_content | indent 4 }}
{{- end }}
{{- end -}}

