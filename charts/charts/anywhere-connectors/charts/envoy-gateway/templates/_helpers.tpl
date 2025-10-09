{{/*
Create a dictionary of HTTPRoutes grouped by namespace.
The goal is to create 'targetRefs' in the 'EnvoyExtensionPolicy' resource with the routenames for each namespace.
example structure:
- <namespace1>: [
	routename1,
	routename2
]
- <namespace2>: [
	routename3,
	routename4
]
*/}}
{{- define "envoy-gateway.httpRoutesByNamespace" -}}
{{- $httpRoutesByNamespace := dict }}
{{- range.Values.httproutes }}
	{{- $ns := .namespace | default $.Release.Namespace }}
	{{- if not (hasKey $httpRoutesByNamespace $ns) }}
		{{- $_ := set $httpRoutesByNamespace $ns (list) -}}
	{{- end }}
	{{- $_ := set $httpRoutesByNamespace $ns (append (index $httpRoutesByNamespace $ns) .name) }}
{{- end }}
{{- $httpRoutesByNamespace | toYaml -}}
{{- end }}

{{/*
Check if at least one namespace that is different from the release namespace.
In the case of 'ReferenceGrant' resource, it will be created only if at least one different namespace was specified.
*/}}
{{- define "envoy-gateway.atLeastOneDifferentNamespaceFromReleaseNamespace" -}}
{{- $httpRoutesByNamespace := include "envoy-gateway.httpRoutesByNamespace" . | fromYaml }}
{{- $hasDifferentNamespace := dict }}

{{- range $namespace, $routes := $httpRoutesByNamespace }}
  {{- if ne $namespace $.Release.Namespace }}
  	{{- $_ := set $hasDifferentNamespace "exists" true }}
    {{- break }}
  {{- end }}
{{- end }}
{{- hasKey $hasDifferentNamespace "exists" | toYaml -}}
{{- end }}

{{/*
Check if the provided input is valid:
1. Check if an unknown flag was set. It checks global and the current chart values.yaml.
2. Check if that httproutes is not empty. At least one route should be specified.
3. Check if a HTTPRoute name was specified. Name must be specified, Namespace can be left out if release namespace is desired.
4. Check if any unidentified key was specified.
	{{- if and (hasKey $allValues $key) (ne $key "global") }}
*/}}
{{- define "envoy-gateway.inputValidation" -}}
{{- $generalError := "Please specify HTTPRoutes in the values.yaml file as a list named 'httproutes' or by using an inline --set. For example: --set envoy-gateway.httproutes[0].name=myhttproute --set envoy-gateway.httproutes[0].namespace=myhttproutenamespace" }}
{{- if not .Values.httproutes }}
	{{- fail (printf "Input Validation Error: No HTTPRoutes specified. At least one HTTPRoute must be specified. '%s'" $generalError) }}
{{- end }}
{{- if not (kindIs "slice" .Values.httproutes) }}
	{{- fail (printf "Input Validation Error: Invalid type for HTTPRoutes. It must be a list. '%s'" $generalError) }}
{{- end }}
{{- range .Values.httproutes }}
	{{- if not (hasKey . "name") }}
		{{- fail (printf "Input Validation Error: Invalid keys specified for HTTPRoute. Attribute 'name' must be specified. '%s'" $generalError) }}
	{{- end }}
	{{- range $key, $value := . }}
		{{- if not (has $key (list "name" "namespace")) }}
			{{- fail (printf "Input Validation Error: Invalid key '%s' specified for HTTPRoute. Only 'name' and 'namespace' are allowed. '%s'" $key $generalError) }}
		{{- end }}
	{{- end }}
{{- end }}
{{- end }}

{{/*
Check if the provided HTTPRoutes and Namespaces exists in the K8s environment.
*/}}
{{- define "envoy-gateway.resourceExistsValidation" -}}
{{- $httpRoutesByNamespace := include "envoy-gateway.httpRoutesByNamespace" . | fromYaml }}
{{- range $namespace, $routes := $httpRoutesByNamespace }}
	{{- $ns := lookup "v1" "Namespace" $namespace $namespace }}
	{{- if not $ns }}
		{{- fail (printf "Resource Validation Error: Namespace '%s' does not exist." $namespace) }}
	{{- end }}
	{{- range $routeName := $routes }}
		{{- $route := lookup "gateway.networking.k8s.io/v1" "HTTPRoute" $namespace $routeName }}
		{{- if not $route }}
			{{- fail (printf "Resource Validation Error: HTTPRoute '%s' does not exist in namespace '%s'." $routeName $namespace) }}
		{{- end }}
	{{- end }}
{{- end }}
{{- end }}

{{/*
Validate the input and check if the resources exist.
*/}}
{{- define "envoy-gateway.validations" -}}
	{{- include "envoy-gateway.inputValidation" . -}}
	{{- include "envoy-gateway.resourceExistsValidation" . -}}
{{- end }}
