{{/*
Expand the name of the chart.
*/}}
{{- define "dashboard.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "dashboard.fullname" -}}
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
{{- define "dashboard.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "dashboard.labels" -}}
helm.sh/chart: {{ include "dashboard.chart" . }}
{{ include "dashboard.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "dashboard.selectorLabels" -}}
app.kubernetes.io/name: {{ include "dashboard.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Nexus labels
*/}}
{{- define "dashboard.nexus.labels" -}}
{{ include "dashboard.labels" . }}
app.kubernetes.io/component: nexus
{{- end }}

{{/*
Nexus selector labels
*/}}
{{- define "dashboard.nexus.selectorLabels" -}}
{{ include "dashboard.selectorLabels" . }}
app.kubernetes.io/component: nexus
{{- end }}

{{/*
FastAPI labels
*/}}
{{- define "dashboard.fastapi.labels" -}}
{{ include "dashboard.labels" . }}
app.kubernetes.io/component: fastapi
{{- end }}

{{/*
FastAPI selector labels
*/}}
{{- define "dashboard.fastapi.selectorLabels" -}}
{{ include "dashboard.selectorLabels" . }}
app.kubernetes.io/component: fastapi
{{- end }}

{{/*
Trino fullname
*/}}
{{- define "dashboard.trino.fullname" -}}
{{ include "dashboard.fullname" . }}-trino
{{- end }}

{{/*
Trino labels
*/}}
{{- define "dashboard.trino.labels" -}}
{{ include "dashboard.labels" . }}
app.kubernetes.io/component: trino
{{- end }}

{{/*
Trino selector labels
*/}}
{{- define "dashboard.trino.selectorLabels" -}}
{{ include "dashboard.selectorLabels" . }}
app.kubernetes.io/component: trino
{{- end }}

{{/*
Frontend labels
*/}}
{{- define "dashboard.frontend.labels" -}}
{{ include "dashboard.labels" . }}
app.kubernetes.io/component: frontend
{{- end }}

{{/*
Frontend selector labels
*/}}
{{- define "dashboard.frontend.selectorLabels" -}}
{{ include "dashboard.selectorLabels" . }}
app.kubernetes.io/component: frontend
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "dashboard.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "dashboard.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Shared database env block for prediction workers.
Workers connect to Trino (to read training data) and Postgres (to write
predictions back to prediction_data.*). Credentials live in the same
secrets nexus uses.
*/}}
{{- define "dashboard.predictionWorker.dbEnv" -}}
- name: TRINO_HOST
  value: "{{ .Values.nexus.env.trino.host }}"
- name: TRINO_PORT
  value: "{{ .Values.nexus.env.trino.port }}"
- name: TRINO_CATALOG
  value: "{{ .Values.nexus.env.trino.catalog }}"
- name: TRINO_SCHEMA
  value: "{{ .Values.nexus.env.trino.schema }}"
- name: TRINO_SSL
  value: "{{ .Values.nexus.env.trino.ssl | default "false" }}"
- name: TRINO_USER
  valueFrom:
    secretKeyRef:
      name: {{ include "dashboard.fullname" . }}-trino-credentials
      key: username
- name: TRINO_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "dashboard.fullname" . }}-trino-credentials
      key: password
- name: POSTGRES_HOST
  value: "{{ .Values.nexus.env.postgres.host }}"
- name: POSTGRES_PORT
  value: "{{ .Values.nexus.env.postgres.port }}"
- name: POSTGRES_DATABASE
  value: "{{ .Values.nexus.env.postgres.database }}"
- name: POSTGRES_USER
  valueFrom:
    secretKeyRef:
      name: {{ include "dashboard.fullname" . }}-postgres-credentials
      key: username
- name: POSTGRES_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "dashboard.fullname" . }}-postgres-credentials
      key: password
{{- end }}
