# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

IoT monitoring system with three components: Angular frontend, Spring Boot backend, MySQL database. This repo is the infrastructure/orchestration layer. The backend lives in the `dxc-backend` git submodule.

## Running the System

```bash
# Build and run all containers (tear down first, then rebuild)
./build.sh
```

The script tears down existing containers/network, builds images in parallel, waits for both, starts the DB, polls until MySQL accepts connections, then starts the backend.

## Docker Architecture

- `database.Dockerfile` — MySQL image with `schema.sql` copied into `/docker-entrypoint-initdb.d/` for auto-initialization on first boot
- `backend.Dockerfile` — multi-stage Maven build (deps cache → compile → JRE runtime), copies source from `dxc-backend/`
- All containers communicate over the `dxc-network` bridge network, enabling DNS resolution by container name

## Key Conventions

- Container names: `db-container`, `backend-container` — Network: `dxc-network` — Volume: `db-data`
- MySQL data persisted via volume at `/var/lib/mysql`
- `initdb.d/` only runs when the volume is empty — run `docker volume rm db-data` to force schema re-initialization
- Backend connects to DB at `db-container:3306`, database name `monitoring`, credentials `root/my-pwd`
- Frontend (Angular) uses `localhost:<port>` for API calls since it runs in the browser, not in Docker
- `application.properties` is gitignored in the submodule — it must exist on disk for Docker to copy it into the image

## Submodule

```bash
# After cloning this repo
git submodule update --init
```

The backend submodule (`dxc-backend`) must be committed and pushed separately before updating the pointer in this repo.

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

Owner: `schema.sql` (infrastructure layer). Hibernate is set to `ddl-auto=validate` — it checks but does not create tables. The `users` table must match the `User` entity in `AuthRepository.java` exactly.
