{{/*
Scheduling shared by all integration pods.
*/}}
{{- define "intelowl.integrationsScheduling" -}}
{{- with .Values.integrations.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.integrations.tolerations }}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.integrations.affinity }}
affinity:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}
