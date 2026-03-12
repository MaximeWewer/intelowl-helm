# IntelOwl Helm Chart

[![Release Helm Chart](https://github.com/MaximeWewer/intelowl-helm/actions/workflows/release-helm.yml/badge.svg)](https://github.com/MaximeWewer/intelowl-helm/actions/workflows/release-helm.yml)
[![Update Versions](https://github.com/MaximeWewer/intelowl-helm/actions/workflows/update-versions.yml/badge.svg)](https://github.com/MaximeWewer/intelowl-helm/actions/workflows/update-versions.yml)

Unofficial Helm chart for deploying [IntelOwl](https://github.com/intelowlproject/IntelOwl) on Kubernetes.

> **IntelOwl** is an open-source intelligence (OSINT) management platform that automates the collection and analysis of threat intelligence data from a single API at scale.

## Quick Start

```bash
helm install intelowl oci://ghcr.io/maximewewer/charts/intelowl
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

### From OCI registry (recommended)

```bash
helm install intelowl oci://ghcr.io/maximewewer/charts/intelowl \
  --namespace intelowl --create-namespace \
  --set app.django.secretKey="$(python3 -c 'import secrets; print(secrets.token_urlsafe(50))')"
```

### From source

```bash
git clone https://github.com/MaximeWewer/intelowl-helm.git
cd intelowl-helm
helm dependency build chart/
helm install intelowl chart/ \
  --namespace intelowl --create-namespace \
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
