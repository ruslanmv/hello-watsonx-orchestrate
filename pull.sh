#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# pull_from_ibm.sh — Helper to pull the DB image from IBM Cloud Container Registry,
#                   using API key (from .env) or interactive SSO, and pulling
#                   the correct private namespace image.
###############################################################################

ENV_FILE=".env"
DEFAULT_REGION="us-south"
DEFAULT_TAG="latest"
NAMESPACE="watson-orchestrate-private"
REPO="wxo-server-db"

# 1) Load .env if present
if [[ -f "$ENV_FILE" ]]; then
  # only export lines like KEY=VALUE, ignoring comments
  export $(grep -E '^[A-Za-z_][A-Za-z0-9_]*=' "$ENV_FILE" | xargs)
fi

# Determine final region and registry endpoint
REGION="${IBM_REGION:-$DEFAULT_REGION}"
REGISTRY="${REGION}.icr.io"
IMAGE="${REGISTRY}/${NAMESPACE}/${REPO}:${IMAGE_TAG:-$DEFAULT_TAG}"

# 2) IBM Cloud login
if [[ -n "${DOCKER_IAM_KEY:-}" ]]; then
  echo "🔐 Logging in with API key from .env (region: $REGION)..."
  ibmcloud login --apikey "$DOCKER_IAM_KEY" --region "$REGION" \
    ${IBM_RESOURCE_GROUP:+--g "$IBM_RESOURCE_GROUP"} \
    >/dev/null
else
  echo "→ No DOCKER_IAM_KEY in .env, using interactive SSO login."
  read -rp "Log in to IBM Cloud with SSO now? [Y/n] " ans
  ans=${ans:-Y}
  if [[ $ans =~ ^[Yy]$ ]]; then
    ibmcloud login --sso --region "$REGION"
  else
    echo "Aborting: not logged in." >&2
    exit 1
  fi
fi

# 3) (Optional) switch account
read -rp "→ Need to switch to a different account? [y/N] " switch_acc
if [[ $switch_acc =~ ^[Yy]$ ]]; then
  ibmcloud target --ca
fi

# 4) Configure Container Registry region
echo "⚙️  Setting container-registry region to $REGION..."
ibmcloud cr region-set "$REGION" >/dev/null

# 5) Log in to Container Registry
echo "🚢 Logging Docker in to IBM Cloud Container Registry..."
ibmcloud cr login >/dev/null

# 6) Pull the image
echo "⬇️  Pulling image $IMAGE..."
docker pull "$IMAGE"

echo "✅ Done! Pulled $IMAGE"
