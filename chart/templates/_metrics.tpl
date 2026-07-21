{{/*
Per-component metrics switches.
Each returns a non-empty string when the component exporter must be rendered.
*/}}
{{- define "intelowl.metrics.uwsgi.enabled" -}}
{{- if and .Values.metrics.enabled .Values.metrics.uwsgi.enabled -}}true{{- end -}}
{{- end }}

{{- define "intelowl.metrics.nginx.enabled" -}}
{{- if and .Values.metrics.enabled .Values.metrics.nginx.enabled -}}true{{- end -}}
{{- end }}

{{- define "intelowl.metrics.flower.enabled" -}}
{{- if and .Values.metrics.enabled .Values.metrics.flower.enabled .Values.flower.enabled -}}true{{- end -}}
{{- end }}

{{- define "intelowl.metrics.celery.enabled" -}}
{{- if and .Values.metrics.enabled .Values.metrics.celery.enabled -}}true{{- end -}}
{{- end }}

{{- define "intelowl.metrics.elasticsearch.enabled" -}}
{{- if and .Values.metrics.enabled .Values.metrics.elasticsearch.enabled .Values.elasticsearch.enabled -}}true{{- end -}}
{{- end }}

{{/*
Annotations for annotation-based Prometheus discovery.
Usage: include "intelowl.metrics.podAnnotations" (dict "port" 9117)
*/}}
{{- define "intelowl.metrics.podAnnotations" -}}
prometheus.io/scrape: "true"
prometheus.io/port: {{ .port | quote }}
prometheus.io/path: "/metrics"
{{- end }}

{{/*
uWSGI exporter sidecar. IntelOwl exposes no /metrics route, so the exporter
translates the uWSGI stats server (stats-http on :9191) into Prometheus metrics.
*/}}
{{- define "intelowl.metrics.uwsgiSidecar" -}}
- name: uwsgi-exporter
  image: "{{ .Values.metrics.uwsgi.image.repository }}:{{ .Values.metrics.uwsgi.image.tag }}"
  imagePullPolicy: {{ .Values.metrics.uwsgi.image.pullPolicy }}
  {{- with .Values.containerSecurityContext }}
  securityContext:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  args:
    - --stats.uri=http://127.0.0.1:9191
    - --web.listen-address=:{{ .Values.metrics.uwsgi.port }}
    {{- with .Values.metrics.uwsgi.extraArgs }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  ports:
    - name: metrics
      containerPort: {{ .Values.metrics.uwsgi.port }}
      protocol: TCP
  livenessProbe:
    httpGet:
      path: /metrics
      port: metrics
    initialDelaySeconds: 15
    periodSeconds: 30
  readinessProbe:
    httpGet:
      path: /metrics
      port: metrics
    initialDelaySeconds: 5
    periodSeconds: 15
  resources:
    {{- toYaml .Values.metrics.uwsgi.resources | nindent 4 }}
{{- end }}

{{/*
Nginx exporter sidecar, scraping the stub_status vhost bound to localhost.
*/}}
{{- define "intelowl.metrics.nginxSidecar" -}}
- name: nginx-exporter
  image: "{{ .Values.metrics.nginx.image.repository }}:{{ .Values.metrics.nginx.image.tag }}"
  imagePullPolicy: {{ .Values.metrics.nginx.image.pullPolicy }}
  securityContext:
    allowPrivilegeEscalation: false
    runAsNonRoot: true
    runAsUser: 65534
    capabilities:
      drop:
        - ALL
  args:
    - --nginx.scrape-uri=http://127.0.0.1:{{ .Values.metrics.nginx.statusPort }}/stub_status
    - --web.listen-address=:{{ .Values.metrics.nginx.port }}
    {{- with .Values.metrics.nginx.extraArgs }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  ports:
    - name: metrics
      containerPort: {{ .Values.metrics.nginx.port }}
      protocol: TCP
  livenessProbe:
    httpGet:
      path: /metrics
      port: metrics
    initialDelaySeconds: 15
    periodSeconds: 30
  readinessProbe:
    httpGet:
      path: /metrics
      port: metrics
    initialDelaySeconds: 5
    periodSeconds: 15
  resources:
    {{- toYaml .Values.metrics.nginx.resources | nindent 4 }}
{{- end }}

{{/*
Secret holding the Flower credentials used to scrape its protected /metrics endpoint.
*/}}
{{- define "intelowl.metrics.flowerSecretName" -}}
{{- if .Values.metrics.flower.basicAuth.secretName }}
{{- .Values.metrics.flower.basicAuth.secretName }}
{{- else if .Values.flower.auth.existingSecret }}
{{- .Values.flower.auth.existingSecret }}
{{- else }}
{{- printf "%s-app-secrets" (include "intelowl.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Common ServiceMonitor endpoint settings.
*/}}
{{- define "intelowl.metrics.endpointDefaults" -}}
{{- $sm := .Values.metrics.serviceMonitor }}
interval: {{ $sm.interval }}
scrapeTimeout: {{ $sm.scrapeTimeout }}
{{- if $sm.honorLabels }}
honorLabels: true
{{- end }}
{{- with $sm.relabelings }}
relabelings:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $sm.metricRelabelings }}
metricRelabelings:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}
