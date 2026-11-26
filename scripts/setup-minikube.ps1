$ErrorActionPreference = "Stop"

Write-Host "Checking required tools..."

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
    throw "Minikube executable not found. Install Minikube first."
}

docker info | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "Docker Desktop is not running. Start Docker Desktop first."
}

Write-Host "Checking Minikube status..."

& $MinikubeExe status 2>$null | Out-Null

if ($LASTEXITCODE -ne 0) {
    Write-Host "Starting Minikube with Docker driver..."
    & $MinikubeExe start --driver=docker --cpus=4 --memory=3072

    if ($LASTEXITCODE -ne 0) {
        throw "Minikube failed to start."
    }
}
else {
    Write-Host "Minikube cluster already exists."
}

Write-Host "Enabling required addons..."

& $MinikubeExe addons enable ingress
if ($LASTEXITCODE -ne 0) { throw "Failed to enable Ingress addon." }

& $MinikubeExe addons enable metrics-server
if ($LASTEXITCODE -ne 0) { throw "Failed to enable metrics-server addon." }

kubectl get nodes

Write-Host ""
Write-Host "Cluster setup completed."
Write-Host "Next run: .\scripts\deploy.ps1"
