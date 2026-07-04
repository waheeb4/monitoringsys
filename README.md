# Project README

## Overview

This project is a full-stack application with a frontend client that communicates with a backend API. Authentication is handled via guarded routes on the client and dedicated auth endpoints on the server. Container builds are automated through shell scripts.

---

## Frontend Pages

The frontend exposes three primary routes, each protected by a route guard that controls access based on the user's authentication state.

### `/login` — *Auth Guard*

The login page where existing users authenticate with their credentials. The auth guard ensures that already-authenticated users are redirected away from this page (typically to `/profile`), preventing unnecessary re-authentication.

- **Calls:** `POST /auth/login`
- **On success:** stores the returned token/session and redirects to `/profile`.

### `/signup` — *Auth Guard*

The registration page for new users. Like `/login`, it is protected by the auth guard so that users who already have an active session are redirected away.

- **Calls:** `POST /auth/signup`
- **On success:** either auto-logs the user in or redirects to `/login`.

### `/profile` — *Guest Guard*

The authenticated user's profile page, where they can view and update their account details, change their password, and update their profile picture. The guest guard blocks unauthenticated visitors and redirects them to `/login`.

- **Calls:**
  - `GET /api/users/me` — fetch the current user's profile.
  - `POST /api/users/password` — change the password.
  - `POST /api/users/picture` — change  new profile picture.

---

## Backend Endpoints

| Method   | Endpoint              | Description                                   | Used By           |
| -------- | --------------------- | --------------------------------------------- | ----------------- |
| `POST`   | `/auth/signup`        | Register a new user account.                  | `/signup`         |
| `POST`   | `/auth/login`         | Authenticate and issue a session/JWT.         | `/login`          |
| `GET`    | `/api/users/me`       | Return the currently authenticated user.      | `/profile`        |
| `POST`    | `/api/users/password` | Change the current user's password.           | `/profile`        |
| `PATCH`   | `/api/users/picture`  | Upload/replace the profile picture.           | `/profile`        |
| `GET`    | `/heartbeat`          | Liveness check — returns `200 OK` if up.      | Monitoring  |

> **Note:** All `/api/*` and `/auth/*` routes (except `/auth/signup`, `/auth/login`, and `/heartbeat`) require a valid auth token in the `Authorization: Bearer <token>` header.

---

## Scripts

Two shell scripts at the project root manage the local dev environment and the production image pipeline.

### `./dev.sh` — Build & Run Locally

Builds the development Docker image and starts the stack locally with hot-reload enabled. Use this while developing.

```bash
./dev.sh
```

What it does:

Builds the local Docker image(s) from the project `Dockerfile`(s).


### `./build.sh` — Build & Push to Docker Hub

Builds the production image and pushes it to the configured Docker Hub registry. Use this when cutting a release.

```bash
./build.sh
```

What it does:

1. Builds the production image with the appropriate tag.
2. Authenticates against Docker Hub (assumes you've already run `docker login`).
3. Pushes the tagged image to the registry so it can be pulled by deployment targets.

---

## Typical Workflow

```bash
# 1. Develop locally
./dev.sh

# 2. When ready to ship, build & push the production image
./build.sh
```
