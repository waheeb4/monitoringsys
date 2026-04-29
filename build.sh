#!/usr/bin/bash

set -e

docker stop db-container || true
docker rm db-container || true

docker network rm dxc-network || true

docker network create dxc-network

docker build -f database.Dockerfile -t database:1.0 . &
databasepid=$!

wait $databasepid
docker run --name db-container --network dxc-network --mount type=volume,src=db-data,dst=/var/lib/mysql -d database:1.0

