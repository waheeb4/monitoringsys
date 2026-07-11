# Minikube Setup Commands (WSL / Linux, docker driver)

> See [minikube-setup-windows10.md](minikube-setup-windows10.md) for the Windows/Hyper-V variant.

This variant runs entirely inside WSL, reusing Docker Desktop's shared Docker daemon (no Hyper-V, no PowerShell). Run all commands below from your WSL terminal unless noted otherwise.

## 1. Install kubectl

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl
kubectl version --client
```

## 2. Install minikube

```bash
curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64
minikube version
```

## 3. Start minikube (docker driver)

```bash
minikube start --driver=docker
```

No Hyper-V, no Windows admin rights needed — this reuses the same Docker Desktop daemon `docker compose` and `build.sh` already talk to.

## 4. Verify cluster is running

```bash
kubectl get nodes
```

## 5. Build and push images to Docker Hub

```bash
cd /mnt/d/DXC/Code-fresh && ./build.sh nabil0412
```

## 6. Apply Kubernetes yamls

> ⚠️ `k8s/database-secret.yaml` is gitignored and must be created manually before deploying.
> It contains the MySQL root password — never commit it.

```bash
kubectl apply -f k8s/database-secret.yaml
kubectl apply -f k8s/
```

## 7. Check all pods are running

```bash
kubectl get pods
```
Expected output: all pods with status `Running`.

## 8. Access the app

With the docker driver, `minikube ip` + NodePort isn't always directly reachable — use the service tunnel instead:

```bash
minikube service frontend-service --url
```

This prints a URL (e.g. `http://127.0.0.1:xxxxx`) that proxies to the frontend NodePort. Keep the command running in a terminal while you use the app, or run it with `&` to background it.

## 9. Redeploying after a code change

1. Rebuild and push:
   ```bash
   cd /mnt/d/DXC/Code-fresh && ./build.sh nabil0412
   ```
2. Make sure `imagePullPolicy: Always` is set on the deployment (already the case in this repo's `k8s/*.yaml` — needed because `build.sh` reuses fixed tags, so without it a `rollout restart` would just reuse the stale local image).
3. Apply and restart:
   ```bash
   kubectl apply -f k8s/
   kubectl rollout restart deployment/backend-deployment
   kubectl rollout restart deployment/frontend-deployment
   ```
