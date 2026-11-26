# Troubleshooting

## ImagePullBackOff
Confirm the image exists in Minikube:
```powershell
minikube image ls | Select-String taskmanager
```
Rebuild with `minikube image build -t taskmanager-api:v1 .`, then restart:
```powershell
kubectl rollout restart deployment/taskmanager -n devops
```

## Pending Pods
```powershell
kubectl describe pod -n devops <POD_NAME>
kubectl describe nodes
```
Check CPU and memory availability.

## HPA shows unknown metrics
```powershell
kubectl get apiservices | Select-String metrics
kubectl top nodes
kubectl top pods -n devops
```
Wait for metrics-server to become ready. HPA requires resource requests, which are configured in the Deployment.

## Ingress does not resolve
Check `kubectl get ingress -n devops`, `kubectl get pods -n ingress-nginx`, and ensure the hosts file maps `taskmanager.local` to `minikube ip`.

## NetworkPolicy blocks traffic
The policy expects ingress-nginx and monitoring namespaces. Inspect namespace labels and temporarily remove the policy only for diagnosis:
```powershell
kubectl delete networkpolicy taskmanager-ingress -n devops
```
Re-apply it after fixing the namespace/selector configuration.
