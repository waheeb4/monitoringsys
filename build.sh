#!/usr/bin/bash

set -e

if [ -z "$1" ]; then
    echo "Specify docker hub username please!"
    echo "./build.sh <username>"
    exit 1
fi

REGISTRY="$1"

docker login

DB_IMAGE="$REGISTRY/database-service:v1.0"
BACKEND_IMAGE="$REGISTRY/backend-service:v1.0"
FRONTEND_IMAGE="$REGISTRY/frontend-service:v1.0"

docker stop db-container || true
docker rm db-container || true

docker stop backend-container || true
docker rm backend-container || true

docker stop frontend-container || true
docker rm frontend-container || true

docker network rm dxc-network || true

docker network create dxc-network

docker build -f IoT-Monitoring-System-backend/database.Dockerfile -t "$DB_IMAGE" IoT-Monitoring-System-backend/ &
databasepid=$!

docker build -f IoT-Monitoring-System-backend/backend.Dockerfile -t "$BACKEND_IMAGE" IoT-Monitoring-System-backend/ &
backendpid=$!

docker build -f IoT-Monitoring-System-frontend/frontend.Dockerfile -t "$FRONTEND_IMAGE" IoT-Monitoring-System-frontend/ &
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

docker run --name backend-container --network dxc-network -d "$BACKEND_IMAGE"

retries=0
until [ "$(docker run --rm --network dxc-network curlimages/curl curl -s http://backend-container:8080/heartbeat)" = "alive" ]; do
    retries=$((retries + 1))
    if [ "$retries" -ge 60 ]; then
        echo "Backend failed to start!"
        exit 1
    fi
    sleep 1
done

docker run --name frontend-container --network dxc-network -p 4200:8080 -d "$FRONTEND_IMAGE"

echo "Access the web app via: http://localhost:4200"
sleep 5

docker push "$DB_IMAGE"
docker push "$BACKEND_IMAGE"
docker push "$FRONTEND_IMAGE"
