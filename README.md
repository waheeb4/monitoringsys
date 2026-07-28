# IoT Monitoring System

Full-stack IoT monitoring application with an Angular frontend, Spring Boot
backend, and MySQL database.

## Project Structure

| Path | Purpose |
|---|---|
| `IoT-Monitoring-System-frontend/` | Angular frontend |
| `IoT-Monitoring-System-backend/` | Spring Boot backend and database image |
| `selenium/` | Selenium/TestNG frontend tests |
| `Sanity-Pack/` | Postman API sanity tests |
| `custom-jenkins/` | Local Jenkins controller |
| `k8s/` | Kubernetes and OpenShift deployment |

The frontend, backend, and Selenium projects are Git submodules.

## Requirements

- Git
- Docker
- Docker Compose v2

## Clone

```bash
git clone --recurse-submodules git@github.com:waheeb4/monitoring-system.git
cd monitoring-system
```

For an existing clone:

```bash
git submodule update --init --recursive
```

## Run Locally

Create the database password file:

```bash
install -d -m 0700 secrets
printf '%s' 'your-local-password' > secrets/mysql_root_password.txt
chmod 0644 secrets/mysql_root_password.txt
```

Start the application:

```bash
docker compose up --build
```

Run it in the background:

```bash
docker compose up --build --detach --wait
```

| Service | Address |
|---|---|
| Frontend | <http://localhost> |
| Backend | <http://localhost:8080> |
| Health check | <http://localhost:8080/heartbeat> |

Stop the application:

```bash
docker compose down
```

Reset the application and its data:

```bash
docker compose down --volumes
```

## Tests

### Backend

```bash
cd IoT-Monitoring-System-backend
./mvnw test
```

### Frontend

Start the application, then select a Selenium TestNG suite:

```bash
cd selenium
mvn test -Dsuite=testng-sanity.xml
```

Available suites:

- `testng.xml`
- `testng-sanity.xml`
- `testng-sprint1.xml`
- `testng-sprint2.xml`
- `testng-sprint3.xml`
- `testng-sprint4.xml`

### API Sanity Pack

With the backend running:

```bash
newman run "Sanity-Pack/Sanity Check.postman_collection.json" \
  --environment "Sanity-Pack/IoT monitoring system - dev.postman_environment.json" \
  --env-var baseUrl=http://localhost:8080
```

## Jenkins

Start the local Jenkins controller:

```bash
docker compose -f custom-jenkins/docker-compose.yml up --build --detach
```

Open <http://localhost:8088>.

The pipeline:

1. Builds the three Docker images.
2. Starts MySQL and the backend.
3. Runs the API sanity pack.
4. Pushes versioned images to Docker Hub.
5. Deploys them to OpenShift.
6. Cleans up the local CI stack.

Required Jenkins configuration:

| ID or variable | Type |
|---|---|
| `github` | SCM credential |
| `mysql-root-password` | Secret text |
| `dockerhub` | Username and token |
| `openshift` | Secret text token |
| `OPENSHIFT_SERVER` | Global environment variable |

See [custom-jenkins/README.md](custom-jenkins/README.md) for setup details.

## Deployment Documentation

- [Kubernetes and OpenShift](k8s/README.md)
- [Minikube overview](k8s/minikube/README.md)
- [Minikube on WSL/Linux](k8s/minikube/minikube-setup-linux.md)
- [Minikube on Windows 10](k8s/minikube/minikube-setup-windows10.md)

## Component Documentation

- [Backend](IoT-Monitoring-System-backend/README.md)
- [Frontend](IoT-Monitoring-System-frontend/README.md)

`deploy.sh` and `docker-compose.hub.yml` are legacy manual deployment files.
