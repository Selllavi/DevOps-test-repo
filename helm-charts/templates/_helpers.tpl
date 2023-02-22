{{- define "weather.instance" -}}
{{- join "-" (compact (regexFindAll "[a-zA-Z0-9]*" (coalesce .Values.instance "default") -1)) -}}
{{- end -}}

{{- define "weather.labels" -}}
{{ include "weather.commonLabels" . }}
{{ include "weather.selectorLabels" .}}
{{- end -}}

{{- define "weather.commonLabels" -}}
app.kubernetes.io/version: "{{ default .Chart.AppVersion .Values.imageTag }}"
app.kubernetes.io/managed-by: "helm"
{{- end -}}

{{- define "weather.selectorLabels" -}}
app.kubernetes.io/name: "weather"
app.kubernetes.io/instance: "{{ include "weather.instance" . | trunc 63 }}"
{{- end -}}

{{- define "weather.name" -}}
    {{- if ne (include "weather.instance" .) "default" -}}
        {{- print "weather-" (include "weather.instance" .) | trunc 63 -}}
    {{- else -}}
      {{- print "weather" -}}
    {{- end -}}
{{- end -}}

