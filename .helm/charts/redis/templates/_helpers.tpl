{{- define "redis.labels" -}}
app.kubernetes.io/name: {{ include "redis.name" . }}
helm.sh/chart: {{ include "redis.chart" . }}
{{- with .Chart.AppVersion }}
app.kubernetes.io/version: {{ . }}
{{- end }}
{{- if .Values.global.environment }}
environment: {{ .Values.global.environment }}
{{- end }}
{{- end }}

{{- define "redis.name" -}}
{{ .Chart.Name }}
{{- end }}

{{- define "redis.chart" -}}
{{ .Chart.Name }}-{{ .Chart.Version }}
{{- end }}
