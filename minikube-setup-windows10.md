# Minikube Setup Commands (Windows 10, Hyper-V driver)

> See [minikube-setup-linux.md](minikube-setup-linux.md) for the WSL/Linux (docker driver) variant.

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
Images pushed (latest: v1.6):
- `nabil0412/database-service:v1.5`
- `nabil0412/backend-service:v1.5`
- `nabil0412/frontend-service:v1.6`

## 7. Apply Kubernetes yamls

> ⚠️ `k8s/database-secret.yaml` is gitignored and must be created manually before deploying.
> It contains the MySQL root password — never commit it.

Apply in this order:
```powershell
minikube kubectl -- apply -f k8s/database-secret.yaml
minikube kubectl -- apply -f k8s/backend-configmap.yaml
minikube kubectl -- apply -f k8s/database-pvc.yaml
minikube kubectl -- apply -f k8s/database-deployment.yaml
minikube kubectl -- apply -f k8s/database-service.yaml
minikube kubectl -- apply -f k8s/backend-deployment.yaml
minikube kubectl -- apply -f k8s/backend-service.yaml
minikube kubectl -- apply -f k8s/frontend-deployment.yaml
minikube kubectl -- apply -f k8s/frontend-service.yaml
```

Or apply everything at once (Secret must already exist):
```powershell
minikube kubectl -- apply -f k8s/
```

## 8. Check all pods are running
```powershell
minikube kubectl -- get pods
```
Expected output: all 3 pods with status `Running`

## 9. Get Minikube node IP
```powershell
minikube ip
```
Access the app at `http://<minikube-ip>:30080`

## 10. Redeploying after a code change
1. Bump the relevant image tag in `build.sh`
2. Rebuild and push in WSL:
```bash
cd /mnt/d/DXC/Code-fresh && ./build.sh nabil0412
```
3. Update the image tag in the relevant `k8s/*-deployment.yaml`
4. Apply in PowerShell:
```powershell
minikube kubectl -- apply -f k8s/<changed-deployment>.yaml
```
