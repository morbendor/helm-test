{{/*
Expand the name of the chart.
*/}}
{{- define "anywhere-commons.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Import a CA certificate for all Imperva microservices to establish mTLS communication.
*/}}
{{- define "anywhere-commons.import-ca-cert" -}}
{{- if and .Values.global.caCertificate .Values.global.caKey -}}
certificate: {{ .Values.global.caCertificate }}
key: {{ .Values.global.caKey }}
{{- else -}}
  {{- $caSecret := lookup "v1" "Secret" .Release.Namespace (printf "imperva-ca-%s" .Release.Namespace) -}}
  {{- if $caSecret -}}
certificate: {{ get $caSecret.data "tls.crt" }}
key: {{ get $caSecret.data "tls.key" }}
  {{- else -}}
    {{- $ca := genCA "imperva-ca" 365 -}}
certificate: {{ $ca.Cert | b64enc }}
key: {{ $ca.Key | b64enc }}
  {{- end -}}
{{- end -}}
{{- end -}}



{{- define "anywhere-commons.get-security-engine-tls-secret-name" -}}
{{- $defaultSESecret := printf "security-engine-certs-%s" .Release.Namespace -}}
{{ .Values.global.tls.existingSecret | default $defaultSESecret }}
{{- end -}}

{{- define "anywhere-commons.get-security-engine-tls-secret-name-ic" -}}
{{- $defaultSESecret := printf "security-engine-certs-%s" (include "ingressController.namespace" .) -}}
{{ .Values.global.tls.existingSecret | default $defaultSESecret }}
{{- end -}}


{{- define "anywhere-commons.get-cloud-mediator-tls-secret-name" -}}
{{- $defaultCMSecret := printf "cloud-mediator-certs-%s" .Release.Namespace -}}
{{ .Values.global.tls.existingSecret | default $defaultCMSecret }}
{{- end -}}

{{- define "anywhere-commons.get-data-sender-tls-secret-name" -}}
{{- $defaultDSSecret := printf "data-sender-certs-%s" .Release.Namespace -}}
{{ .Values.global.tls.existingSecret | default $defaultDSSecret }}
{{- end -}}


{{- define "security-engine.default-name" -}}
security-engine
{{- end -}}

{{/*
Expand the name of the chart.
*/}}
{{- define "security-engine.name" -}}
{{- default (include "security-engine.default-name" .) .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*Generate certificates for the LSE*/}}
{{- define "security-engine.gen-certs" -}}
{{- $existingSecret := (lookup "v1" "Secret" .Release.Namespace (printf "%s-certs-%s" (include "security-engine.name" .) .Release.Namespace)) -}}
{{- if $existingSecret -}}
  {{- /* Use existing certificates */ -}}
tls.crt: {{ index $existingSecret.data "tls.crt" }}
tls.key: {{ index $existingSecret.data "tls.key" }}
ca.crt: {{ index $existingSecret.data "ca.crt" }}
{{- else -}}
{{- /* Generate new certificates using existing logic */ -}}
{{- $namespace := .Release.Namespace -}}
{{- $caComponents := include "anywhere-commons.import-ca-cert" . | fromYaml }}
{{- $ca := buildCustomCert $caComponents.certificate $caComponents.key -}}
{{- $serviceName := "imperva-security-engine-svc" -}}
{{- $serviceFQDN := printf "%s.%s.svc.cluster.local" $serviceName $namespace -}}
{{- $altNames := list $serviceName $serviceFQDN -}}
{{- $cert := genSignedCert $serviceName nil $altNames 365 $ca -}}
tls.crt: {{ $cert.Cert | b64enc }}
tls.key: {{ $cert.Key | b64enc }}
ca.crt: {{ $ca.Cert | b64enc }}
{{- end -}}
{{- end -}}

{{- define "imagePullSecret" }}
{{- printf "{\"auths\": {\"%s\": {\"auth\": \"%s\"}}}" .Values.global.registry (printf "%s:%s" .Values.global.registryCredentials.username .Values.global.registryCredentials.password | b64enc) | b64enc }}
{{- end }}


{{/*
Expand the name of the access-token-job.
*/}}
{{- define "update-image-pull-secrets-job.name" -}}
{{- default "update-image-pull-secrets-job" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Return a remote image path based on `.Values` (passed as root) and `.` (any `.image` from `.Values` passed as parameter)
*/}}
{{- define "image-path" -}}
{{- $registry := (empty .root.global.registry) | ternary "" (printf "%s/" .root.global.registry  ) -}}
{{- if .image.digest -}}
{{ $registry }}{{ .image.repository }}@{{ .image.digest }}
{{- else }}
{{- $tagSuffix := "" -}}
{{- if .image.tagSuffix -}}
{{- $tagSuffix = printf "-%s" .image.tagSuffix -}}
{{- end -}}
{{ $registry }}{{ .image.repository }}:{{ .image.tag }}{{ $tagSuffix }}
{{- end -}}
{{- end -}}




