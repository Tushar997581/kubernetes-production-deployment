# Architecture

## Overview

The DevOps Task Manager is a containerized Flask application deployed on a local Kubernetes cluster using Minikube.

It uses PostgreSQL for persistent task storage and NGINX Ingress for HTTP routing.

## Architecture Flow

Browser / API Client
        |
        v
NGINX Ingress Controller
        |
        v
Task Manager ClusterIP Service
        |
        v
Task Manager Deployment
        |
        +---- Flask Application Pod 1
        |
        +---- Flask Application Pod 2
                    |
                    v
              PostgreSQL Service
                    |
                    v
              PostgreSQL Pod
                    |
                    v
              Persistent Volume Claim
                    |
                    v
              Persistent Storage

## Components

### Application
- Python Flask REST API.
- Gunicorn application server.
- PostgreSQL database integration.
- Prometheus metrics endpoint at `/metrics`.
- Health endpoints for Kubernetes probes.

### Containerization
- Docker image: `taskmanager-api:v3`.
- Python 3.12 slim base image.
- Runs as a non-root user.
- Application dependencies installed through requirements.txt.

### Kubernetes
- Minikube single-node cluster.
- Task Manager Deployment with two replicas.
- PostgreSQL Deployment with one replica.
- ClusterIP Services for internal communication.
- NGINX Ingress for HTTP routing.
- ConfigMap for non-sensitive configuration.
- Kubernetes Secrets for credentials.
- Startup, readiness and liveness probes.
- CPU-based HPA targeting 60% utilization, with 2-5 replicas.
- PodDisruptionBudget with minimum one available application Pod.
- NetworkPolicies for application and database traffic.
- PersistentVolumeClaim for PostgreSQL data.

### Database
- PostgreSQL 16 Alpine.
- Database: `taskmanager`.
- Persistent storage: 1 GiB PVC.
- Application connects using Kubernetes Service DNS.

## Security

- Application container runs as non-root.
- Root filesystem is read-only.
- Linux capabilities are dropped.
- Privilege escalation is disabled.
- Secrets are excluded from Git.
- NetworkPolicies restrict intended application and database traffic.

NetworkPolicy enforcement depends on the Kubernetes networking implementation.

## Monitoring

- Prometheus-compatible metrics exposed at `/metrics`.
- Kubernetes metrics-server supports HPA resource metrics.
- Prometheus and Grafana installation is optional and not included in the verified deployment.

## Deployment Verification

The following have been tested in the local Minikube environment:

- Application and PostgreSQL Pods reach Running state.
- Application readiness and liveness endpoints respond successfully.
- Task creation and retrieval through REST API.
- Task data persists after PostgreSQL Pod recreation.
- Application Pod self-healing.
- HPA metrics availability.
- Rolling update and rollback.
- Ingress HTTP routing verified through port-forwarding to the Ingress controller.
- PostgreSQL PVC remains Bound.

## Environment Limitations

This is a local single-node Kubernetes portfolio lab, not a multi-node production cluster.

Direct access to the Minikube IP from Windows may depend on the Docker driver networking configuration.
