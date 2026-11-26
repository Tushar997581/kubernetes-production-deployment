$ErrorActionPreference = "Stop"

Write-Host "`n========== CLUSTER =========="
kubectl get nodes

Write-Host "`n========== APPLICATION PODS =========="
kubectl get pods -n devops -o wide

Write-Host "`n========== DEPLOYMENTS =========="
kubectl get deployments -n devops

Write-Host "`n========== SERVICES =========="
kubectl get services -n devops

Write-Host "`n========== STORAGE =========="
kubectl get pvc -n devops

Write-Host "`n========== INGRESS / HPA / PDB =========="
kubectl get ingress,hpa,pdb -n devops

Write-Host "`n========== NETWORK POLICIES =========="
kubectl get networkpolicy -n devops

Write-Host "`n========== POSTGRESQL ROLLOUT =========="
kubectl rollout status deployment/postgres -n devops --timeout=180s

Write-Host "`n========== TASK MANAGER ROLLOUT =========="
kubectl rollout status deployment/taskmanager -n devops --timeout=180s

Write-Host "`n========== APPLICATION API CHECK =========="
Write-Host "Checking localhost:8081"
Write-Host "Make sure this command is running in another PowerShell window:"
Write-Host "kubectl port-forward -n devops svc/taskmanager 8081:80"

try {
    $health = Invoke-RestMethod http://127.0.0.1:8081/health/ready
    $info = Invoke-RestMethod http://127.0.0.1:8081/info
    $tasks = Invoke-RestMethod http://127.0.0.1:8081/api/tasks

    Write-Host "`nReadiness:"
    $health | Format-List

    Write-Host "Application info:"
    $info | Format-List

    Write-Host "Tasks returned: $(@($tasks).Count)"
    Write-Host "`nAPI verification successful."
}
catch {
    Write-Warning "API check failed. Confirm port-forward is running on port 8081."
    throw
}

Write-Host "`n========== VERIFICATION COMPLETE =========="
