# DXC IoT Monitoring System

A real-time IoT sensor monitoring platform. Angular 21 frontend, Spring Boot backend, MySQL database — all containerized and orchestrated via Docker with nginx as the API gateway.

---

## Architecture

```
Browser
  │
  └─► localhost:4200  (nginx, port 8080 inside container)
        │
        ├─ /auth/*          ──► backend-container:8080
        ├─ /api/users/*     ──► backend-container:8080
        ├─ /heartbeat       ──► backend-container:8080
        └─ /*               ──► Angular static files (CSR)

Docker network: dxc-network
  ├── db-container        MySQL 9.7       (internal only)
  ├── backend-container   Spring Boot     localhost:8080
  └── frontend-container  nginx + Angular localhost:4200
```

nginx handles all API proxying inside the Docker network — no CORS configuration is needed on the backend.

---

## Prerequisites

- Docker
- A Docker Hub account (for pushing images)

For local development (without Docker):

- Node.js 24+ and npm
- Java 17+ and Maven
- MySQL running locally

---

## Quick Start (Docker)

```bash
git clone <repo-url>
git submodule update --init

./build.sh <your-dockerhub-username>
```

## Project Structure

```
dxc-monitoring-system/              ← orchestration root
├── build.sh                        ← build + run script
├── DXC-IoT-Monitoring-System-frontend/   ← git submodule
│   ├── frontend.Dockerfile
│   ├── nginx.conf
│   └── src/
│       └── app/
│           ├── signup/             ← SignupComponent
│           ├── login/              ← LoginComponent
│           ├── home/               ← HomeComponent
│           ├── profile/            ← ProfileComponent
│           └── services/
│               ├── user.ts         ← in-memory session store
│               └── profile-service.ts  ← mocked (not wired to API)
└── DXC-IoT-Monitoring-System-backend/   ← git submodule
    ├── backend.Dockerfile
    ├── database.Dockerfile
    ├── schema.sql
    └── DXC-IoT-Monitoring-System-backend/   ← Spring Boot Maven project
        └── src/main/java/com/example/DXCproject/
            ├── auth/
            │   ├── login/          ← POST /auth/login
            │   ├── signup/         ← POST /auth/signup
            │   ├── change_password/
            │   ├── user_profile/
            │   ├── update_profile_picture/
            │   ├── User.java       ← JPA entity (UUID PK)
            │   └── SecurityConfig.java
            └── HealthController.java  ← GET /heartbeat
```

---

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/heartbeat` | Health check — returns `alive` |
| POST | `/auth/signup` | Register a new user |
| POST | `/auth/login` | Authenticate — returns JWT |
| POST | `/auth/change_password` | Change user password |
| GET | `/api/users/profile` | Get user profile |
| PUT | `/api/users/update_profile_picture` | Update avatar |

Authentication is JWT-based. The backend validates tokens manually in each service — there is no global security filter.

---

## Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Angular 21, TypeScript, Reactive Forms, SSR (`@angular/ssr`) |
| Backend | Spring Boot 3.5, Spring Security, Spring Data JPA, JJWT 0.12.6 |
| Database | MySQL 9.7 |
| Proxy | nginx (unprivileged Alpine) |
| Build | Maven (3-stage Docker build), Node 24 Alpine |
| Runtime | eclipse-temurin:25-jre |

---

## Configuration

### Database

| Key | Value |
|-----|-------|
| Host | `db-container:3306` |
| Database | `monitoring` |
| User | `root` |
| Password | `my-pwd` |
| Volume | `db-data` |

Schema source of truth: `DXC-IoT-Monitoring-System-backend/schema.sql`. Hibernate runs in `validate` mode — it checks against the schema but does not create or alter tables.
