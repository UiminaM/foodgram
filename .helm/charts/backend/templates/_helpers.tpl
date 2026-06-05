{{- define "backend.labels" -}}
app.kubernetes.io/name: {{ include "backend.name" . }}
helm.sh/chart: {{ include "backend.chart" . }}
{{- with .Chart.AppVersion }}
app.kubernetes.io/version: {{ . }}
{{- end }}
{{- if .Values.global.environment }}
environment: {{ .Values.global.environment }}
{{- end }}
{{- end }}

{{- define "backend.name" -}}
{{ .Chart.Name }}
{{- end }}

{{- define "backend.chart" -}}
{{ .Chart.Name }}-{{ .Chart.Version }}
{{- end }}

{{- define "backend.image" -}}
{{- if and .Values.global.werf .Values.global.werf.images .Values.global.werf.images.backend -}}
{{- $b := .Values.global.werf.images.backend -}}
{{- if $b.full -}}
{{- $b.full -}}
{{- else -}}
{{- printf "%s/%s:%s" $b.registry $b.repository $b.tag -}}
{{- end -}}
{{- else if and .Values.global.werf .Values.global.werf.image .Values.global.werf.image.backend -}}
{{- .Values.global.werf.image.backend -}}
{{- else -}}
{{- printf "%s:%s" .Values.global.image.backend.repository .Values.global.image.backend.tag -}}
{{- end -}}
{{- end }}
