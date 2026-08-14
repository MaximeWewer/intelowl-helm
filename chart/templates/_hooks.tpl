{{/*
Whether to order resources with Argo CD sync waves instead of Helm hooks.

Returns a non-empty string (truthy) when sync waves must be used, empty
otherwise. Use as: {{- if include "intelowl.useSyncWaves" . }}

Sync waves are required whenever Argo CD drives the deployment, and are
implied when the CNPG operator ships as a subchart (the operator must be
running before the Cluster CR reconciles, which Helm pre-install hooks
cannot express).

`argocd.enabled` is deliberately independent from
`postgresql.operator.enabled`: a cluster-wide CNPG operator with Argo CD
is a perfectly normal setup, and it used to fall back to Helm hooks.
*/}}
{{- define "intelowl.useSyncWaves" -}}
{{- $argocd := .Values.argocd | default dict -}}
{{- if or $argocd.enabled .Values.postgresql.operator.enabled -}}
true
{{- end -}}
{{- end -}}

{{/*
Install ordering annotations.

Sync-wave mode emits `argocd.argoproj.io/sync-wave`. Helm-hook mode emits
classic `helm.sh/hook` annotations so the chart still installs correctly
under plain `helm install`.

A hook is by definition deletable and recreatable, so data-bearing
resources (PVCs, the CNPG Cluster) MUST pass `phases: "pre-install"`.
Helm deletes a hook resource before recreating it (the implicit
before-hook-creation delete policy, which "helm.sh/resource-policy: keep"
does not override), so leaving them in the pre-upgrade phase destroys the
volumes and the database on every `helm upgrade`.

Under Argo CD this is not enough — Argo maps both `pre-install` and
`pre-upgrade` to PreSync and re-deletes the hook on every sync — which is
why `argocd.enabled` must be set. See "intelowl.useSyncWaves".

Usage:
  {{- include "intelowl.installOrder" (dict "ctx" . "wave" "1" "weight" "-10") | nindent 4 }}

Params:
  ctx    : root context (.)
  wave   : argocd sync-wave value (string)
  weight : helm.sh/hook-weight value (string)
  phases : (optional) hook phases, defaults to "pre-install,pre-upgrade".
           Data-bearing resources must pass "pre-install".
*/}}
{{- define "intelowl.installOrder" -}}
{{- if include "intelowl.useSyncWaves" .ctx }}
argocd.argoproj.io/sync-wave: "{{ .wave }}"
{{- else }}
"helm.sh/hook": {{ .phases | default "pre-install,pre-upgrade" }}
"helm.sh/hook-weight": "{{ .weight }}"
{{- end }}
{{- end -}}

{{/*
Sync wave only — never emits a Helm hook.

Used for two cases:
  - data-bearing resources that must never become a deletable hook
    (PVCs, the CNPG Cluster);
  - resources that only need ordering under Argo CD, where Helm's own
    install order already does the right thing (app deployments, HPAs,
    PDBs, which Helm creates after PVCs and Secrets anyway).

The annotation is inert outside Argo CD, so it is safe to always emit.
*/}}
{{- define "intelowl.syncWave" -}}
{{- if include "intelowl.useSyncWaves" .ctx }}
argocd.argoproj.io/sync-wave: "{{ .wave }}"
{{- end }}
{{- end -}}
