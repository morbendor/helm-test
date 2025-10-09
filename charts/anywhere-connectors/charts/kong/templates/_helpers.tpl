{{- define "kong.getEnvVar" -}}
{{- $kongDeployment := lookup "apps/v1" "Deployment" (include "ingressController.namespace" .root) (include "ingressController.deploymentName" .root) -}}
{{- if $kongDeployment }}
  {{- with $kongDeployment }}
      {{- if .spec.template.spec.containers }}
        {{- range .spec.template.spec.containers }}
          {{- if eq .name "proxy" }}
            {{- range .env }}
              {{- if eq .name .variableName }}
                {{- .value }}
                {{- break -}}
              {{- end }}
            {{- end }}
            {{- break -}}
          {{- end }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end -}}
{{- end -}}

{{- define "kong.env.KONG_PLUGINS" -}}
{{- without (include "kong.getEnvVar" (dict "root" . "variableName" "KONG_PLUGINS") | default "" | splitList ",") "impv-waf-plugin" | join "," }}
{{- end -}}

{{- define "kong.env.KONG_LUA_PACKAGE_CPATH" -}}
{{- without (include "kong.getEnvVar" (dict "root" . "variableName" "KONG_LUA_PACKAGE_CPATH") | default "" | splitList ";") "$(IMPV_PLUGIN_PATH)/lib/?.so" | join ";" }}
{{- end -}}

{{- define "kong.env.LD_LIBRARY_PATH" -}}
{{- without (include "kong.getEnvVar" (dict "root" . "variableName" "LD_LIBRARY_PATH") | default "" | splitList ":") "$(IMPV_PLUGIN_PATH)/lib" | join ":" }}
{{- end -}}