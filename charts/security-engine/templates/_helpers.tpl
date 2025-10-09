{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "security-engine.fullname" -}}
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
{{- define "security-engine.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "security-engine.labels" -}}
helm.sh/chart: {{ include "security-engine.chart" . }}
{{ include "security-engine.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "security-engine.selectorLabels" -}}
app.kubernetes.io/name: {{ include "security-engine.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "security-engine.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "security-engine.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
CA certificate for communicating with API Security Receiver
*/}}
{{- define "volume-apisec-ca-secret" -}}
{{- $secret := lookup "v1" "Secret" .Release.Namespace "receiver-tls-secret" -}}
{{- if $secret }}
- name: api-security-tls-ca-{{ .Release.Namespace }}
  secret:
    secretName: receiver-tls-secret
    defaultMode: 0400
    items:
      - key: ca.crt
        path: api_gw.crt
{{- end }}
{{- end }}

{{- define "volume-mount-apisec-ca-secret" -}}
{{- $secret := lookup "v1" "Secret" .Release.Namespace "receiver-tls-secret" -}}
{{- if $secret }}
- mountPath: "/incap/global_config/global/api_gw/api_gw.crt"
  subPath: api_gw.crt
  name: api-security-tls-ca-{{ .Release.Namespace }}
  readOnly: true
{{- end }}
{{- end }}

{{/*
LSE resources with IP2ASN param
*/}}
{{- define "security-engine.resources" -}}
requests:    
  cpu: {{ .Values.resources.main.requests.cpu }}
  memory: {{ .Values.resources.main.requests.memory }}
limits:
  cpu: {{ .Values.resources.main.limits.cpu }}
  {{- if not .Values.ip2asn }}  
  memory: {{ .Values.resources.main.limits.memory }}
  {{- else }}
  memory: {{ .Values.resources.main.limits.memory_ip2asn }}
  {{- end }}
{{- end }}

{{/*
LSE source env dict template
*/}}
{{- define "security-engine.source-env" -}}
{{- $allowed := dict "VPOP-GC" true "VPOP-AWS" true "VPOP-AZURE" true "LSE" true -}}
{{- $val := .Values.sourceEnv | default "LSE" -}}
{{- if hasKey $allowed $val -}}
{{ $val }}
{{- else -}}
LSE
{{- end }}
{{- end }}
