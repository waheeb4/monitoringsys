# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

IoT monitoring system with three components: Angular frontend, Spring Boot backend, MySQL database. This repo is the infrastructure/orchestration layer. Both frontend and backend live in git submodules.

## Running the System

```bash
# Build and run all containers (tear down first, then rebuild)
./build.sh
```

The script tears down existing containers/network, builds all three images in parallel, starts the DB, polls until MySQL accepts connections, starts the backend and polls until `/heartbeat` responds, then starts the frontend.

## Frontend Dev (Angular)

```bash
cd DXC-IoT-Monitoring-System-frontend
npm install
npm start        # ng serve — dev server at http://localhost:4200
npm test         # ng test (uses vitest via @angular/build:unit-test, not Karma)
ng build         # production build — outputs to dist/mp-app/browser (CSR) and dist/mp-app/server (SSR)
```

Angular 21 with SSR (`@angular/ssr` + Express). In dev (`npm start`), `proxy.conf.json` is wired via `angular.json` (`proxyConfig`) — `/auth`, `/api`, and `/heartbeat` are proxied to `http://localhost:8080`. In Docker, the nginx layer handles this instead (see below).

## Backend Local Dev (without Docker)

Requires MySQL running and reachable at `db-container:3306` (or edit `application.properties`):

```bash
cd DXC-IoT-Monitoring-System-backend/DXC-IoT-Monitoring-System-backend
./mvnw spring-boot:run

# Or skip tests and package
./mvnw package -DskipTests
```

## Docker Architecture

- `database.Dockerfile` — MySQL 9.7 image with `schema.sql` copied into `/docker-entrypoint-initdb.d/` for auto-initialization on first boot
- `backend.Dockerfile` — three-stage Maven build: `deps` pre-fetches via `mvn dependency:go-offline`, `build` compiles with `-DskipTests`, `runtime` uses `eclipse-temurin:25-jre`
- `frontend.Dockerfile` — two-stage build: Node 24 Alpine runs `npm run build`, then `nginxinc/nginx-unprivileged:alpine` serves the output. Copies `dist/mp-app/browser` (CSR only — SSR is not used in Docker)
- All three Dockerfiles live inside their respective submodules; `build.sh` passes the submodule as the build context so all `COPY` paths are relative to the submodule root
- All containers communicate over the `dxc-network` bridge network

## Nginx as API Proxy (Critical)

The frontend container runs nginx on port 8080 (mapped to host `4200`). `nginx.conf` proxies backend routes so the Angular app never needs CORS:

| Client request | Proxied to |
|---|---|
| `localhost:4200/auth/*` | `backend-container:8080/auth/*` |
| `localhost:4200/api/users/*` | `backend-container:8080/api/users/*` |
| `localhost:4200/heartbeat` | `backend-container:8080/heartbeat` |

Angular makes calls to `localhost:4200/...` in the browser; nginx resolves `backend-container` via Docker's internal DNS (`127.0.0.11`). This is the only supported integration path — do not configure CORS on the backend for Docker use.

## Key Conventions

- Container names: `db-container`, `backend-container`, `frontend-container` — Network: `dxc-network` — Volume: `db-data`
- MySQL data persisted via volume at `/var/lib/mysql`
- `initdb.d/` only runs when the volume is empty — run `docker volume rm db-data` to force schema re-initialization
- Backend connects to DB at `db-container:3306`, database name `monitoring`, credentials `root/my-pwd`
- `application.properties` must exist at `DXC-IoT-Monitoring-System-backend/DXC-IoT-Monitoring-System-backend/src/main/resources/application.properties` — this is what gets packaged into the JAR. There is also a duplicate at the submodule root (`DXC-IoT-Monitoring-System-backend/src/main/resources/`) — only the nested path matters

## Submodule Structure

```bash
# After cloning this repo
git submodule update --init
```

Both submodules must be committed and pushed to their own remotes before updating the pointer in this repo:

- `DXC-IoT-Monitoring-System-backend/` — backend submodule (SSH: `git@github.com:nabil0412/DXC-IoT-Monitoring-System-backend.git`)
  - `DXC-IoT-Monitoring-System-backend/` — nested: the actual Spring Boot Maven project (`pom.xml` + Java source)
  - `backend.Dockerfile`, `database.Dockerfile`, `schema.sql` — live at the submodule root
- `DXC-IoT-Monitoring-System-frontend/` — frontend submodule (SSH: `git@github.com:nabil0412/DXC-IoT-Monitoring-System-frontend.git`)
  - `frontend.Dockerfile`, `nginx.conf` — live at the submodule root

## Frontend Architecture

Angular 21, standalone components, no NgModules. Routes with guards:

- `/signup` (default) → `SignupComponent` — `guestGuard` (redirects to `/profile` if logged in)
- `/login` → `LoginComponent` — `guestGuard`
- `/home` → `HomeComponent`
- `/profile` → `ProfileComponent` — `authGuard` (redirects to `/login` if not logged in)

Guards check `localStorage.getItem('token')` via `UserService.isLoggedIn()`.

Services:
- `UserService` — HTTP-wired. `signup()` → POST `/auth/signup`, `login()` → POST `/auth/login`. JWT token persisted in `localStorage` (survives page refresh). `setUser()` stores token; `clearUser()` removes it.
- `ProfileService` — HTTP-wired. `getMyProfile()` → GET `/api/users/me`, `updateProfilePicture()` → PATCH `/api/users/picture`, `changePassword()` → POST `/api/users/password`.

## Backend Package Structure

Spring Boot 3.5.14 app at `com.example.DXCproject`. All features live under `auth/`, each as a vertical slice with `Controller`, `Service`, and `Repository`:

- `auth/login/` — POST `/auth/login`, returns JWT
- `auth/signup/` — POST `/auth/signup`, BCrypt-hashes password
- `auth/change_password/`
- `auth/user_profile/`
- `auth/update_profile_picture/`
- `auth/User.java` — JPA entity mapped to `users` table (UUID PK as `CHAR(36)`)
- `auth/SecurityConfig.java` — Spring Security configured stateless, CSRF off, all requests permitted; JWT enforcement is handled manually in each Service (not via a filter)
- `HealthController.java` — GET `/heartbeat`

Stack: Spring Boot 3.5.14, Spring Data JPA, Spring Security, JJWT 0.12.6, MySQL Connector/J. `pom.xml` targets Java 17; Dockerfile runtime uses `eclipse-temurin:25-jre`.

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

Owner: `schema.sql` in the backend submodule root. Hibernate is set to `ddl-auto=validate` — it checks but does not create tables. The `users` table must match the `User` entity in `User.java` exactly.
