{{- define "k8-application.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "k8-application.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "k8-application.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}

{{- define "k8-application.labels" -}}
helm.sh/chart: {{ include "k8-application.chart" . }}
{{ include "k8-application.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "k8-application.canaryLabels" -}}
helm.sh/chart: {{ include "k8-application.chart" .root }}
{{ include "k8-application.canarySelectorLabels" . -}}
{{ include "k8-application.customLabels" .root -}}
{{- if .root.Chart.AppVersion }}
app.kubernetes.io/version: {{ .root.Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .root.Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}

{{- define "k8-application.selectorLabels" -}}
app.kubernetes.io/name: {{ include "k8-application.name" . }}
app.kubernetes.io/instance: {{ default .Release.Name .Values.instanceOverride }}
{{- end -}}

{{- define "k8-application.canarySelectorLabels" -}}
{{- if eq .root.Values.canary.trafficControl "aws-alb-weighted-tg" -}}
app.kubernetes.io/name: {{ include "k8-application.name" .root }}-{{ .canaryName }}
{{- else if eq .root.Values.canary.trafficControl "round-robin" }}
app.kubernetes.io/name: {{ include "k8-application.name" .root }}  # so it is targetable by the main Service
app.kubernetes.io/part-of: {{ include "k8-application.name" .root }}-{{ .canaryName }}  # so it is targetable by the canary Service
{{- end }}
app.kubernetes.io/instance: {{ .root.Release.Name }}
{{- end -}}

{{/*
Custom labels
*/}}
{{- define "k8-application.customLabels" -}}
{{- if .Values.customLabels }}
{{ toYaml .Values.customLabels }}
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "k8-application.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "k8-application.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{- define "k8-application.portNumber" -}}
{{- if kindIs "map" .port }}
{{- get .port "number" }}
{{- else }}
{{- .port }}
{{- end }}
{{- end -}}

{{- define "k8-application.portName" -}}
{{- if kindIs "map" .port }}
{{- get .port "name" }}
{{- end }}
{{- end -}}
