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
minikube start --driver=docker --ports=30080:30080
```

No Hyper-V, no Windows admin rights needed — this reuses the same Docker Desktop daemon `docker compose` and `build.sh` already talk to.

The `--ports=30080:30080` flag publishes that port on the underlying `minikube` container itself (like `docker run -p 30080:30080` would), so Docker Desktop forwards it straight through to Windows `localhost` — see step 8 for why this matters. It can only be set when the container is created, so if you ever need to add it to an existing cluster, you must `minikube delete` first and start fresh with the flag.

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

```bash
curl -I http://localhost:30080   # sanity check from WSL — expect 200
```

Then open `http://localhost:30080` directly in your Windows browser.

This works because the cluster was started with `--ports=30080:30080` (step 3), which publishes that port on the `minikube` container. Docker Desktop forwards published container ports through to Windows `localhost` automatically. Confirm the mapping any time with:

```bash
docker port minikube
# should include: 30080/tcp -> 0.0.0.0:30080
```

Caveat: this mapping is baked in at cluster creation. If you ever `minikube delete`, you must recreate with `--ports=30080:30080` again — see step 3.

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

## 10. After restarting your computer or Docker Desktop

Minikube does **not** auto-start on boot, and Docker Desktop restarting (including an unattended background restart) leaves the minikube node container stopped.

```bash
cd /mnt/d/DXC/Code-fresh
minikube start
kubectl get pods
```

If any pod shows `Error`/`CrashLoopBackOff` right after `minikube start`, it's most likely CoreDNS not being ready yet when the frontend's nginx tried to resolve `backend-service.default.svc.cluster.local` at startup — nginx treats that as fatal and exits instead of retrying. Confirm with:

```bash
kubectl logs <frontend-pod-name> --previous
# look for: nginx: [emerg] host not found in upstream "backend-service..."
```

Fix: wait for CoreDNS to be `Running`/`Ready` (`kubectl get pods -n kube-system`), then delete the crashed pod so the Deployment recreates it:

```bash
kubectl delete pod <frontend-pod-name>
```

The port mapping from `--ports=30080:30080` survives restarts (it's part of the container config, not a running process), so `http://localhost:30080` should work again with nothing to re-establish — see step 8.
