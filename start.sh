#!/usr/bin/env bash
# ┌────────────────────────────────────────────────────────────────────────────┐
# │                                                                            │
# │ ██╗      ██╗ █████╗ ████████╗███████╗ ██████╗ ███╗   ██╗██╗  ██╗            │
# │ ██║      ██║██╔══██╗╚══██╔══╝██╔════╝██╔═══██╗████╗  ██║╚██╗██╔╝            │
# │ ██║ █╗ ██║███████║   ██║    ███████╗██║   ██║██╔██╗ ██║ ╚███╔╝             │
# │ ██║███╗██║██╔══██║   ██║    ╚════██║██║   ██║██║╚██╗██║ ██╔██╗             │
# │ ╚███╔███╔╝██║  ██║   ██║    ███████║╚██████╔╝██║ ╚████║██╔╝ ██╗            │
# │  ╚══╝╚══╝ ╚═╝  ╚═╝   ╚═╝    ╚══════╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝            │
# │                                                                            │
# │           watsonx Orchestrate   DEV EDITION   by ruslanmv.com              │
# └────────────────────────────────────────────────────────────────────────────┘
#
# Installs a chosen STABLE version of IBM watsonx Orchestrate ADK in an
# isolated Python virtual-environment (./venv) and starts the local
# Developer Edition server.
#
# If a ./venv directory already exists, installation is skipped.
#
# ── ACCOUNT TYPES ────────────────────────────────────────────────────────────
#    1. watsonx Orchestrate account
#             · WO_INSTANCE + WO_API_KEY
#             · WO_DEVELOPER_EDITION_SOURCE=orchestrate
#    2. watsonx.ai account
#             · WO_ENTITLEMENT_KEY + WATSONX_APIKEY + WATSONX_SPACE_ID
#             · WO_DEVELOPER_EDITION_SOURCE=myibm
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
 _ __ _  _ ___| | __ _ _ __  _ __ _____  __
| '__| | | / __| |/ _` | '_ \| '_ ` _ \ \ / /
| |  | |_| \__ \ | (_| | | | | | | | | \ V /
|_|   \__,_|___/_|\__,_|_| |_|_| |_| |_|\_/

EOF
  echo -e "${NC}"
}

print_logo

# ────────────────────────────────────────────────────────────────────────────
#  Pre-flight: Verify Docker & Compose v2
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

# ────────────────────────────────────────────────────────────────────────────
#  Load .env *before* anything else
# ────────────────────────────────────────────────────────────────────────────
[[ -f "$ENV_FILE" ]] || { echo "❌ .env not found"; exit 1; }
echo "📄 Loading variables from $ENV_FILE"
set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

# ────────────────────────────────────────────────────────────────────────────
#  Detect account type
# ────────────────────────────────────────────────────────────────────────────
if [[ "${WO_DEVELOPER_EDITION_SOURCE:-}" == "internal" ]] && \
   [[ -n "${DOCKER_IAM_KEY:-}" && -n "${WATSONX_APIKEY:-}" && -n "${WATSONX_SPACE_ID:-}" ]]; then

  ACCOUNT_TYPE="internal"

elif [[ "${WO_DEVELOPER_EDITION_SOURCE:-}" == "orchestrate" ]] && \
     [[ -n "${WO_INSTANCE:-}" && -n "${WO_API_KEY:-}" ]]; then

  ACCOUNT_TYPE="orchestrate"

elif [[ "${WO_DEVELOPER_EDITION_SOURCE:-}" == "myibm" ]] && \
     [[ -n "${WO_ENTITLEMENT_KEY:-}" && -n "${WO_INSTANCE:-}" && -n "${WO_API_KEY:-}" ]]; then

  ACCOUNT_TYPE="myibm"

elif [[ "${WO_DEVELOPER_EDITION_SOURCE:-}" == "watsonx.ai" ]] && \
     [[ -n "${WO_ENTITLEMENT_KEY:-}" && -n "${WATSONX_APIKEY:-}" && -n "${WATSONX_SPACE_ID:-}" ]]; then

  ACCOUNT_TYPE="watsonx.ai"

else
  cat <<EOF >&2
❌ Could not detect a valid credential block in .env.
Define exactly one of:

  • internal:
//  WO_DEVELOPER_EDITION_SOURCE=internal
//  DOCKER_IAM_KEY=…
//  WATSONX_APIKEY=…
//  WATSONX_SPACE_ID=…

  • orchestrate:
//  WO_DEVELOPER_EDITION_SOURCE=orchestrate
//  WO_INSTANCE=…
//  WO_API_KEY=…

  • myibm:
//  WO_DEVELOPER_EDITION_SOURCE=myibm
//  WO_ENTITLEMENT_KEY=…
//  WO_INSTANCE=…
//  WO_API_KEY=…
//  [WO_DEVELOPER_EDITION_SKIP_LOGIN=true|false]

  • watsonx.ai:
//  WO_DEVELOPER_EDITION_SOURCE=watsonx.ai
//  WO_ENTITLEMENT_KEY=…
//  WATSONX_APIKEY=…
//  WATSONX_SPACE_ID=…
EOF
  exit 1
fi

echo "🔍 Detected account type: $ACCOUNT_TYPE"

