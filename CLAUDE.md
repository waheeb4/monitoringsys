# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

IoT monitoring system with three components: Angular frontend, Spring Boot backend, MySQL database. Each component has its own repo (frontend and backend are git submodules). This repo is the infrastructure/orchestration layer.

## Running the System

```bash
# Build and run all containers (tear down first, then rebuild)
./build.sh
```

The script tears down existing containers/network, builds images in parallel (forked with `&`), waits on all PIDs, then runs containers attached to `dxc-network`.

## Docker Architecture

- `database.Dockerfile` — MySQL image with `schema.sql` copied into `/docker-entrypoint-initdb.d/` for auto-initialization on first boot
- `build.sh` — orchestration script: teardown → network create → parallel builds → wait → run
- All containers communicate over the `dxc-network` user-defined bridge network, which enables DNS resolution by container name

## Key Conventions

- Container name: `db-container`, Network: `dxc-network`, Volume: `db-data`
- MySQL data persisted via volume mounted at `/var/lib/mysql`
- `initdb.d/` only runs when the volume is empty (first boot or after `docker volume rm db-data`)
- Backend connects to DB at `db-container:3306`
- Frontend (Angular) uses `localhost:<port>` for API calls since it runs in the browser, not in Docker

## Testing the Database

```bash
# Verify seed data
docker run --rm --network dxc-network mysql:latest mysql -h db-container -uroot -pmy-pwd monitoring -e "SELECT * FROM sensor_readings;"

# Insert test row
docker run --rm --network dxc-network mysql:latest mysql -h db-container -uroot -pmy-pwd monitoring -e "INSERT INTO sensor_readings (device_id, temperature, humidity, pressure) VALUES (1, 55.5, 44.4, 999.9);"
```
