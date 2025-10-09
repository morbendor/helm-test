{{/*
Expand the name of the ingress-controller-ops-job.
*/}}
{{- define "ingress-controller-ops.name" -}}
{{- default "ingress-controller-ops" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "ingress-controller-ops-job.selectorLabels" -}}
app.kubernetes.io/name: ingress-controller-ops-job
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "ingress-controller-ops.labels" -}}
{{ include "ingress-controller-ops-job.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "ingress-controller-ops-hook.common.podTemplate" -}}
metadata:
  labels:
    {{- if (eq "istio" .Values.global.ingressType) }}
    sidecar.istio.io/inject: "false"
    {{- end }}
    app: ingress-controller-ops-hook
spec:
  serviceAccountName: ingress-controller-ops-hook
  restartPolicy: Never
  terminationGracePeriodSeconds: 0  
  containers:
  - name: main
    image: {{ include "image-path" (dict "root" .Values "image" .Values.auxImages.icOps) }}
    imagePullPolicy: Always
{{- end }}

{{/*
The post install actions pod template
*/}}
{{- define "ingress-controller-ops-hook.install.podTemplate" -}}
{{ include "ingress-controller-ops-hook.common.podTemplate" . }}
    env:
    - name: ANYWHERE_NAMESPACE
      value: {{ .Release.Namespace }}
    - name: INGRESS_NAMESPACE
      value: {{ include "ingressController.namespace" . }}
    - name: INGRESS_CONTROLLER_DEPLOY_NAME
      value: {{ include "ingressController.deploymentName" . }}
    - name: IS_AUTO_PATCH
      value: "{{ .Values.global.autoInstall.autoPatchIngressControllerResources }}"
    - name: IS_ROLLOUT_RESTART
      value: "{{ .Values.global.autoInstall.restartIngressControllerDeployment }}"
    - name: INGRESS_TYPE
      value: {{ .Values.global.ingressType }}
    {{- if eq "kong" .Values.global.ingressType }}
    volumeMounts:
    - name: kong-gateway-patch
      mountPath: /usr/src/app/patches/kong-deployment-patch.json
      subPath: patch.json
  volumes:
  - name: kong-gateway-patch
    configMap:
      name: kong-gateway-patch
    {{- end }}
    {{- if eq "nginx" .Values.global.ingressType }}
    volumeMounts:
    - name: ingress-nginx-patch
      mountPath: /usr/src/app/patches/nginx-deployment-patch.json
      subPath: deploy-patch.json
    - name: ingress-nginx-patch
      mountPath: /usr/src/app/patches/nginx-cm-patch.json
      subPath: config-patch.json
  volumes:
  - name: ingress-nginx-patch
    configMap:
      name: ingress-nginx-patch
    {{- end }}
    {{- if eq "istio" .Values.global.ingressType }}
    volumeMounts:
    - name: istio-ingress-patch
      mountPath: /usr/src/app/patches/istio-deployment-patch.json
      subPath: patch.json
  volumes:
  - name: istio-ingress-patch
    configMap:
      name: istio-ingress-patch
    {{- end }}
    {{- if eq "gloo" .Values.global.ingressType }}
    - name: GLOO_SETTINGS_NAME
      value: default
    volumeMounts:
    - name: gloo-patch
      mountPath: /usr/src/app/patches/gloo-settings-patch.json
      subPath: patch.json
  volumes:
  - name: gloo-patch
    configMap:
      name: gloo-patch
    {{- end }}
{{- end }}

{{- define "ingress-controller-ops-hook.cleanup.podTemplate" -}}
{{ include "ingress-controller-ops-hook.common.podTemplate" . }}
    env:
    - name: ANYWHERE_NAMESPACE
      value: {{ .Release.Namespace }}
    - name: INGRESS_NAMESPACE
      value: {{ include "ingressController.namespace" . }}
    - name: INGRESS_CONTROLLER_DEPLOY_NAME
      value: {{ include "ingressController.deploymentName" . }}
    - name: INGRESS_TYPE
      value: {{ .Values.global.ingressType }}
    - name: IS_HELM_UNINSTALL
      value: "true"
    {{- if eq "kong" .Values.global.ingressType }}
    - name: PLUGIN_NAME
      value: {{ .Values.kong.pluginName }}
    volumeMounts:
    - name: kong-gateway-counter-patch
      mountPath: /usr/src/app/patches/kong-deployment-patch.json
      subPath: patch.json
  volumes:
  - name: kong-gateway-counter-patch
    configMap:
      name: kong-gateway-counter-patch
    {{- end }}
    {{- if eq "nginx" .Values.global.ingressType }}
    volumeMounts:
    - name: ingress-nginx-counter-patch
      mountPath: /usr/src/app/patches/nginx-deployment-patch.json
      subPath: deploy-patch.json
  volumes:
  - name: ingress-nginx-counter-patch
    configMap:
      name: ingress-nginx-counter-patch
    {{- end }}
    {{- if eq "istio" .Values.global.ingressType }}
    volumeMounts:
    - name: istio-ingress-counter-patch
      mountPath: /usr/src/app/patches/istio-deployment-patch.json
      subPath: patch.json
  volumes:
  - name: istio-ingress-counter-patch
    configMap:
      name: istio-ingress-counter-patch
    {{- end }}
    {{- if eq "gloo" .Values.global.ingressType }}
    - name: GLOO_SETTINGS_NAME
      value: {{ .Values.gloo.settingsResourceName }}
    volumeMounts:
    - name: gloo-counter-patch
      mountPath: /usr/src/app/patches/gloo-settings-patch.json
      subPath: patch.json
  volumes:
  - name: gloo-counter-patch
    configMap:
      name: gloo-counter-patch
    {{- end }}
{{- end }}

{{- define "ingress-controller-ops.createAutoPatchResources" -}}
{{- if and (include "ingressType.isPatchable" .) (or .Values.global.autoInstall.restartIngressControllerDeployment .Values.global.autoInstall.autoPatchIngressControllerResources) }}
true
{{- else }}
{{- end }}
{{- end -}}

{{- define "ingressController.deploymentName" -}}
{{ .Values.global.ingressControllerDeploymentName | default (get .Values.global.defaults.ingressControllerDeploymentName .Values.global.ingressType) }}
{{- end -}}

{{- define "ingressController.namespace" -}}
{{ .Values.global.ingressControllerNamespace | default (get .Values.global.defaults.ingressControllerNamespace .Values.global.ingressType) }}
{{- end -}}

{{- define "ingressController.serviceName" -}}
{{ get .Values.global.defaults.ingressControllerServiceName .Values.global.ingressType }}
{{- end -}}

{{- define "ingressType.isPatchable" -}}
{{- if has .Values.global.ingressType (list "nginx" "istio" "kong" "gloo") }}
true
{{- end }}
{{- end }}

{{- define "ingressController.namespaceExists" -}}
{{- if .Values.global.isArgoCD }}
true
{{- else }}
  {{- $namespace := (lookup "v1" "Namespace" "" (include "ingressController.namespace" .)) -}}
  {{- if $namespace }}
  true
  {{- else }}
  {{ fail (printf "Ingress Controller namespace '%s' doesn't exist." (include "ingressController.namespace" .)) }}
  {{- end }}
{{- end }}
{{- end }}