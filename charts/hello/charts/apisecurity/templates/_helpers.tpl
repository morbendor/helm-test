{{- define "imagePullSecret" }}
{{- printf "{\"auths\": {\"%s\": {\"auth\": \"%s\"}}}" .Values.artifactoryCredentials.registry (printf "%s:%s" .Values.artifactoryCredentials.username .Values.artifactoryCredentials.password | b64enc) | b64enc }}
{{- end }}

{{/*
Defining template for setting up global env vars, these vars affect core functionality across all components
*/}}
{{- define "apisec-global-env-vars" -}}
  {{- if .Values.global.proxy }}
    {{- if .Values.global.proxy.http }}
- name: http_proxy
  value: {{ .Values.global.proxy.http | quote }}
- name: HTTP_PROXY
  value: {{ .Values.global.proxy.http | quote }}
    {{- end }}
    {{- if .Values.global.proxy.https }}
- name: https_proxy
  value: {{ .Values.global.proxy.https | quote }}
- name: HTTPS_PROXY
  value: {{ .Values.global.proxy.https | quote }}
    {{- end }}
    {{- if .Values.global.proxy.noProxy }}
- name: no_proxy
  value: {{ printf "%s" (.Values.global.proxy.noProxy | default "") | quote }}
- name: NO_PROXY
  value: {{ printf "%s" (.Values.global.proxy.noProxy | default "") | quote }}
    {{- end }}
  {{- end}}

  {{- if .Values.env }}
    {{- if .Values.env.HTTP_PROXY }}
- name: HTTP_PROXY
  value: {{ .Values.env.HTTP_PROXY | quote }}
    {{- end }}
    {{- if .Values.env.HTTPS_PROXY }}
- name: HTTPS_PROXY
  value: {{ .Values.env.HTTPS_PROXY | quote }}
    {{- end }}
    {{- if .Values.env.NO_PROXY }}
- name: NO_PROXY
  value: {{ .Values.env.NO_PROXY | quote }}
    {{- end }}
  {{- end }}

  {{- if .Values.global.certificates.allowAnyCertificate }}
- name: ALLOW_ANY_CERTIFICATE
  value: {{ .Values.global.certificates.allowAnyCertificate | quote }}
  {{- end }}
  {{- if .Values.global.certificates.certFilePath }}
- name: CERT_FILE_PATH
  value: {{ .Values.global.certificates.certFilePath | quote }}
  {{- end }}
{{- end }}