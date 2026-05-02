# DXC Smart IoT Monitoring System

A full-stack IoT platform for collecting, processing, and analyzing real-time sensor data. Built for industries such as smart homes, industrial automation, agriculture, and environmental monitoring.

The system provides a centralized dashboard where operators can monitor live sensor readings, visualize historical trends, receive threshold-based alerts, remotely control devices, and define automation rules that execute without manual intervention.

---

## Features

| 1 | Real-time sensor data collection and live dashboard 
| 2 | Threshold-based alerts and email notifications 
| 3 | Historical data analysis, trend charts, and filters 
| 4 | Remote device control via API commands 
| 5 | Automated rule-based actions 
| 6 | Data export (CSV / JSON) and scheduled email reports

---

## How It Works

Sensors send readings to the backend via HTTP POST. The backend stores incoming data in MySQL, evaluates user-defined thresholds, and triggers alerts or automated actions when conditions are met. The Angular frontend connects to the backend through an nginx reverse proxy and displays live charts, historical trends, and device controls in a single dashboard.

```
Sensors / IoT Devices
        │
        │  HTTP POST (sensor readings)
        ▼
┌───────────────────────────────────┐
│           nginx (port 4200)       │  ◄── Browser / Operator Dashboard
│                                   │
│  /auth/*       ──► Spring Boot    │
│  /api/*        ──► Spring Boot    │
│  /heartbeat    ──► Spring Boot    │
│  /*            ──► Angular SPA    │
└───────────────────────────────────┘
        │
        │  Internal Docker network (dxc-network)
        ▼
┌──────────────────┐    ┌──────────────────┐
│   Spring Boot    │───►│     MySQL 9.7    │
│  (backend:8080)  │    │  (db:3306)       │
└──────────────────┘    └──────────────────┘
```
---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Frontend | Angular 21, TypeScript, Reactive Forms, SSR |
| Backend | Spring Boot 3.5, Spring Security, Spring Data JPA, JJWT |
| Database | MySQL 9.7 |
| Gateway | nginx (reverse proxy + static file server) |
| Containerization | Docker, Docker Hub |

---

## Prerequisites

- Docker
- A Docker Hub account

---

## Getting Started

```bash
git clone <repo-url>
cd dxc-monitoring-system
git submodule update --init

./build.sh <your-dockerhub-username>
```

This will build all three images in parallel, push them to Docker Hub, then start and health-check each container in order. The app will be available at `http://localhost:4200`.

> **Note:** On first run, MySQL initializes the schema automatically from `schema.sql`. On subsequent runs the data volume is reused. To reset the database: `docker volume rm db-data` before running the script.

---

## API Reference

All endpoints are accessible through the nginx proxy at `localhost:4200`. Direct access to the backend on port 8080 is available in development only.

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/heartbeat` | None | Service health check |
| POST | `/auth/signup` | None | Register a new operator account |
| POST | `/auth/login` | None | Authenticate — returns JWT |
| POST | `/auth/change_password` | JWT | Change account password |
| GET | `/api/users/profile` | JWT | Get authenticated user profile |
| PUT | `/api/users/update_profile_picture` | JWT | Update profile avatar |

---
