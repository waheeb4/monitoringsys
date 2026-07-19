# Minikube Setup Commands

## 1. Install Minikube
```powershell
New-Item -Path 'c:\' -Name 'minikube' -ItemType Directory -Force
$ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -OutFile 'c:\minikube\minikube.exe' -Uri 'https://github.com/kubernetes/minikube/releases/latest/download/minikube-windows-amd64.exe' -UseBasicParsing
```

## 2. Add Minikube to PATH (run as Administrator)
```powershell
$oldPath = [Environment]::GetEnvironmentVariable('Path', [EnvironmentVariableTarget]::Machine)
```
```powershell
$oldPath.Split(';') -inotcontains 'C:\minikube'
```
```powershell
[Environment]::SetEnvironmentVariable('Path', $('{0};C:\minikube' -f $oldPath), [EnvironmentVariableTarget]::Machine)
```

## 3. Enable Hyper-V (run as Administrator, may require restart)
```powershell
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-Tools-All -All
```

## 4. Start Minikube
```powershell
minikube start
```

## 5. Verify cluster is running
```powershell
minikube kubectl -- get nodes
```

## 6. Build and push images to Docker Hub (run in WSL)
```bash
cd /mnt/d/DXC/Code-fresh && ./build.sh nabil0412
```
Images pushed (latest: v1.4):
- `nabil0412/database-service`
- `nabil0412/backend-service`
- `nabil0412/frontend-service`

## 7. Apply Kubernetes yamls
```powershell
cd "d:\DXC\Code-fresh"; minikube kubectl -- apply -f k8s/
```

## 8. Check all pods are running
```powershell
minikube kubectl -- get pods
```
Expected output: all 3 pods with status `Running`

## 9. Get frontend URL
```powershell
minikube service frontend-service --url
```

## 10. Redeploying after a code change
1. Bump image tag in `build.sh` (e.g. v1.4 → v1.5)
2. Rebuild and push in WSL:
```bash
cd /mnt/d/DXC/Code-fresh && ./build.sh nabil0412
```
3. Update image tag in the relevant `k8s/*.yaml` file
4. Apply in PowerShell:
```powershell
minikube kubectl -- apply -f k8s/<changed-deployment>.yaml
```
