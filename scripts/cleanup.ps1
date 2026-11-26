$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "WARNING: This removes the DevOps Task Manager namespace."
Write-Host "PostgreSQL PVC and stored task data will also be deleted."
Write-Host ""

$confirmation = Read-Host "Type DELETE to permanently remove the project and its data"

if ($confirmation -ne "DELETE") {
    Write-Host "Cleanup cancelled. Nothing was deleted."
    exit 0
}

kubectl delete namespace devops --wait=true

Write-Host ""
Write-Host "Project namespace deleted."
Write-Host "Minikube cluster remains available."
