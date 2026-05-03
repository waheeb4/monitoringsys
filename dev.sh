#!/usr/bin/bash

set -e

DB_IMAGE="database-service:dev"
BACKEND_IMAGE="backend-service:dev"
FRONTEND_IMAGE="frontend-service:dev"

docker stop db-container || true
docker rm db-container || true

docker stop backend-container || true
docker rm backend-container || true

docker stop frontend-container || true
docker rm frontend-container || true

docker network rm dxc-network || true

docker network create dxc-network

docker build -f DXC-IoT-Monitoring-System-backend/database.Dockerfile -t "$DB_IMAGE" DXC-IoT-Monitoring-System-backend/ &
databasepid=$!

docker build -f DXC-IoT-Monitoring-System-backend/backend.Dockerfile -t "$BACKEND_IMAGE" DXC-IoT-Monitoring-System-backend/ &
backendpid=$!

docker build -f DXC-IoT-Monitoring-System-frontend/frontend.Dockerfile -t "$FRONTEND_IMAGE" DXC-IoT-Monitoring-System-frontend/ &
frontendpid=$!

wait $databasepid $backendpid $frontendpid

docker run --name db-container --network dxc-network --mount type=volume,src=db-data,dst=/var/lib/mysql -d "$DB_IMAGE"

retries=0
until docker run --rm --network dxc-network mysql:latest mysqladmin ping -h db-container -uroot -pmy-pwd --silent 2>/dev/null; do
    retries=$((retries + 1))
    if [ "$retries" -ge 60 ]; then
        echo "DB failed to start!"
        exit 1
    fi
    sleep 1
done

docker run --name backend-container --network dxc-network -p 8080:8080 -d "$BACKEND_IMAGE"

retries=0
until [ "$(curl -s http://localhost:8080/heartbeat)" = "alive" ]; do
    retries=$((retries + 1))
    if [ "$retries" -ge 60 ]; then
        echo "Backend failed to start!"
        exit 1
    fi
    sleep 1
done

docker run --name frontend-container --network dxc-network -p 4200:8080 -d "$FRONTEND_IMAGE"

echo "Frontend: http://localhost:4200"
echo "Backend:  http://localhost:8080"
