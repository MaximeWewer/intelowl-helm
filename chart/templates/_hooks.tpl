{{/*
Install ordering annotations.

When postgresql.operator.enabled=true, the CNPG operator deploys as a
subchart in the Sync phase. Helm pre-install hooks would create the
Cluster CR before the operator exists, deadlocking the install.
In that mode, emit argocd sync-wave annotations instead so resources
order via Argo waves and the operator can come up first.

When postgresql.operator.enabled=false (operator preinstalled), emit
classic helm hooks so the chart still works under plain helm.

Usage:
  {{- include "intelowl.installOrder" (dict "ctx" . "wave" "1" "weight" "-10") | nindent 4 }}

Params:
  ctx    : root context (.)
  wave   : argocd sync-wave value (string)
  weight : helm.sh/hook-weight value (string)
  keep   : (optional) if "true", keep resource across helm uninstall — only meaningful in hook mode
*/}}
{{- define "intelowl.installOrder" -}}
{{- if .ctx.Values.postgresql.operator.enabled }}
argocd.argoproj.io/sync-wave: "{{ .wave }}"
{{- else }}
"helm.sh/hook": pre-install,pre-upgrade
"helm.sh/hook-weight": "{{ .weight }}"
{{- end }}
{{- end -}}

{{/*
Sync wave only — used on resources that must run after pre-install but
have no helm hook in operator-preinstalled mode (e.g. main app deployments
that need to wait for the migration job in subchart mode).
*/}}
{{- define "intelowl.syncWave" -}}
{{- if .ctx.Values.postgresql.operator.enabled }}
argocd.argoproj.io/sync-wave: "{{ .wave }}"
{{- end }}
{{- end -}}
