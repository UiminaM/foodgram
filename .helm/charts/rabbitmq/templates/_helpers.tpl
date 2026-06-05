{{- define "rabbitmq.labels" -}}
app.kubernetes.io/name: {{ include "rabbitmq.name" . }}
helm.sh/chart: {{ include "rabbitmq.chart" . }}
{{- with .Chart.AppVersion }}
app.kubernetes.io/version: {{ . }}
{{- end }}
{{- if .Values.global.environment }}
environment: {{ .Values.global.environment }}
{{- end }}
{{- end }}

{{- define "rabbitmq.name" -}}
{{ .Chart.Name }}
{{- end }}

{{- define "rabbitmq.chart" -}}
{{ .Chart.Name }}-{{ .Chart.Version }}
{{- end }}
