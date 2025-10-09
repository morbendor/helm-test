{{/*
Expand the name of the chart.
*/}}
{{- define "cloud-mediator.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "cloud-mediator.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "cloud-mediator.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "cloud-mediator.labels" -}}
helm.sh/chart: {{ include "cloud-mediator.chart" . }}
{{ include "cloud-mediator.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "cloud-mediator.selectorLabels" -}}
app.kubernetes.io/name: {{ include "cloud-mediator.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "cloud-mediator.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "cloud-mediator.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}


{{/*Generate certificates for the Mediator*/}}
{{- define "cloud-mediator.gen-certs" -}}
{{- $existingSecret := (lookup "v1" "Secret" .Release.Namespace (printf "%s-certs-%s" (include "cloud-mediator.name" .) .Release.Namespace)) -}}
{{- if $existingSecret -}}
  {{- /* Use existing certificates */ -}}
tls.crt: {{ index $existingSecret.data "tls.crt" }}
tls.key: {{ index $existingSecret.data "tls.key" }}
ca.crt: {{ index $existingSecret.data "ca.crt" }}
{{- else -}}
  {{- /* Generate new certificates */ -}}
{{- $namespace := .Release.Namespace -}}
{{- $altNames := list ( printf "%s" (include "cloud-mediator.fullname" .) ) (printf "imperva-cloud-mediator.%s.svc.cluster.local" $namespace) -}}
{{- $caComponents := include "anywhere-commons.import-ca-cert" . | fromYaml }}
{{- $ca := buildCustomCert $caComponents.certificate $caComponents.key -}}
{{- $cert := genSignedCert ( include "cloud-mediator.fullname" . ) nil $altNames 365  $ca -}}
tls.crt: {{ $cert.Cert | b64enc }}
tls.key: {{ $cert.Key | b64enc }}
ca.crt: {{ $ca.Cert | b64enc }}
{{- end -}}
{{- end -}}