{{- define "nginx.labels" -}}
app.kubernetes.io/name: {{ include "nginx.name" . }}
helm.sh/chart: {{ include "nginx.chart" . }}
{{- with .Chart.AppVersion }}
app.kubernetes.io/version: {{ . }}
{{- end }}
{{- if .Values.global.environment }}
environment: {{ .Values.global.environment }}
{{- end }}
{{- end }}

{{- define "nginx.name" -}}
{{ .Chart.Name }}
{{- end }}

{{- define "nginx.chart" -}}
{{ .Chart.Name }}-{{ .Chart.Version }}
{{- end }}

{{- define "nginx.image" -}}
{{- if and .Values.global.werf .Values.global.werf.images .Values.global.werf.images.frontend -}}
{{- $img := .Values.global.werf.images.frontend -}}
{{- if $img.full -}}
{{- $img.full -}}
{{- else -}}
{{- printf "%s/%s:%s" $img.registry $img.repository $img.tag -}}
{{- end -}}
{{- else if and .Values.global.werf .Values.global.werf.image .Values.global.werf.image.frontend -}}
{{- .Values.global.werf.image.frontend -}}
{{- else -}}
{{- printf "%s:%s" .Values.global.image.frontend.repository .Values.global.image.frontend.tag -}}
{{- end -}}
{{- end }}
