{{- define "nginx.pluginInjection" -}}
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
            "image": "{{ include "image-path" (dict "root" .Values "image" .Values.auxImages.nginxPlugin) }}-{{ .Values.base.flavor }}-{{ .Values.base.tag }}",
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
            "name": "controller",
            "volumeMounts": [
              {
                "name": "impv-waf-plugin",
                "mountPath": "/usr/lib/nginx/modules/imperva_waf_module.so",
                "subPath": "imperva_waf_module.so"
              },
              {
                "name": "impv-waf-plugin",
                "mountPath": "/usr/local/lib/libexternal_grpc.so",
                "subPath": "libexternal_grpc.so"
              },
              {
                "name": "impv-waf-plugin",
                "mountPath": "/usr/local/lib/libabsl_vlog_config_internal.so.2407.0.0",
                "subPath": "libabsl_vlog_config_internal.so.2407.0.0"
              },
              {
                "name": "impv-waf-plugin",
                "mountPath": "/usr/local/lib/libabsl_log_internal_fnmatch.so.2407.0.0",
                "subPath": "libabsl_log_internal_fnmatch.so.2407.0.0"
              }
            ]
          },
          {
            "name": "envoy",
            "image": "{{.Values.global.registry}}/imperva-waf-anywhere-beta-docker/envoy:v1.33",
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
              "runAsUser": 101,
              "seccompProfile": {
                "type": "RuntimeDefault"
              }
            },
            "terminationMessagePath": "/dev/termination-log",
            "terminationMessagePolicy": "File",
            "ports": [
              {
                "containerPort": 10000,
                "name": "envoy-listener",
                "protocol": "TCP"
              }
            ],
            "volumeMounts": [
              {
                "name": "envoy",
                "mountPath": "/etc/envoy/envoy.yaml",
                "subPath": "envoy.yaml"
              },
              {
                "name": "ext-proc-filter-ca-root-cert",
                "mountPath": "/etc/envoy/ca.crt",
                "subPath": "ca.crt"
              }
            ]
          }
        ],
        "volumes": [
          {
            "name": "envoy",
            "configMap": {
              "name": "envoy-sidecar",
              "defaultMode": 420,
              "items": [
                {
                  "key": "envoy.yaml",
                  "path": "envoy.yaml"
                }
              ]
            }
          },
          {
            "name": "ext-proc-filter-ca-root-cert",
            "secret": {
              "defaultMode": 420,
              "secretName": "{{ include "anywhere-commons.get-security-engine-tls-secret-name-ic" .}}"
            }
          },
          {
            "name": "impv-waf-plugin",
            "emptyDir": {
              "sizeLimit": "100Mi"
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

{{- define "nginx.configInjection" -}}
{
  "data": {
    "allow-snippet-annotations": "true",
    "enable-real-ip": "true",
    "http-snippet": "impv_waf_module_is_ssl off;\nimpv_waf_module_gateway_ip localhost;\nimpv_waf_module_gateway_port 10000;\nimpv_waf_module_pass_on_failure {{ (eq false .Values.global.failOpen) | ternary "off" "on" }};\nimpv_waf_max_gateway_grpc_recv_size 4194304;\nimpv_waf_max_buffer_size 4194294;\nimpv_waf_module_grpc_timeout 90000;\nimpv_waf_request_headers_initial_send_mode DEFAULT;\nimpv_waf_response_headers_initial_send_mode DEFAULT;\nimpv_waf_request_body_initial_send_mode STREAMED;\nimpv_waf_response_body_initial_send_mode STREAMED;",
    "location-snippet": "impv_waf_module_protect on;",
    "main-snippet": "load_module /usr/lib/nginx/modules/imperva_waf_module.so;",
    "proxy-body-size": "10m"
  }
}
{{- end -}}

{{- define "nginx.counterPatch" -}}
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
            "name": "controller",
            "volumeMounts": [
              {
                "$patch": "delete",
                "name": "impv-waf-plugin",
                "mountPath": "/usr/lib/nginx/modules/imperva_waf_module.so",
                "subPath": "imperva_waf_module.so"
              },
              {
                "$patch": "delete",
                "name": "impv-waf-plugin",
                "mountPath": "/usr/local/lib/libexternal_grpc.so",
                "subPath": "libexternal_grpc.so"
              },
              {
                "$patch": "delete",
                "name": "impv-waf-plugin",
                "mountPath": "/usr/local/lib/libabsl_vlog_config_internal.so.2407.0.0",
                "subPath": "libabsl_vlog_config_internal.so.2407.0.0"
              },
              {
                "$patch": "delete",
                "name": "impv-waf-plugin",
                "mountPath": "/usr/local/lib/libabsl_log_internal_fnmatch.so.2407.0.0",
                "subPath": "libabsl_log_internal_fnmatch.so.2407.0.0"
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
            "name": "envoy"
          },
          {
            "$patch": "delete",
            "name": "ext-proc-filter-ca-root-cert"
          },
          {
            "$patch": "delete",
            "name": "impv-waf-plugin"
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