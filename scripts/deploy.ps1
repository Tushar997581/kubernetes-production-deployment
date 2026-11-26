$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

Write-Host "Checking prerequisites..."

foreach ($tool in @("docker", "kubectl")) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        throw "$tool is not installed or not on PATH."
    }
}

$MinikubeCommand = Get-Command minikube -ErrorAction SilentlyContinue

if ($MinikubeCommand) {
    $MinikubeExe = $MinikubeCommand.Source
}
elseif (Test-Path "C:\Program Files\Kubernetes\Minikube\minikube.exe") {
    $MinikubeExe = "C:\Program Files\Kubernetes\Minikube\minikube.exe"
}
else {
    throw "Minikube executable not found."
}

docker info | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "Start Docker Desktop first."
}

& $MinikubeExe status
if ($LASTEXITCODE -ne 0) {
    throw "Minikube is not running. Run .\scripts\setup-minikube.ps1 first."
}

foreach ($secret in @(".\k8s\secret.yaml", ".\k8s\postgres-secret.yaml")) {
    if (-not (Test-Path $secret)) {
        throw "Missing local Secret file: $secret. Copy its .example.yaml template and configure it first."
    }
}

$Image = "taskmanager-api:v3"

Write-Host ""
Write-Host "Building application image: $Image"

& $MinikubeExe image build -t $Image .
if ($LASTEXITCODE -ne 0) {
    throw "Application image build failed."
}

Write-Host ""
Write-Host "Applying Kubernetes manifests..."

kubectl apply -k .\k8s\
if ($LASTEXITCODE -ne 0) {
    throw "Kubernetes manifest application failed."
}

Write-Host ""
Write-Host "Waiting for PostgreSQL..."

kubectl rollout status deployment/postgres -n devops --timeout=180s
if ($LASTEXITCODE -ne 0) {
    throw "PostgreSQL rollout failed."
}

Write-Host ""
Write-Host "Waiting for Task Manager..."

kubectl rollout status deployment/taskmanager -n devops --timeout=180s
if ($LASTEXITCODE -ne 0) {
    throw "Task Manager rollout failed."
}

Write-Host ""
Write-Host "Deployment resources:"
kubectl get pods,svc,pvc,ingress,hpa,pdb -n devops

Write-Host ""
Write-Host "Deployment completed successfully."
Write-Host "Use .\scripts\verify.ps1 to verify the application."
