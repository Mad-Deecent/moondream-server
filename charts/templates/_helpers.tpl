{{/*
Expand the name of the chart.
*/}}
{{- define "moonstream-server.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "moonstream-server.fullname" -}}
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
{{- define "moonstream-server.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "moonstream-server.labels" -}}
helm.sh/chart: {{ include "moonstream-server.chart" . }}
{{ include "moonstream-server.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "moonstream-server.selectorLabels" -}}
app.kubernetes.io/name: {{ include "moonstream-server.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "moonstream-server.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "moonstream-server.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the PVC to use
*/}}
{{- define "moonstream-server.pvcName" -}}
{{- if .Values.persistence.existingClaim }}
{{- .Values.persistence.existingClaim }}
{{- else }}
{{- printf "%s-data" (include "moonstream-server.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Create the name of the model cache PVC to use
*/}}
{{- define "moonstream-server.modelPvcName" -}}
{{- if .Values.modelCache.existingClaim }}
{{- .Values.modelCache.existingClaim }}
{{- else }}
{{- printf "%s-models" (include "moonstream-server.fullname" .) }}
{{- end }}
{{- end }}
