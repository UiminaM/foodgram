{{/*
Frontend name
*/}}
{{- define "frontend.name" -}}
{{ .Chart.Name }}
{{- end }}

{{/*
Frontend chart
*/}}
{{- define "frontend.chart" -}}
{{ .Chart.Name }}-{{ .Chart.Version }}
{{- end }}

{{/*
Frontend labels
*/}}
{{- define "frontend.labels" -}}
app.kubernetes.io/name: {{ include "frontend.name" . }}
helm.sh/chart: {{ include "frontend.chart" . }}
{{- with .Chart.AppVersion }}
app.kubernetes.io/version: {{ . }}
{{- end }}
{{- if .Values.global.environment }}
environment: {{ .Values.global.environment }}
{{- end }}
{{- end }}

{{/*
Frontend selector labels
*/}}
{{- define "frontend.selectorLabels" -}}
app.kubernetes.io/name: {{ include "frontend.name" . }}
{{- end }}

