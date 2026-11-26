# Deployment Guide

This guide explains how to deploy the DevOps Task Manager application locally using Docker Desktop, Minikube and Kubernetes.

## 1. Prerequisites

Install the following tools:

- Docker Desktop
- kubectl
- Minikube
- Git
- Windows PowerShell 5.1 or PowerShell 7

Start Docker Desktop before continuing.

## 2. Clone the Repository

Clone your GitHub repository:

```powershell
git clone <YOUR_GITHUB_REPOSITORY_URL>
cd kubernetes-production-deployment
```

Replace the placeholder URL with your actual GitHub repository URL.

## 3. Configure Kubernetes Secrets

Create local Secret files from the example templates:

```powershell
Copy-Item .\k8s\secret.example.yaml .\k8s\secret.yaml
Copy-Item .\k8s\postgres-secret.example.yaml .\k8s\postgres-secret.yaml
```

Edit both local files and replace placeholder values with your own values.

The PostgreSQL database name and username must match the application configuration.

**Important:** Never commit `secret.yaml` or `postgres-secret.yaml` to GitHub. These files are excluded through `.gitignore`. Only the example templates should be committed.

## 4. Configure PowerShell

Allow scripts to run in the current PowerShell session:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
```

This does not permanently change the system execution policy.

## 5. Start Minikube

Make sure Docker Desktop is running, then execute:

```powershell
.\scripts\setup-minikube.ps1
```

The script checks the local environment and starts Minikube if required.

## 6. Deploy the Application

Build the application image and deploy the Kubernetes resources:

```powershell
.\scripts\deploy.ps1
```

The deployment includes:

- Task Manager application
- PostgreSQL database
- Kubernetes Services
- ConfigMaps and Secrets
- Persistent Volume Claim
- Ingress
- Horizontal Pod Autoscaler
- Pod Disruption Budget
- Network Policies

## 7. Access the Application

Open a separate PowerShell terminal and run:

```powershell
kubectl port-forward -n devops svc/taskmanager 8081:80
```

Keep this terminal open.

Open the application API in your browser:

http://127.0.0.1:8081

Health check:

http://127.0.0.1:8081/health/ready

Application information:

http://127.0.0.1:8081/info

Prometheus metrics endpoint:

http://127.0.0.1:8081/metrics

## 8. Verify the Deployment

In the project terminal, run:

```powershell
.\scripts\verify.ps1
```

You can also inspect Kubernetes resources manually:

```powershell
kubectl get nodes
kubectl get pods -n devops
kubectl get deployments -n devops
kubectl get services -n devops
kubectl get pvc -n devops
kubectl get hpa -n devops
kubectl get ingress -n devops
```

## 9. Test the API

List tasks:

```powershell
Invoke-RestMethod http://127.0.0.1:8081/api/tasks
```

Create a task:

```powershell
$body = @{
    title = "Practice Kubernetes"
} | ConvertTo-Json

Invoke-RestMethod -Uri http://127.0.0.1:8081/api/tasks -Method Post -ContentType "application/json" -Body $body
```

## 10. Useful Kubernetes Commands

View application logs:

```powershell
kubectl logs -n devops deployment/taskmanager
```

Describe application Pods:

```powershell
kubectl describe pods -n devops -l app=taskmanager
```

Check rollout status:

```powershell
kubectl rollout status deployment/taskmanager -n devops
```

Restart the application:

```powershell
kubectl rollout restart deployment/taskmanager -n devops
```

Check resource usage:

```powershell
kubectl top pods -n devops
kubectl top nodes
```

## 11. Cleanup

The cleanup script asks for explicit confirmation before deleting the application namespace:

```powershell
.\scripts\cleanup.ps1
```

**Warning:** Deleting the namespace also deletes its Persistent Volume Claim and may permanently remove the PostgreSQL data stored in that claim.

Do not run cleanup unless you intentionally want to remove the project deployment and its data.

## 12. Important Notes

- This project is a local Kubernetes learning and portfolio environment.
- Minikube runs a single-node Kubernetes cluster.
- PostgreSQL uses persistent storage through a PVC.
- Network Policy enforcement depends on the Kubernetes networking implementation.
- Prometheus metrics are exposed by the application, but a Prometheus/Grafana monitoring stack is not installed by default.
- Replace demo credentials before using this project outside a local learning environment.

