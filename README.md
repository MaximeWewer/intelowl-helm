# IntelOwl Helm Chart

Unofficial Helm chart for deploying [IntelOwl](https://github.com/intelowlproject/IntelOwl) on Kubernetes.

> **IntelOwl** is an open-source intelligence (OSINT) management platform that automates the collection and analysis of threat intelligence data from a single API at scale.

> **Deployment target:** this chart is designed for [Argo CD](https://argo-cd.readthedocs.io/). When `postgresql.operator.enabled=true`, install ordering relies on `argocd.argoproj.io/sync-wave` annotations rather than Helm hooks (the CNPG operator subchart must come up before the `Cluster` CR can reconcile). Plain `helm install` still works in the `operator.enabled=false` mode (operator preinstalled), where classic Helm pre/post-install hooks are emitted.

## Quick Start (Argo CD)

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: intelowl
  namespace: argocd
spec:
  project: default
  source:
    repoURL: ghcr.io/maximewewer/charts
    chart: intelowl
    targetRevision: "6.6.1-12-05-2026-2"
    helm:
      values: |
        postgresql:
          operator:
            enabled: true
  destination:
    server: https://kubernetes.default.svc
    namespace: intelowl
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
      - ServerSideApply=true
```

## Features

- Full IntelOwl deployment (Django backend, Celery workers, Nginx)
- PostgreSQL via [CloudNative-PG](https://cloudnative-pg.io/) operator
- Redis via [CloudPirates operator](https://github.com/cloudpirates/helm-charts) (broker/cache) and optional RabbitMQ via [CloudPirates operator](https://github.com/cloudpirates/helm-charts) as alternative broker
- Optional Elasticsearch integration via [ECK Operator](https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-overview.html)
- Ingress, NetworkPolicies, PodDisruptionBudgets, ServiceMonitor support
- Automated weekly version updates tracking upstream IntelOwl releases

## Prerequisites

- Kubernetes 1.25+
- Helm 3.8+
- PV provisioner with ReadWriteMany support

## Installation

### Argo CD (recommended)

The chart ships with `argocd.argoproj.io/sync-wave` annotations to order resources when the CNPG operator is deployed as a subchart. See the [Quick Start](#quick-start-argo-cd) above.

### Plain Helm (operator preinstalled)

Only when `postgresql.operator.enabled=false` (CloudNative-PG installed separately at cluster scope):

```bash
helm install intelowl oci://ghcr.io/maximewewer/charts/intelowl \
  --namespace intelowl --create-namespace \
  --set postgresql.operator.enabled=false \
  --set app.django.secretKey="$(python3 -c 'import secrets; print(secrets.token_urlsafe(50))')"
```

### From source

```bash
git clone https://github.com/MaximeWewer/intelowl-helm.git
cd intelowl-helm
helm dependency update chart/
helm install intelowl chart/ \
  --namespace intelowl --create-namespace \
  --set postgresql.operator.enabled=false \
  --set app.django.secretKey="$(python3 -c 'import secrets; print(secrets.token_urlsafe(50))')"
```

## Configuration

See the full list of configurable values in [`chart/README.md`](chart/README.md).

A minimal production example:

```yaml
app:
  django:
    secretKey: ""           # Use existingSecret in production
    existingSecret: "my-django-secret"
  baseUrl: "https://intelowl.example.com"
  httpsEnabled: true

ingress:
  enabled: true
  className: "nginx"
  hosts:
    - host: intelowl.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: intelowl-tls
      hosts:
        - intelowl.example.com

postgresql:
  operator:
    enabled: true
  instances: 2
  storage:
    size: "20Gi"
```

## License

This chart is distributed under the [Apache License 2.0](LICENSE).
