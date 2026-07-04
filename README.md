# IoT Monitoring System

A full-stack IoT platform for collecting, processing, and analyzing real-time sensor data. Built for industries such as smart homes, industrial automation, agriculture, and environmental monitoring.

---

## Features

- Real-time sensor data collection and live dashboard
- Threshold-based alerts and email notifications
- Historical data analysis, trend charts, and filters
- Remote device control via API commands
- Automated rule-based actions
- Data export (CSV / JSON) and scheduled email reports

---

## Prerequisites

- Docker

---

## Running the App

There are three scripts depending on your goal:

### Development — build locally, no registry

```bash
git clone --recursive <repo-url>
cd monitoring-system
git submodule update --init
./dev.sh
```

Builds all three images locally with `:dev` tags and starts the containers. The frontend is at `http://localhost:4200` and the backend is also directly accessible at `http://localhost:8080`.

---

### Build & Publish — build locally and push to Docker Hub

```bash
./build.sh <your-dockerhub-username>
```

Builds all three images, starts and health-checks the containers, then pushes the images to your Docker Hub registry.

---

### Deploy — pull pre-built images and run

```bash
./deploy.sh
```

Pulls the latest pre-built images from Docker Hub and starts the containers — no build step required. The app will be at `http://localhost:4200`.

---

> **Note:** On first run, MySQL initializes the schema automatically. On subsequent runs the data volume is reused. To reset the database: `docker volume rm db-data` before running the script.
