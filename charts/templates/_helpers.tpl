{{/*
Expand the name of the chart.
*/}}
{{- define "moondream-station.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "moondream-station.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "moondream-station.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "moondream-station.labels" -}}
helm.sh/chart: {{ include "moondream-station.chart" . }}
{{ include "moondream-station.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "moondream-station.selectorLabels" -}}
app.kubernetes.io/name: {{ include "moondream-station.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "moondream-station.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "moondream-station.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the PVC to use
*/}}
{{- define "moondream-station.pvcName" -}}
{{- if .Values.persistence.existingClaim }}
{{- .Values.persistence.existingClaim }}
{{- else }}
{{- printf "%s-data" (include "moondream-station.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Create the name of the model cache PVC to use
*/}}
{{- define "moondream-station.modelPvcName" -}}
{{- if .Values.modelCache.existingClaim }}
{{- .Values.modelCache.existingClaim }}
{{- else }}
{{- printf "%s-models" (include "moondream-station.fullname" .) }}
{{- end }}
{{- end }}