{{/*
Decide whether the update-image-pull-secrets-job should run.
There are 2 conditions that need to be met in order for the job to run:
1. The registry is imperva.jfrog.io
2. The username and password are empty
*/}}
{{- define "update-image-pull-secrets-job.shouldRun" -}}
{{- if (and (eq .Values.global.registry "imperva.jfrog.io") (and (empty .Values.global.registryCredentials.username) (empty .Values.global.registryCredentials.password))) }}
true
{{- else }}

{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "update-image-pull-secrets-job.selectorLabels" -}}
app.kubernetes.io/name: update-image-pull-secrets-job-{{ .Release.Namespace }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "update-image-pull-secrets-job.labels" -}}
{{ include "update-image-pull-secrets-job.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}


{{/*
The access-token-job pod template
*/}}
{{- define "update-image-pull-secrets-job.podTemplate" -}}
metadata:
  labels:
    {{- if (eq "istio" .Values.global.ingressType) }}
    sidecar.istio.io/inject: "false"
    {{- end }}
    app: update-image-pull-secrets
spec:
  securityContext:
    fsGroup: 2000
  serviceAccountName: update-image-pull-secret-job-{{ .Release.Namespace }}
  volumes:
    - name: imperva-auth-secrets
      secret:
        secretName: imperva-auth
        defaultMode: 0400
  {{- include "volume-customer-cert-creation" . | indent 4 }}
  containers:
    - name: init
      image: "{{ include "image-path" (dict "root" .Values "image" .Values.auxImages.updateImagePullSecrets) }}"
      imagePullPolicy: "{{ .Values.auxImages.updateImagePullSecrets.pullPolicy }}"
      env:
        - name: PROFILE
          value: {{.Values.global.env}}
        - name: DEBUG
          value: "{{ .Values.global.debug }}"
        - name: UPDATE_INGRESS_NAMESPACE_SECRETS
          value: "{{ include "is-ingress-controller-ns-secret-required" .}}"
        - name: INGRESS_NAMESPACE
          value: {{ include "ingressController.namespace" . }}
        - name: CLIENT_REQUESTS_TIMEOUT_SECONDS
          value: "{{ .Values.network.requestTimeout }}"
        - name: ACCESS_TOKEN_HOST
          value: {{ (eq "prod" .Values.global.env) | ternary "https://anywhere-gateway.us.impervaservices.com/anywhere-data-service/anywhere-provisioner" "https://anywhere-gateway.us.stage.impervaservices.com/anywhere-data-service/anywhere-provisioner" }}
        - name: IMPERVA_INSTANCE_ID
          valueFrom:
            configMapKeyRef:
              key: instanceId
              name: shared-config
        - name: IMPERVA_CHART_VERSION
          valueFrom:
            configMapKeyRef:
              key: chartVersion
              name: shared-config
        - name: IMPERVA_CONTROLLER_PACKAGE_KEY
          valueFrom:
            configMapKeyRef:
              key: controllerPackageKey
              name: shared-config
        - name: NODE_NAME
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
        - name: INGRESS_TYPE
          valueFrom:
            configMapKeyRef:
              key: ingressType
              name: shared-config
        {{ include "global-env-vars" . | nindent 8 }}
      volumeMounts:
        - mountPath: "/etc/imperva-auth"
          name: imperva-auth-secrets
      {{- include "volume-mount-customer-cert-creation" . | indent 8 }}
  restartPolicy: Never
  terminationGracePeriodSeconds: 0
{{- end }}

{{/*
Defining template for setting up global env vars, these var affect core functionality accross all components
*/}}
{{- define "global-env-vars" -}}
{{- if .Values.global.proxy }}
{{- if .Values.global.proxy.https }}
- name: http_proxy
  value: {{ .Values.global.proxy.http | quote}}
- name: HTTP_PROXY
  value: {{ .Values.global.proxy.http | quote }}
- name: https_proxy
  value: {{ .Values.global.proxy.https | quote }}
- name: HTTPS_PROXY
  value: {{ .Values.global.proxy.https | quote }}
{{- end }}
- name: no_proxy
  value: {{ printf "%s"  (.Values.global.proxy.noProxy | default "") | quote }}
- name: NO_PROXY
  value: {{ printf "%s"  (.Values.global.proxy.noProxy | default "") | quote }}
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


{{/*
Defining access-token-job role binding
*/}}
{{- define "update-image-pull-secrets-job.roleBinding" -}}
subjects:
  - kind: ServiceAccount
    name: update-image-pull-secret-job-{{ .Release.Namespace }}
    namespace: {{ .Release.Namespace }}
roleRef:
  kind: ClusterRole
  name: update-image-pull-secret-job-role-{{ .Release.Namespace }}
  apiGroup: rbac.authorization.k8s.io
{{- end }}


{{/*
Defining ingress type getter
*/}}
{{- define "ingressType" -}}
{{- printf "%s" $.Values.global.ingressType }}
{{- end }}

{{/*Adding volume for customer certificate*/}}
{{- define "volume-customer-cert-creation" -}}
{{- if ( include "is-using-custom-certifiate" .)}}
- name: client-proxy-cert-{{ .Release.Namespace }}
  secret:
    secretName: {{.Values.global.certificates.secretCertName}}
    optional: true
    defaultMode: 0400
{{- end }}
{{- end }}

{{/*Adding volumeMounts for customer certificate*/}}
{{- define "volume-mount-customer-cert-creation" -}}
{{- if ( include "is-using-custom-certifiate" .)}}
- name: client-proxy-cert-{{ .Release.Namespace }}
  mountPath: {{ .Values.global.certificates.certFilePath | dir }}
  readOnly: true
{{- end }}
{{- end }}

{{- define "is-using-custom-certifiate" -}}
{{- if (and (empty .Values.global.certificates.certFilePath) (empty .Values.global.certificates.secretCertName)) }}

{{- else }}
true
{{- end }}
{{- end }}


{{- define "ingressController.namespace" -}}
{{ .Values.global.ingressControllerNamespace | default (get .Values.global.defaults.ingressControllerNamespace .Values.global.ingressType) }}
{{- end -}}


{{- define "requested-plugin-image-vars" -}}
{{- if eq "nginx" .Values.global.ingressType }}
{{- with (index .Values "anywhere-connectors" "nginx-ingress-controller") }}
- name: IMAGE_PULL_SECRET
  value: "{{ include "imagePullSecret" $ }}"
- name: REQUESTED_INGRESS_VERSION
  value: "{{- .base.tag }}"
- name: REQUESTED_PLUGIN_IMAGE
  value: "{{ printf "%s-%s-%s" (include "image-path" (dict "root" $.Values "image" .auxImages.nginxPlugin)) .base.flavor .base.tag | trim }}"
{{- end }}
{{- else if eq "kong" .Values.global.ingressType }}
{{- with (index .Values "anywhere-connectors" "kong") }}
- name: IMAGE_PULL_SECRET
  value: "{{ include "imagePullSecret" $ }}"
- name: REQUESTED_INGRESS_VERSION
  value: "{{- .base.tag }}"
- name: REQUESTED_PLUGIN_IMAGE
  value: "{{ printf "%s-%s-%s" (include "image-path" (dict "root" $.Values "image" .auxImages.kongPlugin)) .base.flavor .base.tag | trim }}"
{{- end }}
{{- else }}
{{- end }}
{{- end }}


{{- define "is-ingress-controller-ns-secret-required" -}}
{{- if (has .Values.global.ingressType (list "nginx" "kong")) -}}
true
{{- else }}

{{- end }}
{{- end }}


{{- define "check-prerequisites-hook.podTemplate" -}}
metadata:
  labels:
    app: check-prerequisites-hook
spec:
  serviceAccountName: check-prerequisites-hook
  containers:
    - name: check-prerequisites
      image: "{{ include "image-path" (dict "root" .Values "image" .Values.auxImages.checkPrerequisites) }}"
      imagePullPolicy: {{ .Values.auxImages.checkPrerequisites.pullPolicy }}
      env:
        - name: INGRESS_TYPE
          value: {{ .Values.global.ingressType }}
        - name: IC_SVC_NAME
          value: {{ include "ingressController.serviceName" . }}
        - name: IC_NAMESPACE
          value: {{ include "ingressController.namespace" . }}
        - name: PRODUCT_TYPE
          value: {{ include "get-chosen-product" . }}
        {{ include "requested-plugin-image-vars" . | nindent 8 }}
        {{ include "global-env-vars" . | nindent 8 }}
  restartPolicy: Never
{{- end }}


{{/*
Selector labels
*/}}
{{- define "checkPrerequisites-job.selectorLabels" -}}
app.kubernetes.io/name: checkPrerequisites-job-{{ .Release.Namespace }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "checkPrerequisites-job.labels" -}}
{{ include "checkPrerequisites-job.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}


{{- define "get-chosen-product" -}}
{{- $trueKey := "" -}}
{{- range $key, $value := .Values.tags -}}
  {{- if $value -}}
    {{- $trueKey = $key -}}
  {{- end -}}
{{- end -}}
{{- $trueKey -}}
{{- end -}}

