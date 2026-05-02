#!/usr/bin/bash

set -e

docker stop db-container || true
docker rm db-container || true

docker stop backend-container || true
docker rm backend-container || true

docker stop frontend-container || true
docker rm frontend-container || true

docker network rm dxc-network || true

docker network create dxc-network

docker build -f DXC-IoT-Monitoring-System-backend/database.Dockerfile -t database:1.0 DXC-IoT-Monitoring-System-backend/ &
databasepid=$!

docker build -f DXC-IoT-Monitoring-System-backend/backend.Dockerfile -t backend:1.0 DXC-IoT-Monitoring-System-backend/ &
backendpid=$!

docker build -f DXC-IoT-Monitoring-System-frontend/frontend.Dockerfile -t frontend:1.0 DXC-IoT-Monitoring-System-frontend/ &
frontendpid=$!

wait $databasepid $backendpid $frontendpid

docker run --name db-container --network dxc-network --mount type=volume,src=db-data,dst=/var/lib/mysql -d database:1.0

until docker run --rm --network dxc-network mysql:latest mysqladmin ping -h db-container -uroot -pmy-pwd --silent 2>/dev/null; do
    sleep 1
done

docker run --name backend-container --network dxc-network -p 8080:8080 -d backend:1.0

until [ "$(curl -s http://localhost:8080/heartbeat)" = "alive" ]; do                                                         
      sleep 1                                                                                                                 
done

docker run --name frontend-container --network dxc-network -p 4200:8080 -d frontend:1.0

