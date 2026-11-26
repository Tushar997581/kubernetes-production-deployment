# Kubernetes Production Deployment – DevOps Task Manager

A containerized task management application deployed on Kubernetes using Docker, Minikube, Flask and PostgreSQL.

This project demonstrates practical DevOps skills, including containerization, Kubernetes orchestration, persistent storage, health monitoring, autoscaling, rolling updates and application security.

## Project Architecture

```text
                  Developer
                      |
                 Docker Desktop
                      |
                   Minikube
                      |
                Kubernetes Cluster
                      |
             NGINX Ingress / Service
                      |
             Task Manager Application
                (2 replicas)
                      |
               PostgreSQL Service
                      |
              PostgreSQL Database
                      |
             Persistent Volume Claim
```

See [Architecture Documentation](docs/architecture.md) for details.

## Technology Stack

| Category | Technologies |
|---|---|
| Application | Python, Flask |
| Database | PostgreSQL 16 |
| Containerization | Docker |
| Orchestration | Kubernetes |
| Local Cluster | Minikube |
| Networking | Kubernetes Services, NGINX Ingress |
| Storage | PersistentVolumeClaim |
| Autoscaling | Horizontal Pod Autoscaler |
| Monitoring | Prometheus client metrics |
| Automation | PowerShell |
| Configuration | ConfigMaps, Secrets, YAML |

## Key Features

- Flask-based Task Manager REST API.
- PostgreSQL database integration.
- Docker container running as a non-root user.
- Kubernetes Deployment with two application replicas.
- PostgreSQL Deployment and persistent volume.
- Kubernetes Services for application and database communication.
- NGINX Ingress configuration.
- Startup, readiness and liveness probes.
- Horizontal Pod Autoscaler (2–5 replicas).
- Pod Disruption Budget.
- ConfigMaps and Kubernetes Secrets.
- Network Policies for application and database traffic.
- Prometheus metrics endpoint.
- PowerShell scripts for setup, deployment, verification and cleanup.

## Repository Structure

```text
kubernetes-production-deployment/
|
├── app/
│   ├── app.py
│   ├── requirements.txt
│   └── templates/
│       └── index.html
|
├── docs/
│   ├── architecture.md
│   ├── deployment-guide.md
│   └── troubleshooting.md
|
├── k8s/
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── postgres.yaml
│   ├── postgres-service.yaml
│   ├── ingress.yaml
│   ├── hpa.yaml
│   ├── pdb.yaml
│   ├── network-policy.yaml
│   ├── postgres-network-policy.yaml
│   ├── kustomization.yaml
│   ├── secret.example.yaml
│   └── postgres-secret.example.yaml
|
├── scripts/
│   ├── setup-minikube.ps1
│   ├── deploy.ps1
│   ├── verify.ps1
│   └── cleanup.ps1
|
├── Dockerfile
├── .dockerignore
├── .gitignore
├── LICENSE
└── README.md
```

## Prerequisites

Install:

- Docker Desktop
- Kubernetes kubectl
- Minikube
- Git
- Windows PowerShell 5.1 or PowerShell 7

Start Docker Desktop before deploying.

## Deployment Guide

### 1. Clone the repository

```powershell
git clone <YOUR_GITHUB_REPOSITORY_URL>
cd kubernetes-production-deployment
```

Replace the placeholder with your actual repository URL.

### 2. Configure Kubernetes Secrets

Create local Secret files:

```powershell
Copy-Item .\k8s\secret.example.yaml .\k8s\secret.yaml
Copy-Item .\k8s\postgres-secret.example.yaml .\k8s\postgres-secret.yaml
```

Edit both files and replace the example credentials with your own values.

Keep the PostgreSQL database name and username consistent with the application configuration.

Never commit the local Secret files. Only commit the example templates.

### 3. Configure PowerShell

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
```

### 4. Start Minikube

```powershell
.\scripts\setup-minikube.ps1
```

### 5. Deploy the application

```powershell
.\scripts\deploy.ps1
```

### 6. Access the application

Run this command in a separate PowerShell terminal:

```powershell
kubectl port-forward -n devops svc/taskmanager 8081:80
```

Keep the terminal running.

Open:

http://127.0.0.1:8081

### 7. Verify deployment

```powershell
.\scripts\verify.ps1
```

For more detailed instructions, see [Deployment Guide](docs/deployment-guide.md).

## API Endpoints

| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/api/tasks` | List tasks |
| POST | `/api/tasks` | Create a task |
| PATCH | `/api/tasks/<id>` | Update task status |
| GET | `/health/live` | Liveness check |
| GET | `/health/ready` | Database readiness check |
| GET | `/info` | Application information |
| GET | `/metrics` | Prometheus metrics |

Example API request:

```powershell
Invoke-RestMethod http://127.0.0.1:8081/api/tasks
```

## Verification and Testing

The following have been tested in the local Minikube environment:

- Application Pods running successfully.
- PostgreSQL connectivity and readiness checks.
- Task creation and retrieval through the REST API.
- PostgreSQL data persistence after Pod recreation.
- Application Pod self-healing.
- Horizontal Pod Autoscaler metrics.
- Rolling update and rollback.
- Ingress routing through the NGINX controller port-forward.

## Security and Lab Limitations

- Demo credentials are for local learning only. Replace them before using the project elsewhere.
- Kubernetes Secret data should not be treated as encrypted merely because it is base64-encoded.
- Network Policy enforcement depends on the cluster's CNI implementation.
- Minikube is a single-node local Kubernetes environment, not a production cluster.
- Application metrics are exposed, but a complete Prometheus and Grafana monitoring stack is not installed by default.
- Resource availability depends on the resources allocated to Docker Desktop and Minikube.

## Future Improvements

- Add Jenkins-based CI/CD automation.
- Integrate SonarQube for code quality.
- Add container image vulnerability scanning with Trivy.
- Deploy Prometheus and Grafana.
- Add automated integration tests.
- Extend deployment to a managed Kubernetes environment.

## License

This project is licensed under the MIT License.
