{{- define "mcp-stack.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{- define "mcp-stack.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := include "mcp-stack.name" . -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end }}

{{- define "mcp-stack.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" -}}
{{- end }}

{{- define "mcp-stack.componentFullname" -}}
{{- $ctx := .context -}}
{{- $component := .component -}}
{{- printf "%s-%s" (include "mcp-stack.fullname" $ctx) $component | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{- define "mcp-stack.componentLabels" -}}
{{- $ctx := .context -}}
{{- $component := .component -}}
app.kubernetes.io/name: {{ include "mcp-stack.name" $ctx }}
app.kubernetes.io/instance: {{ $ctx.Release.Name }}
app.kubernetes.io/component: {{ $component }}
app.kubernetes.io/managed-by: {{ $ctx.Release.Service }}
helm.sh/chart: {{ include "mcp-stack.chart" $ctx }}
{{- end }}

{{- define "mcp-stack.componentSelectorLabels" -}}
{{- $ctx := .context -}}
{{- $component := .component -}}
app.kubernetes.io/name: {{ include "mcp-stack.name" $ctx }}
app.kubernetes.io/instance: {{ $ctx.Release.Name }}
app.kubernetes.io/component: {{ $component }}
{{- end }}

{{- define "mcp-stack.componentSecretName" -}}
{{- $ctx := .context -}}
{{- $component := .component -}}
{{- $secret := .secret -}}
{{- if $secret.name -}}
{{- $secret.name -}}
{{- else -}}
{{- printf "%s-secret" (include "mcp-stack.componentFullname" (dict "context" $ctx "component" $component)) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end }}
