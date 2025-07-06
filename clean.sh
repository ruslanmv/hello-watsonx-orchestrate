#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# cleanup_specific_resources.sh
#
# Stops and removes a specific Docker container and its associated image.
# -----------------------------------------------------------------------------

# --- Configuration ---
CONTAINER_TO_REMOVE="docker-wxo-server-db-1"
IMAGE_TO_REMOVE="cp.icr.io/cp/wxo-lite/wxo-server-db:24-06-2025-v1"

# Ensure docker is installed
if ! command -v docker &> /dev/null; then
  echo "Error: Docker not found. Please install Docker first." >&2
  exit 1
fi

# --- Remove Container ---
echo "➡️  Checking for container: $CONTAINER_TO_REMOVE"
# The command checks if the container exists (in any state) before trying to remove it.
if [ -n "$(docker ps -a --filter "name=^/${CONTAINER_TO_REMOVE}$" -q)" ]; then
  echo " Found container. Forcibly removing it..."
  docker rm -f "$CONTAINER_TO_REMOVE"
  echo "✅ Container removed."
else
  echo "ℹ️  Container not found. Skipping."
fi

# --- Remove Image ---
echo "➡️  Checking for image: $IMAGE_TO_REMOVE"
# The command checks if the image exists before trying to remove it.
if [ -n "$(docker images -q "$IMAGE_TO_REMOVE")" ]; then
  echo " Found image. Forcibly removing it..."
  docker rmi -f "$IMAGE_TO_REMOVE"
  echo "✅ Image removed."
else
  echo "ℹ️  Image not found. Skipping."
fi

echo "✨ Cleanup complete!"