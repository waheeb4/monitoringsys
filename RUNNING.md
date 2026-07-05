# Running the IoT Monitoring System

Two supported environments: **Docker Compose** (for local dev and Postman testing) and **Kubernetes via Minikube** (production-like).

> Never run both at the same time — they compete for the same ports (80 / 8080).

---

## Docker Compose

Use this when you want to run the app locally or test APIs with Postman.

### Prerequisites

Create the DB password secret file (one-time setup):

```bash
mkdir -p secrets
echo "my-pwd" > secrets/mysql_root_password.txt
```

### Start

```bash
docker compose up --build
```

- Frontend: http://localhost:80
- Backend (for Postman): http://localhost:8080

### Stop

```bash
docker compose down
```

To also wipe the database volume (forces schema re-init on next start):

```bash
docker compose down -v
```

### Rebuild after a code change

```bash
# Rebuild and restart a specific service
docker compose up --build backend
docker compose up --build frontend
docker compose up --build database
```

### How nginx works here

`docker-compose.yml` mounts `nginx.docker.conf` over the config baked into the image:

```yaml
volumes:
  - ./nginx.docker.conf:/etc/nginx/nginx.conf:ro
```

`nginx.docker.conf` uses Docker's internal DNS resolver (`127.0.0.11`) and routes to the backend via its Compose service name: `backend:8080`.

---

## Kubernetes (Minikube)

Use this for a production-like deployment where pods, replicas, and services are managed by Kubernetes.

### Prerequisites

- [Minikube](https://minikube.sigs.k8s.io/) installed
- [kubectl](https://kubernetes.io/docs/tasks/tools/) installed
- Docker Hub account (images must be pushed there — Minikube pulls from the registry)
- Hyper-V enabled on Windows (run as Administrator):
  ```powershell
  Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-Tools-All -All
  ```

### First-time setup

```bash
minikube start --driver=hyperv
```

Create the database secret (this file is gitignored — you must create it manually):

```bash
# k8s/database-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: database-secret
type: Opaque
stringData:
  MYSQL_ROOT_PASSWORD: "my-pwd"
```

Apply all manifests:

```bash
kubectl apply -f k8s/database-secret.yaml
kubectl apply -f k8s/
```

Get the URL to open in your browser:

```bash
minikube service frontend-service --url
# e.g. http://172.18.16.112:30080
```

### Stop / tear down

```bash
# Pause without deleting anything
minikube stop

# Delete the cluster entirely (loses all data)
minikube delete
```

### Rebuild and redeploy after a code change

Run `build.sh` — it builds all three images, pushes them to Docker Hub, then roll out the updated deployment in Kubernetes.

```bash
# Must be run inside WSL (not PowerShell or CMD)
# 1. Build and push all images
./build.sh <dockerhub-username>

# 2. Update the image tag in the relevant k8s/*-deployment.yaml, then apply
kubectl apply -f k8s/frontend-deployment.yaml

# 3. If the tag is the same as before, force a fresh rollout
kubectl rollout restart deployment/frontend-deployment
```

### Check pod status

```bash
kubectl get pods
kubectl logs <pod-name>
kubectl describe pod <pod-name>   # detailed events if a pod is stuck
```

### How nginx works here

The frontend image has `nginx.conf` baked in at build time (no volume override). That config uses:

- Resolver: `10.96.0.10` (Kubernetes kube-dns)
- Backend hostname: `backend-service.default.svc.cluster.local:80`
- `proxy_set_header Origin "";` on all proxy blocks — strips the Origin header so Spring Security never sees a cross-origin request and CORS is not needed

---

## Key difference: the nginx config

| | Docker Compose | Kubernetes |
|---|---|---|
| nginx config file | `nginx.docker.conf` (mounted as volume) | `nginx.conf` (baked into image) |
| Backend hostname | `backend` (Compose service name) | `backend-service.default.svc.cluster.local` |
| DNS resolver | `127.0.0.11` (Docker internal) | `10.96.0.10` (kube-dns) |
| Backend port | `8080` | `80` (ClusterIP service) |
| Frontend URL | http://localhost:80 | `minikube service frontend-service --url` |
| Postman base URL | http://localhost:8080 | not directly accessible (ClusterIP) |
