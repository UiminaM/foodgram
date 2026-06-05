{{- define "db.labels" -}}
app.kubernetes.io/name: {{ include "db.name" . }}
helm.sh/chart: {{ include "db.chart" . }}
{{- with .Chart.AppVersion }}
app.kubernetes.io/version: {{ . }}
{{- end }}
{{- if .Values.global.environment }}
environment: {{ .Values.global.environment }}
{{- end }}
{{- end }}

{{- define "db.name" -}}
{{ .Chart.Name }}
{{- end }}

{{- define "db.chart" -}}
{{ .Chart.Name }}-{{ .Chart.Version }}
{{- end }}
