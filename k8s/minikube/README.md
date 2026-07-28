# Minikube Setup Documentation

> [Kubernetes and OpenShift overview](../README.md) ·
> [WSL/Linux setup](minikube-setup-linux.md) ·
> [Windows 10 setup](minikube-setup-windows10.md)

## Overview

This project runs a 3-tier IoT monitoring app on Kubernetes (Minikube for local dev):

```
Browser
  └── NodePort Service (port 30080)
        └── Frontend Pod (nginx)
              └── ClusterIP Service (backend-service:80)
                    └── Backend Pod (Spring Boot :8080)
                          └── ClusterIP Service (database-service:3306)
                                └── Database Pod (MySQL :3306)
```

---

## Files

| File | Purpose |
|---|---|
| `backend-deployment.yaml` | Deploys backend Spring Boot app |
| `backend-service.yaml` | ClusterIP service for backend (port 80 → 8080) |
| `database-deployment.yaml` | Deploys MySQL database |
| `database-service.yaml` | ClusterIP service for database (port 3306) |
| `frontend-deployment.yaml` | Deploys frontend nginx app |
| `frontend-service.yaml` | NodePort service, exposes frontend on port 30080 |

---

## Prerequisites

- Minikube installed and running (`minikube start`)
- Images built and pushed to Docker Hub (`./build.sh nabil0412`)

---

## Deploying

Apply all yamls at once from the project root:

```powershell
minikube kubectl -- apply -f k8s/
```

---

## Checking Status

```powershell
# Check all pods are Running
minikube kubectl -- get pods

# Check services
minikube kubectl -- get services

# Get frontend URL
minikube service frontend-service --url
```

---

## Viewing Logs

```powershell
minikube kubectl -- logs deployment/backend-deployment
minikube kubectl -- logs deployment/frontend-deployment
minikube kubectl -- logs deployment/database-deployment
```

To follow logs in real time:
```powershell
minikube kubectl -- logs deployment/backend-deployment -f
```

---

## Redeploying After a Code Change

1. Bump the image tag in `build.sh` (e.g. `v1.4` → `v1.5`)
2. Build and push in WSL:
   ```bash
   cd /mnt/d/DXC/Code-fresh && ./build.sh nabil0412
   ```
3. Update the image tag in the relevant deployment yaml
4. Apply in PowerShell:
   ```powershell
   minikube kubectl -- apply -f k8s/<changed-deployment>.yaml
   ```

---

## Known Configuration Changes Made for Kubernetes

| File | Change | Reason |
|---|---|---|
| `application.properties` | `db-container` → `database-service` | Kubernetes uses service names not container names |
| `nginx.conf` | `backend-container` → `backend-service.default.svc.cluster.local:80` | Same reason; port changed to match ClusterIP service port |
| `nginx.conf` | resolver changed from `127.0.0.11` to `10.96.0.10` | Docker DNS resolver doesn't exist in Kubernetes |
| `SecurityConfig.java` | `List.of(allowedOrigins)` → `List.of(allowedOrigins.split(","))` | Allows comma-separated CORS origins |
| `database-deployment.yaml` | Added `MYSQL_ROOT_PASSWORD` env var | MySQL requires password on first init |
| `backend-deployment.yaml` | Added `CORS_ALLOWED_ORIGINS` env var | Allows requests from Minikube IP |
