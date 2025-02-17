{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "renku.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "renku.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "renku.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Define http scheme
*/}}
{{- define "http" -}}
{{- if .Values.global.useHTTPS -}}
https
{{- else -}}
http
{{- end -}}
{{- end -}}

{{/*
Define subcharts full names
*/}}
{{- define "postgresql.fullname" -}}
{{- if not .Values.global.externalServices.postgresql.enabled -}}
{{- printf "%s-%s" .Release.Name "postgresql" | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- .Values.global.externalServices.postgresql.host -}}
{{- end -}}
{{- end -}}

{{- define "keycloak.fullname" -}}
{{- printf "%s-%s" .Release.Name "keycloakx" | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "gitlab.fullname" -}}
{{- printf "%s-%s" .Release.Name "gitlab" | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "ui.fullname" -}}
{{- printf "%s-%s" .Release.Name "ui" | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "uiserver.fullname" -}}
{{- printf "%s-%s" .Release.Name "uiserver" | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "notebooks.fullname" -}}
{{- printf "%s-%s" .Release.Name "notebooks" | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "gateway.fullname" -}}
{{- printf "%s-%s" .Release.Name "gateway" | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "webhookService.fullname" -}}
{{- printf "%s-%s" .Release.Name "webhook-service" | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "knowledgeGraph.fullname" -}}
{{- printf "%s-%s" .Release.Name "knowledge-graph" | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "core.fullname" -}}
{{- printf "%s-%s" .Release.Name "core" | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Catch configuration errors
*/}}
{{- if .Values.global.externalServices.postgresql.enabled and .Values.postgresql.enabled -}}
fail "External PostgreSQL and Renku-bundled PostgreSQL cannot both be enabled. Please disable either global.externalServices.postgresql.enabled or postgresql.enabled"
{{- end -}}

{{- if not .Values.global.externalServices.postgresql.enabled and not .Values.postgresql.enabled -}}
fail "External PostgreSQL and Renku-bundled PostgreSQL cannot both be disabled. Please enable either global.externalServices.postgresql.enabled or postgresql.enabled"
{{- end -}}

{{- if .Values.global.externalServices.postgresql.enabled and .Values.global.externalServices.postgresql.password and .Values.global.externalServices.postgresql.existingSecret -}}
fail "External PostgreSQL password and existing Secret fields cannot both be populated."
{{- end -}}

{{- define "keycloak.admin-secret" -}}
{{- $secretAdmin := lookup "v1" "Secret" .Release.Namespace "keycloak-password-secret" -}}
{{- if $secretAdmin -}}
{{- if $secretAdmin.data.KEYCLOAK_ADMIN -}}
# Post-keycloakx
KEYCLOAK_ADMIN: {{ $secretAdmin.data.KEYCLOAK_ADMIN | quote }}
KEYCLOAK_ADMIN_PASSWORD: {{ $secretAdmin.data.KEYCLOAK_ADMIN_PASSWORD | quote }}
{{- else -}}
# Pre-keycloakx
KEYCLOAK_ADMIN: {{ $secretAdmin.data.KEYCLOAK_USER | quote }}
KEYCLOAK_ADMIN_PASSWORD: {{ $secretAdmin.data.KEYCLOAK_PASSWORD | quote }}
{{- end -}}
# No pre-existing secret
{{- else -}}
KEYCLOAK_ADMIN: {{ .Values.global.keycloak.user | b64enc }}
KEYCLOAK_ADMIN_PASSWORD: {{ default (randAlphaNum 64) .Values.global.keycloak.password.value | b64enc }}
{{- end -}}
{{- end -}}

{{- define "keycloak.postgres-secret" -}}
{{- $secretPostgres := lookup "v1" "Secret" .Release.Namespace "renku-keycloak-postgres" -}}
{{- if $secretPostgres -}}
{{- if $secretPostgres.data.KC_DB_URL_HOST -}}
# Post-keycloakx
KC_DB_URL_HOST: {{ $secretPostgres.data.KC_DB_URL_HOST | quote }}
KC_DB_URL_DATABASE: {{ $secretPostgres.data.KC_DB_URL_DATABASE | quote }}
KC_DB_USERNAME: {{ $secretPostgres.data.KC_DB_USERNAME | quote }}
KC_DB_PASSWORD: {{ $secretPostgres.data.KC_DB_PASSWORD | quote }}
{{- else -}}
# Pre-keycloakx
KC_DB_URL_HOST: {{ $secretPostgres.data.DB_ADDR | quote }}
KC_DB_URL_DATABASE: {{ $secretPostgres.data.DB_DATABASE | quote }}
KC_DB_USERNAME: {{ $secretPostgres.data.DB_USER | quote }}
KC_DB_PASSWORD: {{ $secretPostgres.data.DB_PASSWORD | quote }}
{{- end -}}
# No pre-existing secret
{{- else -}}
KC_DB_URL_HOST: {{ (include "postgresql.fullname" .) | b64enc | quote }}
KC_DB_URL_DATABASE: {{ .Values.global.keycloak.postgresDatabase | b64enc | quote }}
KC_DB_USERNAME: {{ .Values.global.keycloak.postgresUser | b64enc | quote }}
KC_DB_PASSWORD: {{ default (randAlphaNum 64) .Values.global.keycloak.postgresPassword.value | b64enc | quote }}
{{- end -}}
{{- end -}}
