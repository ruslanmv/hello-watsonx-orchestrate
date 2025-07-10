#!/usr/bin/env bash
#Please move this file to root to work.
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
#  Startup Script
#
set -e  # Exit on any error

# ── Blue runtime logo ────────────────────────────────────────────────────────
print_logo() {
  local BLUE="\033[1;34m"; local NC="\033[0m"
  echo -e "${BLUE}"
  cat <<'EOF'
                _                            
               | |                           
 _ __ _   _ ___| | __ _ _ __  _ __ _____   __
| '__| | | / __| |/ _` | '_ \| '_ ` _ \ \ / /
| |  | |_| \__ \ | (_| | | | | | | | | \ V / 
|_|   \__,_|___/_|\__,_|_| |_|_| |_| |_|\_/   

EOF
  echo -e "${NC}"
}

print_logo

# Colours ---------------------------------------------------------------------
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

print()       { echo -e "${BLUE}[INFO]${NC} $1";   }
print_ok()    { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warn()  { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_err()   { echo -e "${RED}[ERROR]${NC} $1";   }

# Configuration ---------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
CLEANUP_SCRIPT="$SCRIPT_DIR/cleanup_specific_resources.sh"

print "Starting watsonx Orchestrate Developer Edition…"
print "Script directory: $SCRIPT_DIR"

# Pre-flight checks -----------------------------------------------------------
print "Running pre-flight checks…"

[[ -f "$ENV_FILE" ]] || { print_err ".env file not found"; exit 1; }

docker info   >/dev/null 2>&1 || { print_err "Docker is not running"; exit 1; }
docker compose version 2>/dev/null | grep -q 'v2\.' || { print_err "Docker Compose v2 is required"; exit 1; }


# ────────────────────────────────────────────────────────────────────────────
#  Check virtual-environment & ADK
# ────────────────────────────────────────────────────────────────────────────

# Unset VIRTUAL_ENV to ensure a clean check, otherwise a previously
# active venv could cause the second check to be skipped incorrectly.
unset VIRTUAL_ENV

if [[ -d "venv" ]]; then
  VIRTUAL_ENV="venv" # Manually set to skip the next check
  echo "📦 Found existing venv. Activating…"
  # shellcheck disable=SC1091
  source venv/bin/activate
  echo "🔧 Python $(python --version)"
  ADK_VERSION=$(pip show ibm-watsonx-orchestrate 2>/dev/null \
                | awk '/^Version:/{print $2}')
  [[ -z "$ADK_VERSION" ]] && print_warn "Could not detect installed ADK version."
fi # <-- This closing 'fi' was missing.

# This check runs only if the './venv' directory was NOT found.
if [[ -z "$VIRTUAL_ENV" ]]; then
  print_warn "No Python venv detected"
  read -p "Continue anyway? (y/N): " -n 1 -r; echo
  [[ $REPLY =~ ^[Yy]$ ]] || exit 1
fi

command -v orchestrate >/dev/null 2>&1 || {
  print_err "'orchestrate' command not found – install with: pip install ibm-watsonx-orchestrate-adk"
  exit 1
}



command -v orchestrate >/dev/null 2>&1 || {
  print_err "'orchestrate' command not found – install with: pip install ibm-watsonx-orchestrate-adk"
  exit 1
}

print_ok "Pre-flight checks passed"

# Load .env -------------------------------------------------------------------
set -a; source "$ENV_FILE"; set +a
required_vars=(WO_DEVELOPER_EDITION_SOURCE WO_ENTITLEMENT_KEY WO_INSTANCE WO_API_KEY WATSONX_APIKEY WATSONX_SPACE_ID)
for v in "${required_vars[@]}"; do
  [[ -z "${!v:-}" ]] && { missing="yes"; print_err "Missing env var: $v"; }
done
[[ $missing == "yes" ]] && exit 1
[[ "$WO_INSTANCE" == *"YOUR_INSTANCE_ID"* ]] && { print_err "Replace YOUR_INSTANCE_ID in WO_INSTANCE"; exit 1; }
print_ok "Environment validated"

# Stop any existing services --------------------------------------------------
print "Stopping any existing watsonx Orchestrate services…"
orchestrate server stop 2>/dev/null || true

# Start-server helper ---------------------------------------------------------
export COMPOSE_INTERACTIVE_NO_CLI=1 DOCKER_BUILDKIT=1

start_server() {
  local max=3 attempt=1
  while (( attempt <= max )); do
    print "Attempt $attempt of $max…"

    if (( attempt == 3 )); then
      print_warn "Running in pseudo-TTY to avoid TTY error…"
      cmd='script -q -c "orchestrate server start --env-file=$ENV_FILE" /dev/null'
      bash -c "$cmd"
    else
      orchestrate server start --env-file="$ENV_FILE"
    fi

    if [[ $? -eq 0 ]]; then
      print_ok "Server started successfully"; return 0
    fi

    print_warn "Server start attempt $attempt failed"

    if (( attempt == 1 )); then
      print "Running cleanup_specific_resources.sh before retry…"
      bash "$CLEANUP_SCRIPT" || print_warn "Cleanup script encountered an error"
    fi

    (( attempt++ ))
    if (( attempt <= max )); then
      print "Waiting 10 s before retry…"; sleep 10
      print "Resetting server before retry…"
      echo "I accept" | orchestrate server reset --env-file="$ENV_FILE" 2>/dev/null || true
      sleep 5
    fi
  done
  print_err "Failed to start server after $max attempts"; return 1
}

# Launch ----------------------------------------------------------------------
if ! start_server; then exit 1; fi

# Wait for services to be ready ----------------------------------------------
print "Waiting for services to initialise…"; sleep 30

# Activate local environment --------------------------------------------------
for i in {1..3}; do
  orchestrate env activate local && { print_ok "Local env activated"; break; }
  (( i == 3 )) && print_warn "Failed after 3 tries – activate manually" && break
  print_warn "Activation failed (attempt $i/3) – retrying in 10 s…"; sleep 10
done

# ────────────────────────────────────────────────────────────────────────────
#  Import Tools and Agents Section
# ────────────────────────────────────────────────────────────────────────────
read -p $'\e[34m[INFO]\e[0m Would you like to install the sample agents included in this project? (y/N): ' -n 1 -r; echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  
  # Import tools first (agents depend on tools)
  TOOLS_DIR="$SCRIPT_DIR/tools"
  if [[ -d "$TOOLS_DIR" ]]; then
    print "Importing tools first…"
    shopt -s nullglob
    mapfile -t tool_files < <(find "$TOOLS_DIR" -name "*.py" -type f)
    if [[ ${#tool_files[@]} -gt 0 ]]; then
      for file in "${tool_files[@]}"; do
        name="$(basename "$file")"
        print "Importing tool: $name…"
        if orchestrate tools import -k python -f "$file"; then
          print_ok "Tool $name imported"
        else
          print_err "Failed to import tool $name"
        fi
      done
    else
      print_warn "No Python tool files found in $TOOLS_DIR"
    fi
  else
    print_warn "Tools directory not found: $TOOLS_DIR"
  fi

  # Import agents after tools
  AGENTS_DIR="$SCRIPT_DIR/agents"
  if [[ -d "$AGENTS_DIR" ]]; then
    print "Importing agents…"
    shopt -s nullglob
    mapfile -t agent_files < <(printf '%s\n' "$AGENTS_DIR"/*.yaml "$AGENTS_DIR"/*.yml)
    if [[ ${#agent_files[@]} -eq 0 ]]; then
      print_warn "No agent definition files (*.yaml|*.yml) found in $AGENTS_DIR"
    else
      print "Installing ${#agent_files[@]} agent(s)…"
      
      # Import agents in dependency order
      # First import agents without collaborators
      declare -a simple_agents=()
      declare -a complex_agents=()
      
      for file in "${agent_files[@]}"; do
        name="$(basename "$file")"
        if grep -q "collaborators:" "$file" && ! grep -A5 "collaborators:" "$file" | grep -q "^\s*-\s*$\|^\s*\[\s*\]"; then
          complex_agents+=("$file")
        else
          simple_agents+=("$file")
        fi
      done
      
      # Import simple agents first
      for file in "${simple_agents[@]}"; do
        name="$(basename "$file")"
        print "Importing $name…"
        if orchestrate agents import -f "$file"; then
          print_ok "$name imported"
        else
          print_err "Failed to import $name"
        fi
      done
      
      # Then import complex agents (with collaborators)
      for file in "${complex_agents[@]}"; do
        name="$(basename "$file")"
        print "Importing $name…"
        if orchestrate agents import -f "$file"; then
          print_ok "$name imported"
        else
          print_err "Failed to import $name (missing collaborators?)"
        fi
      done
    fi
  else
    print_err "Agents directory not found: $AGENTS_DIR"
  fi
fi
# ────────────────────────────────────────────────────────────────────────────

# Final messages --------------------------------------------------------------
print_ok "watsonx Orchestrate Developer Edition is ready!"
echo -e "
  ▸ UI  : http://localhost:3000/chat-lite
  ▸ API : http://localhost:4321/api/v1
  ▸ Docs : http://localhost:4321/docs
"

# Check if we have agents before offering to start chat
agent_count=$(orchestrate agents list 2>/dev/null | wc -l)
if [[ $agent_count -gt 0 ]]; then
    read -p $'\e[34m[INFO]\e[0m Start the chat interface now? (y/N): ' -n 1 -r; echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print "Starting chat…"
        orchestrate chat start
    fi
else
    print_warn "No agents available. Create an agent first before starting the chat interface."
fi

print_ok "Script completed."