# ────────────────────────────────────────────────────────────────────────────
#  Validate only that credential block (extra keys are ignored)
# ────────────────────────────────────────────────────────────────────────────
case "$ACCOUNT_TYPE" in
  internal)
    for V in WO_DEVELOPER_EDITION_SOURCE DOCKER_IAM_KEY WATSONX_APIKEY WATSONX_SPACE_ID; do
      [[ -n "${!V:-}" ]] || { echo "❌ $V missing for internal mode."; exit 1; }
    done
    ;;
  orchestrate)
    for V in WO_DEVELOPER_EDITION_SOURCE WO_INSTANCE WO_API_KEY; do
      [[ -n "${!V:-}" ]] || { echo "❌ $V missing for orchestrate mode."; exit 1; }
    done
    ;;
  myibm)
    for V in WO_DEVELOPER_EDITION_SOURCE WO_ENTITLEMENT_KEY WO_INSTANCE WO_API_KEY; do
      [[ -n "${!V:-}" ]] || { echo "❌ $V missing for myibm mode."; exit 1; }
    done
    # default skip-login to false
    WO_DEVELOPER_EDITION_SKIP_LOGIN="${WO_DEVELOPER_EDITION_SKIP_LOGIN:-false}"
    ;;
  watsonx.ai)
    for V in WO_DEVELOPER_EDITION_SOURCE WO_ENTITLEMENT_KEY WATSONX_APIKEY WATSONX_SPACE_ID; do
      [[ -n "${!V:-}" ]] || { echo "❌ $V missing for watsonx.ai mode."; exit 1; }
    done
    ;;
esac

# ────────────────────────────────────────────────────────────────────────────
#  IBM Cloud / Docker login (skip in internal; optional skip in myibm)
# ────────────────────────────────────────────────────────────────────────────
if [[ "$ACCOUNT_TYPE" == "internal" ]]; then

  echo "🔐 internal mode: please ensure Docker is logged in manually if needed:"
  echo "      docker login -u iamapikey -p \$DOCKER_IAM_KEY registry.us-south.watson-orchestrate.cloud.ibm.com"

elif [[ "$ACCOUNT_TYPE" == "myibm" && "$WO_DEVELOPER_EDITION_SKIP_LOGIN" == "true" ]]; then

  echo "🔐 myibm mode with WO_DEVELOPER_EDITION_SKIP_LOGIN=true → skipping registry login"

else
  # for orchestrate, myibm (skip_login=false), watsonx.ai:
  if ! command -v ibmcloud >/dev/null; then
    echo "⚠️  ibmcloud CLI not found; please install it to auto-login." >&2
  else
    # determine region for CLI login
    REGION="us-south"
    [[ "$ACCOUNT_TYPE" == "orchestrate" || "$ACCOUNT_TYPE" == "myibm" ]] \
      && REGION=$(echo "$WO_INSTANCE" | cut -d. -f2)

    echo "🔐 Logging into IBM Cloud (region: $REGION)…"
    ibmcloud login --apikey "${WO_API_KEY:-$WO_ENTITLEMENT_KEY}" -r "$REGION"

    echo "🔐 Logging Docker into IBM Container Registry…"
    ibmcloud cr login
  fi
fi

# ────────────────────────────────────────────────────────────────────────────
#  Setup Python venv & ADK
# ────────────────────────────────────────────────────────────────────────────
if [[ -d "venv" ]]; then
  echo "📦 Activating existing venv…"
  # shellcheck disable=SC1091
  source venv/bin/activate
  echo "🔧 Python $(python --version)"
  ADK_VERSION=$(pip show ibm-watsonx-orchestrate 2>/dev/null \
                 | awk '/^Version:/{print $2}')
  [[ -z "$ADK_VERSION" ]] && echo "⚠️  Could not detect ADK version."
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
#  Fix non-TTY for the “I accept” prompt
# ────────────────────────────────────────────────────────────────────────────
export COMPOSE_INTERACTIVE_NO_CLI=1

# ────────────────────────────────────────────────────────────────────────────
#  Run Developer Edition
# ────────────────────────────────────────────────────────────────────────────
if [[ "$ACCOUNT_TYPE" == "internal" ]]; then

  echo
  echo "🚀 (internal) Starting Developer Edition…"
  orchestrate server start -l --env-file "$ENV_FILE"
  echo
  echo "💬 Launching chat…"
  orchestrate chat start
  echo
  read -rp "Press [Enter] to exit…"
  exit 0

else
  echo
  echo "♻️  Resetting any previous Developer Edition…"
  echo "I accept" | orchestrate server reset --env-file "$ENV_FILE" || true

  echo
  echo "🚀 Starting Developer Edition…"
  echo "I accept" | orchestrate server start --env-file "$ENV_FILE"

  echo
  echo "🔄 Activating local environment…"
  orchestrate env activate local
fi

# ────────────────────────────────────────────────────────────────────────────
#  Done
# ────────────────────────────────────────────────────────────────────────────
echo
if [[ -n "$ADK_VERSION" ]]; then
  echo "✅  Developer Edition v$ADK_VERSION is live (venv activated)."
else
  echo "✅  Developer Edition is live (venv activated)."
fi
echo "    Happy building — ruslanmv.com 🚀"