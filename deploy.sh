#!/usr/bin/bash

set -e

# Publish the images that dev.sh has already built and tested locally.
REGISTRY="waheeb4"
# Default to the mutable tag while validating the initial OpenShift deployment.
# An explicit version can still be supplied: ./deploy.sh v1.9
IMAGE_TAG="${1:-latest}"

LOCAL_DB_IMAGE="database-service:dev"
LOCAL_BACKEND_IMAGE="backend-service:dev"
LOCAL_FRONTEND_IMAGE="frontend-service:dev"

DB_IMAGE="$REGISTRY/database-service:$IMAGE_TAG"
BACKEND_IMAGE="$REGISTRY/backend-service:$IMAGE_TAG"
FRONTEND_IMAGE="$REGISTRY/frontend-service:$IMAGE_TAG"

for image in "$LOCAL_DB_IMAGE" "$LOCAL_BACKEND_IMAGE" "$LOCAL_FRONTEND_IMAGE"; do
    if ! docker image inspect "$image" >/dev/null 2>&1; then
        echo "Missing local image: $image"
        echo "Run ./dev.sh successfully before publishing."
        exit 1
    fi
done

docker login

docker tag "$LOCAL_DB_IMAGE" "$DB_IMAGE"
docker tag "$LOCAL_BACKEND_IMAGE" "$BACKEND_IMAGE"
docker tag "$LOCAL_FRONTEND_IMAGE" "$FRONTEND_IMAGE"

docker push "$DB_IMAGE"
docker push "$BACKEND_IMAGE"
docker push "$FRONTEND_IMAGE"

echo "Published Docker Hub images with tag: $IMAGE_TAG"
