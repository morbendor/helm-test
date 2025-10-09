{{- define "gloo.pluginInjection" -}}
{
  "spec": {
    "extProc": {
      "failureModeAllow": {{ $.Values.global.failOpen }},
      "filterStage": {
        "predicate": "Before",
        "stage": "RouteStage"
      },
      "grpcService": {
        "extProcServerRef": {
          "name": "{{ $.Values.securityEngineServiceName }}-upstream",
          "namespace": "{{ .Release.Namespace }}"
        }
      },
      "processingMode": {
        "requestBodyMode": "STREAMED",
        "responseBodyMode": "STREAMED"
      }
    }
  }
}
{{- end -}}

{{- define "gloo.counterPatch" -}}
{
  "spec": {
    "extProc": null,
    "metadata": {
      "annotations": {
        "imperva/patch-timestamp": null
      }
    }
  }
}
{{- end -}}