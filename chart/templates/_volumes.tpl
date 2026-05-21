{{/*
Common volume mounts for IntelOwl application services
*/}}
{{- define "intelowl.commonVolumeMounts" -}}
{{- if .Values.storage.localStorage }}
- name: generic-logs
  mountPath: /var/log/intel_owl
- name: shared-files
  mountPath: /opt/deploy/intel_owl/files
{{- end }}
{{- include "intelowl.authVolumeMounts" . }}
{{- end }}

{{/*
Common volumes for IntelOwl application services
*/}}
{{- define "intelowl.commonVolumes" -}}
{{- if .Values.storage.localStorage }}
- name: generic-logs
  persistentVolumeClaim:
    claimName: {{ include "intelowl.fullname" . }}-generic-logs
- name: shared-files
  persistentVolumeClaim:
    claimName: {{ include "intelowl.fullname" . }}-shared-files
{{- end }}
{{- include "intelowl.authVolumes" . }}
{{- end }}

{{/*
Auth config volume mounts (LDAP / RADIUS Python files)
*/}}
{{- define "intelowl.authVolumeMounts" -}}
{{- if .Values.auth.ldap.enabled }}
- name: ldap-config
  mountPath: /opt/deploy/intel_owl/configuration/ldap_config.py
  subPath: ldap_config.py
  readOnly: true
{{- end }}
{{- if .Values.auth.radius.enabled }}
- name: radius-config
  mountPath: /opt/deploy/intel_owl/configuration/radius_config.py
  subPath: radius_config.py
  readOnly: true
{{- end }}
{{- end }}

{{/*
Auth config volumes (LDAP / RADIUS ConfigMaps)
*/}}
{{- define "intelowl.authVolumes" -}}
{{- if .Values.auth.ldap.enabled }}
- name: ldap-config
  configMap:
    name: {{ .Values.auth.ldap.existingConfigMap | default (printf "%s-ldap-config" (include "intelowl.fullname" .)) }}
{{- end }}
{{- if .Values.auth.radius.enabled }}
- name: radius-config
  configMap:
    name: {{ .Values.auth.radius.existingConfigMap | default (printf "%s-radius-config" (include "intelowl.fullname" .)) }}
{{- end }}
{{- end }}

{{/*
Static volume mounts for Nginx
*/}}
{{- define "intelowl.staticVolumeMounts" -}}
{{- if .Values.storage.localStorage }}
- name: static-content
  mountPath: /var/www/static
{{- end }}
{{- end }}

{{/*
Static volumes for Nginx
*/}}
{{- define "intelowl.staticVolumes" -}}
{{- if .Values.storage.localStorage }}
- name: static-content
  persistentVolumeClaim:
    claimName: {{ include "intelowl.fullname" . }}-static-content
{{- end }}
{{- end }}

{{/*
Storage class for PVCs
*/}}
{{- define "intelowl.storageClass" -}}
{{- if .storageClass }}
storageClassName: {{ .storageClass | quote }}
{{- end }}
{{- end }}
