# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

IoT monitoring system with three components: Angular frontend, Spring Boot backend, MySQL database. This repo is the infrastructure/orchestration layer. The backend lives in the `DXC-IoT-Monitoring-System-backend` git submodule.

## Running the System

```bash
# Build and run all containers (tear down first, then rebuild)
./build.sh
```

The script tears down existing containers/network, builds images in parallel, waits for both, starts the DB, polls until MySQL accepts connections, then starts the backend.

## Docker Architecture

- `database.Dockerfile` — MySQL 9.7 image with `schema.sql` copied into `/docker-entrypoint-initdb.d/` for auto-initialization on first boot
- `backend.Dockerfile` — three-stage Maven build: `deps` stage pre-fetches dependencies via `mvn dependency:go-offline`, `build` stage compiles and packages with `-DskipTests`, `runtime` stage uses `eclipse-temurin:25-jre`
- All containers communicate over the `dxc-network` bridge network, enabling DNS resolution by container name

## Key Conventions

- Container names: `db-container`, `backend-container` — Network: `dxc-network` — Volume: `db-data`
- MySQL data persisted via volume at `/var/lib/mysql`
- `initdb.d/` only runs when the volume is empty — run `docker volume rm db-data` to force schema re-initialization
- Backend connects to DB at `db-container:3306`, database name `monitoring`, credentials `root/my-pwd`
- Frontend (Angular) uses `localhost:<port>` for API calls since it runs in the browser, not in Docker
- `application.properties` is tracked in the submodule at `DXC-IoT-Monitoring-System-backend/src/main/resources/`; the Dockerfile copies it via `DXC-IoT-Monitoring-System-backend/src`

## Submodule Structure

```bash
# After cloning this repo
git submodule update --init
```

The submodule root (`DXC-IoT-Monitoring-System-backend/`) contains:
- `src/main/resources/application.properties` — DB/JWT config, copied into the Docker image
- `DXC-IoT-Monitoring-System-backend/` — the actual Spring Boot Maven project (pom.xml + Java source)

`backend.Dockerfile` copies from `DXC-IoT-Monitoring-System-backend/pom.xml` and `DXC-IoT-Monitoring-System-backend/src` — these paths point to the submodule root's `src/` (application.properties only) and the inner project directory. If the Dockerfile needs to compile Java source, the copy path must target `DXC-IoT-Monitoring-System-backend/DXC-IoT-Monitoring-System-backend/`.

The backend submodule must be committed and pushed separately before updating the pointer in this repo.

## Backend Package Structure

Spring Boot 3.5 app at `com.example.DXCproject`. All features live under `auth/`, each as a vertical slice with `Controller`, `Service`, and `Repository`:

- `auth/login/` — POST `/auth/login`, returns JWT
- `auth/signup/` — POST `/auth/signup`, BCrypt-hashes password
- `auth/change_password/`
- `auth/user_profile/`
- `auth/update_profile_picture/`
- `auth/User.java` — JPA entity mapped to `users` table (UUID PK as `CHAR(36)`)
- `auth/SecurityConfig.java` — Spring Security configured stateless, CSRF off, all requests permitted; JWT enforcement is handled manually in services
- `HealthController.java` — GET `/heartbeat`

Stack: Spring Boot 3.5, Spring Data JPA, Spring Security, JJWT 0.12.6, MySQL Connector/J. `pom.xml` targets Java 17; Dockerfile runtime uses `eclipse-temurin:25-jre`.

## Testing

```bash
# Confirm app is up (no DB)
curl http://localhost:8080/heartbeat

# Test DB connectivity — expect 401 if DB is reachable, 500 if not
curl -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"test"}'

# Query DB directly
docker run --rm --network dxc-network mysql:latest mysql -h db-container -uroot -pmy-pwd monitoring -e "SELECT * FROM users;"
```

## Schema

Owner: `schema.sql` (infrastructure layer). Hibernate is set to `ddl-auto=validate` — it checks but does not create tables. The `users` table must match the `User` entity in `User.java` exactly.
