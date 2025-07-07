#!/usr/bin/env bash
# ┌────────────────────────────────────────────────────────────────────────────┐
# │                                                                            │
# │ ██╗    ██╗ █████╗ ████████╗███████╗ ██████╗ ███╗   ██╗██╗  ██╗             │
# │ ██║    ██║██╔══██╗╚══██╔══╝██╔════╝██╔═══██╗████╗  ██║╚██╗██╔╝             │
# │ ██║ █╗ ██║███████║   ██║   ███████╗██║   ██║██╔██╗ ██║ ╚███╔╝              │
# │ ██║███╗██║██╔══██║   ██║   ╚════██║██║   ██║██║╚██╗██║ ██╔██╗              │
# │ ╚███╔███╔╝██║  ██║   ██║   ███████║╚██████╔╝██║ ╚████║██╔╝ ██╗             │
# │  ╚══╝╚══╝ ╚═╝  ╚═╝   ╚═╝   ╚══════╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝             │
# │                                                                            │
# │            watsonx Orchestrate  DEV EDITION  by ruslanmv.com               │
# └────────────────────────────────────────────────────────────────────────────┘
#
# Installs a chosen STABLE version of IBM watsonx Orchestrate ADK in an
# isolated Python virtual-environment (./venv).
#
# This script prepares the environment but does NOT start the server.
#
# If a ./venv directory already exists, installation is skipped.
#
# ── ACCOUNT TYPES ────────────────────────────────────────────────────────────
#   Account type is determined by the WO_DEVELOPER_EDITION_SOURCE variable:
#   1. 'orchestrate': Uses watsonx Orchestrate credentials (WO_INSTANCE + WO_API_KEY)
#   2. 'myibm': Uses watsonx.ai credentials (WO_ENTITLEMENT_KEY + WATSONX_APIKEY + WATSONX_SPACE_ID)
#
# Ensure an appropriate `.env` exists in this directory before running.
# ---------------------------------------------------------------------------

set -euo pipefail

