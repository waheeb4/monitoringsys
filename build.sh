#!/usr/bin/bash

set -e

docker stop db-container || true
docker rm db-container || true

docker stop backend-container || true
docker rm backend-container || true

docker network rm dxc-network || true

docker network create dxc-network

docker build -f database.Dockerfile -t database:1.0 . &
databasepid=$!

docker build -f backend.Dockerfile -t backend:1.0 . &
backendpid=$!

wait $databasepid $backendpid

docker run --name db-container --network dxc-network --mount type=volume,src=db-data,dst=/var/lib/mysql -d database:1.0

until docker run --rm --network dxc-network mysql:latest mysqladmin ping -h db-container -uroot -pmy-pwd --silent 2>/dev/null; do
    sleep 2
done

docker run --name backend-container --network dxc-network -p 8080:8080 -d backend:1.0
