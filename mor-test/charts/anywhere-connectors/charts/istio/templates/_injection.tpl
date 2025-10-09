{{- define "istio.pluginInjection" -}}
{
  "spec": {
    "template": {
      "spec": {
        "containers": [
          {
            "name": "istio-proxy",
            "volumeMounts": [
              {
                "mountPath": "/etc/envoy/certs",
                "name": "ext-proc-filter-ca-root-cert"
              }
            ]
          }
        ],
        "volumes": [
          {
            "name": "ext-proc-filter-ca-root-cert",
            "secret": {
              "defaultMode": 420,
              "secretName": "{{ include "anywhere-commons.get-security-engine-tls-secret-name-ic" .}}"
            }
          }
        ]
      }
    }
  }
}
{{- end -}}

{{- define "istio.counterPatch" -}}
{
  "spec": {
    "template": {
      "spec": {
        "containers": [
          {
            "name": "istio-proxy",
            "volumeMounts": [
              {
                "$patch": "delete",
                "mountPath": "/etc/envoy/certs",
                "name": "ext-proc-filter-ca-root-cert"
              }
            ]
          }
        ],
        "volumes": [
          {
            "$patch": "delete",
            "name": "ext-proc-filter-ca-root-cert"
          }
        ]
      }
    }
  }
}
{{- end -}}