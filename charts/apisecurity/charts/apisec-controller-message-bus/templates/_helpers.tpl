{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "apisec-controller-message-bus.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" | trimSuffix "." -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "apisec-controller-message-bus.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" | trimSuffix "." -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" | trimSuffix "." -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" | trimSuffix "." -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "apisec-controller-message-bus.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" | trimSuffix "." -}}
{{- end -}}

{{- define "apisec-controller-message-bus.version" -}}
{{- printf "%s" .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" | trimSuffix "." -}}
{{- end -}}

{{- define "apisec-controller-message-bus.imagetag" -}}
{{- default .Chart.Version .Values.image.tag | replace "+" "-" | trunc 63 | trimSuffix "-" | trimSuffix "." -}}
{{- end -}}

{{- define "apisec-controller-message-bus.imageregistry" -}}
  {{- if hasKey .Values "global" -}}
    {{ .Values.global.imageregistry }}/{{ .Values.global.imagerepository }}
  {{- else -}}
    {{ .Values.image.registry }}
  {{- end -}}
{{- end -}}
