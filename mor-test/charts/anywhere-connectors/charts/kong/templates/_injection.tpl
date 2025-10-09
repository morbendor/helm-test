{{- define "kong.pluginInjection" -}}
{
  "spec": {
    "template": {
      "spec": {
        "imagePullSecrets": [
          {
            "name": "waf-anywhere-artifactory"
          }
        ],
        "initContainers": [
          {
            "name": "install-impv-plugin",
            "image": "{{ include "image-path" (dict "root" .Values "image" .Values.auxImages.kongPlugin) }}-{{ .Values.base.flavor }}{{ .Values.base.tag }}",
            "command": [
              "sh",
              "-c",
              "cp -r ./* /impv-waf-plugin/"
            ],
            "imagePullPolicy": "IfNotPresent",
            "securityContext": {
              "allowPrivilegeEscalation": false,
              "capabilities": {
                "drop": [
                  "ALL"
                ]
              },
              "readOnlyRootFilesystem": true,
              "runAsNonRoot": true,
              "runAsUser": 1000,
              "seccompProfile": {
                "type": "RuntimeDefault"
              }
            },
            "terminationMessagePolicy": "File",
            "volumeMounts": [
              {
                "mountPath": "/impv-waf-plugin/",
                "name": "impv-waf-plugin"
              }
            ]
          }
        ],
        "containers": [
          {
            "name": "proxy",
            "env": [
              {
                "name": "KONG_PLUGINS",
                "value": "{{ include "kong.env.KONG_PLUGINS" . | default "bundled" }},impv-waf-plugin"
              },
              {
                "name": "IMPV_PLUGIN_PATH",
                "value": "/usr/local/share/lua/5.1/kong/plugins/impv-waf-plugin"
              },
              {
                "name": "KONG_LUA_PACKAGE_CPATH",
                "value": "$(IMPV_PLUGIN_PATH)/lib/?.so;{{ include "kong.env.KONG_LUA_PACKAGE_CPATH" . | default ";" }}"
              },
              {
                "name": "LD_LIBRARY_PATH",
                "value": "$(IMPV_PLUGIN_PATH)/lib:{{ include "kong.env.LD_LIBRARY_PATH" . | default "$LD_LIBRARY_PATH" }}"
              },
              {
                "name": "KONG_NGINX_HTTP_LUA_SHARED_DICT",
                "value": "impv_stats_shared_dict 10m"
              }
            ],
            "volumeMounts": [
              {
                "mountPath": "/usr/local/share/lua/5.1/kong/plugins/impv-waf-plugin",
                "name": "impv-waf-plugin"
              }
            ]
          },
          {
            "image": "{{.Values.global.registry}}/imperva-waf-anywhere-beta-docker/envoy:v1.33",
            "imagePullPolicy": "IfNotPresent",
            "name": "envoy",
            "securityContext": {
              "allowPrivilegeEscalation": false,
              "capabilities": {
                "drop": [
                  "ALL"
                ]
              },
              "readOnlyRootFilesystem": true,
              "runAsNonRoot": true,
              "runAsUser": 101,
              "seccompProfile": {
                "type": "RuntimeDefault"
              }
            },
            "ports": [
              {
                "containerPort": 10000,
                "name": "envoy-listener",
                "protocol": "TCP"
              }
            ],
            "terminationMessagePath": "/dev/termination-log",
            "terminationMessagePolicy": "File",
            "volumeMounts": [
              {
                "mountPath": "/etc/envoy/envoy.yaml",
                "name": "envoy",
                "subPath": "envoy.yaml"
              },
              {
                "mountPath": "/etc/envoy/ca.crt",
                "name": "ext-proc-filter-ca-root-cert",
                "subPath": "ca.crt"
              }
            ]
          }
        ],
        "volumes": [
          {
            "emptyDir": {
              "sizeLimit": "100Mi"
            },
            "name": "impv-waf-plugin"
          },
          {
            "name": "envoy",
            "configMap": {
              "defaultMode": 420,
              "items": [
                {
                  "key": "envoy.yaml",
                  "path": "envoy.yaml"
                }
              ],
              "name": "envoy-sidecar"
            }
          },
          {
            "name": "ext-proc-filter-ca-root-cert",
            "secret": {
              "defaultMode": 420,
              "secretName": "{{ include "anywhere-commons.get-security-engine-tls-secret-name-ic" .}}"
            }
          }
        ]
      },
      "metadata": {
        "annotations": {
          "imperva/patch-timestamp": {{ now | date "2006-01-02T15:04:05" | quote }}
        }
      }
    }
  }
}
{{- end -}}

{{- define "kong.counterPatch" -}}
{
  "spec": {
    "template": {
      "spec": {
        "imagePullSecrets": [
          {
            "$patch": "delete",
            "name": "waf-anywhere-artifactory"
          }
        ],
        "initContainers": [
          {
            "$patch": "delete",
            "name": "install-impv-plugin"
          }
        ],
        "containers": [
          {
            "name": "proxy",
            "env": [
              {
                "name": "KONG_PLUGINS",
                "value": "{{ include "kong.env.KONG_PLUGINS" . | default "bundled" }}"
              },
              {
                "$patch": "delete",
                "name": "IMPV_PLUGIN_PATH"
              },
              {
                "name": "KONG_LUA_PACKAGE_CPATH",
                "value": "{{ include "kong.env.KONG_LUA_PACKAGE_CPATH" . | default ";;" }}"
              },
              {
                "name": "LD_LIBRARY_PATH",
                "value": "{{ include "kong.env.LD_LIBRARY_PATH" . | default "$LD_LIBRARY_PATH" }}"
              },
              {
                "$patch": "delete",
                "name": "KONG_NGINX_HTTP_LUA_SHARED_DICT",
                "value": "impv_stats_shared_dict 10m"
              }
            ],
            "volumeMounts": [
              {
                "$patch": "delete",
                "mountPath": "/usr/local/share/lua/5.1/kong/plugins/impv-waf-plugin",
                "name": "impv-waf-plugin"
              }
            ]
          },
          {
            "$patch": "delete",
            "name": "envoy"
          }
        ],
        "volumes": [
          {
            "$patch": "delete",
            "name": "impv-waf-plugin"
          },
          {
            "$patch": "delete",
            "name": "envoy"
          },
          {
            "$patch": "delete",
            "name": "ext-proc-filter-ca-root-cert"
          }
        ]
      },
      "metadata": {
        "annotations": {
          "imperva/patch-timestamp": null
        }
      }
    }
  }
}
{{- end -}}