# ── Blue runtime logo ────────────────────────────────────────────────────────
print_logo() {
  local BLUE="\033[1;34m"; local NC="\033[0m"
  echo -e "${BLUE}"
  cat <<'EOF'
                _
               | |
 _ __ _   _ ___| | __ _ _ __   _ __ _____   __
| '__| | | / __| |/ _` | '_ \| '_ ` _ \ \ / /
| |  | |_| \__ \ | (_| | | | | | | | | \ V /
|_|   \__,_|___/_|\__,_|_| |_|_| |_| |_|\_/

EOF
  echo -e "${NC}"
}

print_logo



# ────────────────────────────────────────────────────────────────────────────
#  Pre-flight: Verify local tooling before touching Docker
# ────────────────────────────────────────────────────────────────────────────
command -v docker >/dev/null \
  || { echo "❌ Docker not installed. Please install Docker first."; exit 1; }

if ! docker compose version 2>/dev/null | grep -q 'v2\.'; then
  echo "❌ Docker Compose v2 missing. Please upgrade to Compose v2."; exit 1
fi

if ! command -v ifconfig >/dev/null; then
  echo "ℹ️  'ifconfig' not found (package net-tools). IP auto-detect will fall back to other methods."
fi

# ────────────────────────────────────────────────────────────────────────────
#  Config
# ────────────────────────────────────────────────────────────────────────────
ADK_VERSIONS=( "1.5.0" "1.5.1" "1.6.0" "1.6.1" "1.6.2" )
ENV_FILE="./.env"
ADK_VERSION=""
ACCOUNT_TYPE=""

# ────────────────────────────────────────────────────────────────────────────
#  Load .env *before* anything else
# ────────────────────────────────────────────────────────────────────────────
[[ -f "$ENV_FILE" ]] || { echo "❌ .env not found"; exit 1; }
set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

# ────────────────────────────────────────────────────────────────────────────
#  Detect account type based on WO_DEVELOPER_EDITION_SOURCE
# ────────────────────────────────────────────────────────────────────────────
if [[ "${WO_DEVELOPER_EDITION_SOURCE:-}" == "orchestrate" ]]; then
  ACCOUNT_TYPE="orchestrate"
elif [[ "${WO_DEVELOPER_EDITION_SOURCE:-}" == "myibm" ]]; then
  ACCOUNT_TYPE="watsonx.ai"
else
  echo "❌ WO_DEVELOPER_EDITION_SOURCE is not set or has an invalid value in .env." >&2
  echo "   It must be either 'orchestrate' or 'myibm'." >&2
  exit 1
fi
echo "🔍 Detected account source: ${WO_DEVELOPER_EDITION_SOURCE} (Account Type: ${ACCOUNT_TYPE})"


# ────────────────────────────────────────────────────────────────────────────
#  Validate required keys
# ────────────────────────────────────────────────────────────────────────────
if [[ "$ACCOUNT_TYPE" == "orchestrate" ]]; then
  for V in WO_DEVELOPER_EDITION_SOURCE WO_INSTANCE WO_API_KEY; do
    [[ -n "${!V:-}" ]] || { echo "❌ $V is missing in .env for 'orchestrate' source."; exit 1; }
  done
else # watsonx.ai
  for V in WO_DEVELOPER_EDITION_SOURCE WO_ENTITLEMENT_KEY WATSONX_APIKEY WATSONX_SPACE_ID; do
    [[ -n "${!V:-}" ]] || { echo "❌ $V is missing in .env for 'myibm' source."; exit 1; }
  done
fi

# ────────────────────────────────────────────────────────────────────────────
#  IBM Cloud CLI login & container-registry login
# ────────────────────────────────────────────────────────────────────────────
if command -v ibmcloud >/dev/null; then
  # derive region from WO_INSTANCE (e.g. api.us-south.watson… → us-south)
  if [[ "$ACCOUNT_TYPE" == "orchestrate" ]]; then
    REGION=$(echo "$WO_INSTANCE" | cut -d. -f2)
  else
    REGION="us-south"
  fi

  echo "🔐 Logging into IBM Cloud (region: $REGION)…"
  ibmcloud login --apikey "${WO_API_KEY:-$WO_ENTITLEMENT_KEY}" -r "$REGION"

  echo "🔐 Logging Docker into IBM Container Registry…"
  ibmcloud cr login
else
  echo "⚠️  ibmcloud CLI not found; skipping IBM Cloud login." >&2
  echo "   You will need to 'docker login' manually." >&2
fi

# ────────────────────────────────────────────────────────────────────────────
#  Setup Python virtual-environment & ADK
# ────────────────────────────────────────────────────────────────────────────
if [[ -d "venv" ]]; then
  echo "📦 Found existing venv. Activating…"
  # shellcheck disable=SC1091
  source venv/bin/activate
  echo "🔧 Python $(python --version)"
  ADK_VERSION=$(pip show ibm-watsonx-orchestrate 2>/dev/null \
                | awk '/^Version:/{print $2}')
  [[ -z "$ADK_VERSION" ]] && echo "⚠️  Could not detect installed ADK version."
else
  echo "📦 Creating venv in ./venv…"
  python3.11 -m venv venv
  # shellcheck disable=SC1091
  source venv/bin/activate
  echo "🔧 Python $(python --version)"

  echo; echo "Available ADK versions:"
  for i in "${!ADK_VERSIONS[@]}"; do
    printf "   %2d) %s\n" $((i+1)) "${ADK_VERSIONS[$i]}"
  done
  read -rp "Select ADK version number: " IDX
  [[ "$IDX" =~ ^[0-9]+$ && "$IDX" -ge 1 && "$IDX" -le "${#ADK_VERSIONS[@]}" ]] \
    || { echo "❌ Invalid version."; exit 1; }
  ADK_VERSION="${ADK_VERSIONS[$((IDX-1))]}"
  echo "📦 Installing ibm-watsonx-orchestrate==$ADK_VERSION …"
  pip install --quiet --upgrade "ibm-watsonx-orchestrate==$ADK_VERSION"
fi

# ────────────────────────────────────────────────────────────────────────────
#  Done
# ────────────────────────────────────────────────────────────────────────────
echo
if [[ -n "$ADK_VERSION" ]]; then
  echo "✅  Environment setup for ADK v$ADK_VERSION is complete."
else
  echo "✅  Environment setup is complete."
fi
echo "   You can now activate the venv with 'source venv/bin/activate' and run the server."
echo "   Happy building — ruslanmv.com 🚀"